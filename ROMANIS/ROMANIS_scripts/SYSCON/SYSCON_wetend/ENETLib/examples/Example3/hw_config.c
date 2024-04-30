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
#define ENET_VICPriority 3
#define DMA_VICPriority 2
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
DMA_InitTypeDef  Rx_DMA_InitStruct;

/* External variables --------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
void MCLK_Config (void);
void ENET_InitClocksGPIO(void);
void ENET_DMAInit();

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
  
  /* Configure Clocks and all GPIO */  
  ENET_InitClocksGPIO();  
  
  /* Enable VIC clock */
  SCU_AHBPeriphClockConfig(__VIC, ENABLE);
  SCU_AHBPeriphReset(__VIC, DISABLE);
  
  /* Enable ENET interrupt */
  VIC_Config(ENET_ITLine, VIC_IRQ, ENET_VICPriority);
  VIC_ITCmd(ENET_ITLine, ENABLE);
  
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
  
  /* Initialize DMA controller */
  ENET_DMAInit();
  
  /* Setting the ENET operating mode */
  ENET_SetOperatingMode(FULLDUPLEX_100M);

  /* Start Receive & Transmit */
  ENET_Start(); 
  
  /* Enable ENET RX current done interrupt */
  ENET_ITConfig(ENET_IT_RX_CURR_DONE, ENABLE); 
  
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
* Function Name  : ENET_DMAInit
* Description    : Initializes & configures the DMAC channel0 and channel1.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ENET_DMAInit()
{  
   
  SCU_AHBPeriphClockConfig(__DMA, ENABLE);
  DMA_DeInit();
  DMA_Cmd(ENABLE);
  
  /* DMA_ITLine configuration, if DMA interrupt used */
  VIC_Config(DMA_ITLine, VIC_IRQ, DMA_VICPriority); 
  VIC_ITCmd(DMA_ITLine, ENABLE);
  
/** DMAC channel1 initialization **/
  /* Configure channel1 as receive channel */
  DMA_StructInit(&Rx_DMA_InitStruct);
  Rx_DMA_InitStruct.DMA_Channel_LLstItm=0; /* No linked list */
  Rx_DMA_InitStruct.DMA_Channel_SrcWidth= DMA_SrcWidth_Byte; /* source Width is one Byte */
  Rx_DMA_InitStruct.DMA_Channel_DesWidth= DMA_DesWidth_Byte; /* destination Width is one Byte */
  Rx_DMA_InitStruct.DMA_Channel_DesBstSize = DMA_DesBst_256Data ; /* Burst transfer size == 256Bytes */
  Rx_DMA_InitStruct.DMA_Channel_SrcBstSize = DMA_SrcBst_256Data ; /* Burst transfer size == 256bytes */
  Rx_DMA_InitStruct.DMA_Channel_FlowCntrl=  DMA_FlowCntrlt0_DMA; /* transfer type :Memory-to-memory, flow controller:DMA */
  
  /* Enables Src & Dest address incrementation after each transfer */
  DMA_ChannelSRCIncConfig (DMA_Channel1, ENABLE);
  DMA_ChannelDESIncConfig (DMA_Channel1, ENABLE);
  
  /* DMA_channel0 Terminal count interrupt Enable */ 
  DMA_ITConfig(DMA_Channel1, ENABLE);
  DMA_ITMaskConfig(DMA_Channel1, DMA_ITMask_ITC, ENABLE);
  
  /* Initialize the channel1 */
  DMA_Init(DMA_Channel1,&Rx_DMA_InitStruct);
}
/*******************************************************************************
* Function Name  : ENET_DMA_CpyRxPkt
* Description    : Configures & enables the DMA channel to copy received packet 
*                  to the buffer pointed by ppkt.
* Input          : ppkt: pointer on application packet buffer.
* Output         : None
* Return         : Size of the Rx packet
*******************************************************************************/
u32 ENET_DMACpyRxPkt(void *ppkt)
{
  ENET_DMADSCRBase   *pDescr;
  u16 size;
  
  pDescr = &dmaRxDscrBase[RxBC];
  
  /* Get the size of the received packet */
  size = (u16)( (pDescr->dmaPackStatus & 0x7ff) - 4);

  /* DMAC channel0 configuration */
  Rx_DMA_InitStruct.DMA_Channel_SrcAdd = (u32)&RxBuff[RxBC][0]; /*Source addresss */
  
  Rx_DMA_InitStruct.DMA_Channel_DesAdd = (u32)ppkt; /*Destination address*/
  
  Rx_DMA_InitStruct.DMA_Channel_TrsfSize = size; /*The transfer size */
  
  DMA_Init(DMA_Channel1,&Rx_DMA_InitStruct);  /* Initialize the channel1 */

  DMA_ChannelCmd (DMA_Channel1,ENABLE); /* Start the transfer */
 
  /* Return the size */
  return (size);

}
/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
