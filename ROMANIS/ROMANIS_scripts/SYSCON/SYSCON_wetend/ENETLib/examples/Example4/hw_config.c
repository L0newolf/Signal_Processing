/******************** (C) COPYRIGHT 2007 STMicroelectronics ********************
* File Name          : hw_config.c
* Author             : MCD Application Team
* Version            : V2.0
* Date               : 12/07/2007
* Description        : ENET Hardware Configuration & Setup
********************************************************************************
* THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/
/* Includes ------------------------------------------------------------------*/
#include "91x_lib.h"
#include "91x_enet.h"
#include"hw_config.h"
#include "lcd.h"
/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
#define ENET_VIC_Priority 3
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
static void MCLK_Config (void);
static void ENET_InitClocksGPIO(void);
static void ENET_PHYITInit(u8 phyDev, u8 VIC_Priority);
/* Extern function prototypes ------------------------------------------------*/
/* Private functions ---------------------------------------------------------*/
/*******************************************************************************
* Function Name  : Set_System
* Description    : Set System clock.
* Input          : None.
* Return         : None.
*******************************************************************************/
void Set_System(void)
{
  ENET_MACConfig MAC_Config;
  
  /* CPU running @ 96 MHz */
  MCLK_Config();  
  
  /* LCD initialization */
  LCD_Init(); 
  LCD_Clear();
  
  /* Enable VIC clock */
  SCU_AHBPeriphClockConfig(__VIC, ENABLE);
  SCU_AHBPeriphReset(__VIC, DISABLE);
  
  /* Configure MCU to support PHY interrrupts */
  ENET_PHYITInit(PHY_ADDRESS, ENET_VIC_Priority);
  
  /* ENET clocks and GPIO initialization */
  ENET_InitClocksGPIO();  
  
  /* Initialize MAC control structure  with common values */
  MAC_Config.ReceiveALL = DISABLE;
  if (SCU_GetHCLKFreqValue() > 50000)
  MAC_Config.MIIPrescaler = MIIPrescaler_2;
  MAC_Config.LoopbackMode = DISABLE;
  MAC_Config.AddressFilteringMode = MAC_Perfect_Multicast_Perfect;
  MAC_Config.VLANFilteringMode = VLANfilter_VLTAG;
  MAC_Config.PassWrongFrame = DISABLE;
  MAC_Config.LateCollision = ENABLE;
  MAC_Config.BroadcastFrameReception = ENABLE;
  MAC_Config.PacketRetry = ENABLE;
  MAC_Config.RxFrameFiltering = ENABLE;
  MAC_Config.AutomaticPadRemoval = ENABLE;
  MAC_Config.DeferralCheck = ENABLE;
  
  /* ENET MAC&DMA and PHY device initializations */
  ENET_Init(&MAC_Config);  
   
  /* Enables the PHY Auto-Negotiation completed interrupt */
  ENET_PHYITConfig(PHY_ADDRESS, PHY_IT_AutoNego_Cmplt, ENABLE);
  
  /* Set the ENET operatin mode */ 
  ENET_SetOperatingMode(AUTO_NEGOTIATION);
  
 
}
/*******************************************************************************
* Function Name  : MCLK_Config
* Description    : Configures PLL @96MHZ.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void MCLK_Config (void)

{
  FMI_Config(FMI_READ_WAIT_STATE_2, FMI_WRITE_WAIT_STATE_0, FMI_PWD_ENABLE, \
             FMI_LVD_ENABLE, FMI_FREQ_HIGH); /* FMI Wait States */

  SCU_PLLFactorsConfig(192, 25, 2); /* Configure Factors FPLL = 96MHz */
  SCU_PLLCmd(ENABLE);
  SCU_MCLKSourceConfig(SCU_MCLK_PLL);
  SCU_PCLKDivisorConfig(SCU_PCLK_Div2); /* ARM Peripheral bus divisor*/ 
}
/*******************************************************************************
* Function Name  : ENET_InitClocksGPIO
* Description    : Reset, clocks & GPIO Ethernet Pin initializations
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ENET_InitClocksGPIO(void)
{

  GPIO_InitTypeDef GPIO_Struct;
  
  /* Enable ENET and MII PHY clocks */
  SCU_AHBPeriphClockConfig(__ENET, ENABLE);
  SCU_AHBPeriphReset(__ENET,DISABLE);
  SCU_PHYCLKConfig(ENABLE);
  
  /* Configure ENET GPIO */
  GPIO_DeInit(GPIO1);
  GPIO_Struct.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2 |GPIO_Pin_3 |GPIO_Pin_4 |GPIO_Pin_7 ;
  GPIO_Struct.GPIO_Type = GPIO_Type_PushPull;
  GPIO_Struct.GPIO_Direction = GPIO_PinOutput;
  GPIO_Struct.GPIO_IPInputConnected = GPIO_IPInputConnected_Disable;
  GPIO_Struct.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init(GPIO1, &GPIO_Struct);

  GPIO_DeInit(GPIO5);
  GPIO_Struct.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_3;
  GPIO_Struct.GPIO_Type = GPIO_Type_PushPull;
  GPIO_Struct.GPIO_Direction = GPIO_PinOutput;
  GPIO_Struct.GPIO_IPInputConnected = GPIO_IPInputConnected_Disable;
  GPIO_Struct.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init(GPIO5, &GPIO_Struct);

}
/*******************************************************************************
* Function Name  : ENET_PHY_ITInit
* Description    : PHY interrupt GPIO, WIU & VIC initializations.
* Input          : - phyDev: specifies the PHY device address.
*                  - VIC_Priority: specifies the priority of the interrupt.
*                                  It can be a value from 0 to 15. 0 is the highest priority.
* Output         : None
* Return         : None
* Precondition   : VIC clock Enable.
*******************************************************************************/
void ENET_PHYITInit(u8 phyDev, u8 VIC_Priority)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  WIU_InitTypeDef WIU_InitStructure;
  
  
  /* Enable WIU clock */
  SCU_APBPeriphClockConfig(__WIU, ENABLE);
  WIU_DeInit();
 
  /* GPIO 7 clock source enable */
  SCU_APBPeriphClockConfig(__GPIO7, ENABLE);
  GPIO_DeInit(GPIO7);

  /* GPIO7  pin 1 configuration */ 
  GPIO_StructInit(&GPIO_InitStructure);
  GPIO_InitStructure.GPIO_Direction = GPIO_PinInput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_Init (GPIO7, &GPIO_InitStructure); 
  
  /* Enable the WIU & Clear the WIU line 25 pending bit */
  WIU_Cmd(ENABLE );
  WIU_ClearITPendingBit(WIU_Line25);
  WIU_InitStructure.WIU_Line = WIU_Line25 ;
  WIU_InitStructure.WIU_TriggerEdge = WIU_RisingEdge ;
  WIU_Init(&WIU_InitStructure);

  /* Select WIU line 25 as VIC1.13 interrupt source */
  SCU_WakeUpLineConfig(25);
  
  /* Configure the External interrupt group 3 priority */
  VIC_Config(EXTIT3_ITLine, VIC_IRQ, VIC_Priority);
  
  /* Enable the External interrupt group 3 */
  VIC_ITCmd(EXTIT3_ITLine, ENABLE);
}
/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
