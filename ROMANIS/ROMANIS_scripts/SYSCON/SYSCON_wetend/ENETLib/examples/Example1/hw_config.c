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

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
static void MCLK_Config (void);
static void ENET_InitClocksGPIO(void);

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
  
  /*CPU running @96MHZ*/
  MCLK_Config();

  /* Configure Clock and all GPIO */  
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
  
  /* Set the ENET Operating Mode */
  ENET_SetOperatingMode(FULLDUPLEX_100M);    

  /* Start Receive & Transmit */
  ENET_Start(); 
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
  
  /** Configure ENET GPIO **/
  
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
/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
