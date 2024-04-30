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
DMA_InitTypeDef  Tx_DMA_InitStruct;
LLI_InitTypeDef LLI1_InitStructure, LLI2_InitStructure;
LLI_CCR_InitTypeDef LLI_CCR_InitStruct;

/* External variables --------------------------------------------------------*/
extern u16 TabSize[ENET_TXBUFNB];

/* Private function prototypes -----------------------------------------------*/
static void MCLK_Config (void);
static void ENET_InitClocksGPIO(void);
static void ENET_DMAInit();

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

  /* Enable VIC clock */
  SCU_AHBPeriphClockConfig(__VIC, ENABLE);
  SCU_AHBPeriphReset(__VIC, DISABLE);
  
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
  
  /* Initailize the DMA controller */
  ENET_DMAInit();
  
  /* Set the Operating mode */
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
void ENET_DMAInit(void)
{  
   
  SCU_AHBPeriphClockConfig(__DMA, ENABLE);
  DMA_DeInit();
  DMA_Cmd(ENABLE);
  
  /* DMA_ITLine configuration, if DMA interrupt used */
  VIC_Config(DMA_ITLine, VIC_IRQ, DMA_VICPriority);
  VIC_ITCmd(DMA_ITLine, ENABLE);
  
/** DMAC channel1 initialization **/    
  /* Configure channel1 as transmission channel */
  
  DMA_StructInit(&Tx_DMA_InitStruct);
  Tx_DMA_InitStruct.DMA_Channel_LLstItm=(u32)(&(LLI1_InitStructure.LLI_SrcAdd));
  Tx_DMA_InitStruct.DMA_Channel_SrcWidth= DMA_SrcWidth_Byte;  /* source Width is one Byte */
  Tx_DMA_InitStruct.DMA_Channel_DesWidth= DMA_DesWidth_Byte;  /* destination Width is one Byte */
  Tx_DMA_InitStruct.DMA_Channel_DesBstSize = DMA_DesBst_256Data ; /* Burst transfer size == 256Bytes */ 
  Tx_DMA_InitStruct.DMA_Channel_SrcBstSize = DMA_SrcBst_256Data ; /* Burst transfer size == 256Bytes */  
  Tx_DMA_InitStruct.DMA_Channel_FlowCntrl=  DMA_FlowCntrlt0_DMA;  /* transfer type :Memory-to-memory, flow controller:DMA */
  
  /* Enables Src & Dest address incrementation after each transfer */
  DMA_ChannelSRCIncConfig (DMA_Channel1, ENABLE);
  DMA_ChannelDESIncConfig (DMA_Channel1, ENABLE);
  
  /* DMA_channel1 Terminal count interrupt Enable */
  DMA_ITConfig(DMA_Channel1, ENABLE);
  DMA_ITMaskConfig(DMA_Channel1, DMA_ITMask_ITC, ENABLE);
  
  /* Initialize the channel1*/
  DMA_Init(DMA_Channel1,&Tx_DMA_InitStruct);
}

/*******************************************************************************
* Function Name  : ENET_DMACpyTxPkt
* Description    : Configures & enables the DMA channel to copy a packet 
*                  pointed by ppkt to ENET DMA buffer.
* Input          : - ppkt: pointer to application packet buffer.
*                  - size1: Tx Packet 1 size.
*                  - size2: Tx Packet 2 size.
*                  - size3: Tx Packet 3 size.
* Output         : None
* Return         : None
*******************************************************************************/
void ENET_DMACpyTxPkt(void *ppkt, u16 TabSize[ENET_TXBUFNB])
{
  
  u8 txbc1, txbc2;
  
  /* wait for the fifo to be empty */
  while(DMA_GetChannelActiveStatus(DMA_Channel1));
  
  /* If the ENET still work on the buffer, we wait...*/
  while( (dmaTxDscrBase[TxBC].dmaPackStatus & ENET_DSCR_TX_STATUS_VALID_MSK) );
  /* The buffer is owned by the CPU, we can work on it! */
   
  
  /** LLI_CCR_InitStructure Initialization **/
  LLI_CCR_InitStruct.LLI_SrcBstSize = DMA_SrcBst_256Data;  /* Source burst size*/
  LLI_CCR_InitStruct.LLI_DesBstSize = DMA_SrcBst_256Data;  /* Destination burst size*/
  LLI_CCR_InitStruct.LLI_SrcWidth = DMA_SrcWidth_Byte;  /* Source width*/
  LLI_CCR_InitStruct.LLI_DesWidth = DMA_DesWidth_Byte;  /* Destination width */
  LLI_CCR_InitStruct.LLI_SrcIncrement = DMA_SrcIncrement;  /* Source address is incremented */
  LLI_CCR_InitStruct.LLI_DesIncrement = DMA_DesIncrement;  /* Destination address is incremented */
  
 /**                 Linked list items for the first Link LLI               **/
  /* Source address */
  LLI1_InitStructure.LLI_SrcAdd = (u32)ppkt+ENET_MAX_PACKET_SIZE;
  /* Destination address */ 
  txbc1=TxBC+1;
  if(txbc1 >= ENET_TXBUFNB)
    txbc1=0;
  /* Destination address */
  LLI1_InitStructure.LLI_DesAdd = (u32)TxBuff[txbc1];
  /* Pointer */
  LLI1_InitStructure.LLI_Pointer = (u32)(&(LLI2_InitStructure));
  /* Control word */
  LLI_CCR_InitStruct.LLI_TrsfSize = TabSize[1]; /*Transfer size*/
  
  LLI1_InitStructure.LLI_CCR = DMA_LLI_CCR_Init(&LLI_CCR_InitStruct);

  /**                 Linked list items for the second Link LLI               **/
  /* Source address */
  LLI2_InitStructure.LLI_SrcAdd = (u32)ppkt+(2*ENET_MAX_PACKET_SIZE);
  /* Destination address */ 
  txbc2=txbc1+1;
  if(txbc2 >= ENET_TXBUFNB)
    txbc1=0;
  /* Destination address */
  LLI2_InitStructure.LLI_DesAdd = (u32)TxBuff[txbc2];
  /* Pointer */
  LLI2_InitStructure.LLI_Pointer = 0;
  /* Control word */
  LLI_CCR_InitStruct.LLI_TrsfSize = TabSize[2];  /* Transfer size */

  LLI2_InitStructure.LLI_CCR = DMA_LLI_CCR_Init(&LLI_CCR_InitStruct);
  
  /**                        DMAC channel1 configuration                     **/
  /* Source addresss */
  Tx_DMA_InitStruct.DMA_Channel_SrcAdd = (u32)ppkt; 
  /* Destination address*/
  Tx_DMA_InitStruct.DMA_Channel_DesAdd= (u32)TxBuff[TxBC]; 
  /* The transfer size */
  Tx_DMA_InitStruct.DMA_Channel_TrsfSize = TabSize[0]; 

  /* Initialize the channel1 */  
  DMA_Init(DMA_Channel1,&Tx_DMA_InitStruct); 
  /* Start the transfer */
  DMA_ChannelCmd (DMA_Channel1,ENABLE); 
  
  /* DMA channel 1 is copying pkts to the ENET_DMA buffer ...*/
}
/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
