/******************** (C) COPYRIGHT 2006 STMicroelectronics ********************
* File Name          : main.c
* Author             : MCD Application Team
* Date First Issued  : 11/27/2006  : Version 1.0
* Description        : main program for Memory to SSP DMA example
********************************************************************************
* History:
* 11/27/2006  : Version 1.0
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

/* Private typedef -----------------------------------------------------------*/
typedef enum { FAILED = 0, PASSED = !FAILED} TestStatus;

/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
u8 SSP0_Buffer_Tx[32] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
                         0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12,
                         0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B,
                         0x1C, 0x1D, 0x1E, 0x1F, 0x20};

u8 SSP1_Buffer_Tx[32] = {0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
                         0x5A, 0x5B, 0x5C, 0x5D, 0x5E, 0x5F, 0x60, 0x61, 0x62,
                         0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B,
                         0x6C, 0x6D, 0x6E, 0x6F, 0x70};


u8 SSP0_Buffer_Rx[32], SSP1_Buffer_Rx[32];
u8 Tx_Idx=0, Rx_Idx=0, k=0;
SSP_InitTypeDef   SSP_InitStructure;
DMA_InitTypeDef DMA_InitStruct;
TestStatus TransferStatus1,TransferStatus2; 

/* Private function prototypes -----------------------------------------------*/
void GPIO_Configuration(void);
void SCU_Configuration(void);
TestStatus Buffercmp(u8* pBuffer1, u8* pBuffer2, u16 BufferLength);

/* Private functions ---------------------------------------------------------*/
/*******************************************************************************
* Function Name  : main
* Description    : Main program
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void main()
{

  #ifdef DEBUG
  debug();
  #endif

  /* SCU configuration */ 
  SCU_Configuration();

  /* GPIO pins configuration */
  GPIO_Configuration();

  /* SSP0 configuration */
  SSP_DeInit(SSP0);
  SSP_InitStructure.SSP_FrameFormat = SSP_FrameFormat_Motorola;
  SSP_InitStructure.SSP_Mode = SSP_Mode_Master;
  SSP_InitStructure.SSP_CPOL = SSP_CPOL_High;
  SSP_InitStructure.SSP_CPHA = SSP_CPHA_2Edge;
  SSP_InitStructure.SSP_DataSize = SSP_DataSize_16b;
  SSP_InitStructure.SSP_ClockRate = 5;
  SSP_InitStructure.SSP_ClockPrescaler = 2;
  SSP_Init(SSP0, &SSP_InitStructure);

  /* SSP1 configuration */
  SSP_DeInit(SSP1);
  SSP_InitStructure.SSP_Mode = SSP_Mode_Slave;
  SSP_InitStructure.SSP_SlaveOutput = SSP_SlaveOutput_Enable;
  SSP_Init(SSP1, &SSP_InitStructure);

  /* SSP0 enable */
  SSP_Cmd(SSP0, ENABLE);

  /* SSP1 enable */
  SSP_Cmd(SSP1, ENABLE);
  /***********************Enable SSP DMA request*******************************/
  
  SSP_DMACmd(SSP0, SSP_DMA_Transmit, ENABLE);
  SSP_DMACmd(SSP0, SSP_DMA_Receive, ENABLE);
  SSP_Cmd(SSP0,  ENABLE);
  
  /***************************DMA configuration channel0***********************/

  DMA_DeInit();                         
  DMA_StructInit(&DMA_InitStruct);
   DMA_Cmd(ENABLE);
  /*No linked lists used*/
  DMA_InitStruct.DMA_Channel_LLstItm=0; 
  
  /*Source address*/
  DMA_InitStruct.DMA_Channel_SrcAdd=(u32)(&SSP0_Buffer_Tx[0]);
  
  /*Destination address*/
  DMA_InitStruct.DMA_Channel_DesAdd=(u32)((&SSP0->DR));
  
  /*Source width of one byte*/
  DMA_InitStruct.DMA_Channel_SrcWidth= DMA_SrcWidth_Byte;
  
  /*Destination width of one byte*/
  DMA_InitStruct.DMA_Channel_DesWidth= DMA_DesWidth_Byte; 
  
  /*The flow controller is the DMAC*/
  DMA_InitStruct.DMA_Channel_FlowCntrl= DMA_FlowCntrl1_DMA;
  DMA_InitStruct.DMA_Channel_Des = DMA_DES_SSP0_TX;
   
  /*Transfer size of 32 bytes*/
  DMA_InitStruct.DMA_Channel_TrsfSize =32;
  
  /*We increment the source not the destination*/
  DMA_ChannelSRCIncConfig (DMA_Channel0, ENABLE);
  DMA_Init(DMA_Channel0,&DMA_InitStruct); 
  
  
  
  /***************************DMA configuration channel1************************/

  //DMA_DeInit();                         
  DMA_StructInit(&DMA_InitStruct);
  
  /*No linked lists used*/
  DMA_InitStruct.DMA_Channel_LLstItm=0; 
  
  /*Source address*/
  DMA_InitStruct.DMA_Channel_SrcAdd=(u32)(&SSP0->DR);
  
  /*Destination address*/
  DMA_InitStruct.DMA_Channel_DesAdd=(u32)((&SSP0_Buffer_Rx));
  
  /*Source width of one byte*/
  DMA_InitStruct.DMA_Channel_SrcWidth= DMA_SrcWidth_Byte;
  
  /*Destination width of one byte*/
  DMA_InitStruct.DMA_Channel_DesWidth= DMA_DesWidth_Byte; 
  
  /*The flow controller is the DMAC*/
  DMA_InitStruct.DMA_Channel_FlowCntrl= DMA_FlowCntrl2_DMA;
  DMA_InitStruct.DMA_Channel_Src = DMA_SRC_SSP0_RX;
   
  /*Transfer size of 32 bytes*/
  DMA_InitStruct.DMA_Channel_TrsfSize =32;
  
  /*We increment the source not the destination*/
  DMA_ChannelDESIncConfig (DMA_Channel1, ENABLE);
  DMA_Init(DMA_Channel1,&DMA_InitStruct); 

  
  
  
 
/******************************Master to slave transfer procedure**************/
 
  /* Send data to SSP0 using DMA capability instead of CPU*/
   DMA_ChannelCmd (DMA_Channel0,ENABLE);
  while(Rx_Idx<32)
  {
  while(SSP_GetFlagStatus(SSP1, SSP_FLAG_RxFifoNotEmpty)==RESET);
  SSP1_Buffer_Rx[Rx_Idx++] = SSP_ReceiveData(SSP1);
  }

  /* Check the received data with the send ones */
  /* TransferStatus1 = PASSED, if the data transmitted from SSP0 and
     received by SSP1 are the same */
  /* TransferStatus1 = FAILED, if the data transmitted from SSP0 and
     received by SSP1 are different */

  TransferStatus1 = Buffercmp(SSP0_Buffer_Tx, SSP1_Buffer_Rx, 32);
  
 /* Clear SSP0 receive Fifo */
  for(k=0; k<8; k++) SSP0_Buffer_Rx[k] = SSP_ReceiveData(SSP0);

  /* Reset counters */
  Tx_Idx=Rx_Idx=0;

  /* Slave to master transfer procedure */
 
  
  
  while(Tx_Idx<32)
  {
    
    DMA_ChannelCmd (DMA_Channel1,DISABLE);
    SSP_SendData(SSP1, SSP1_Buffer_Tx[Tx_Idx]);
   /* send a dummy bit to generate the clock */
    SSP_SendData(SSP0, SSP0_Buffer_Tx[Tx_Idx++]);
     while(SSP_GetFlagStatus(SSP0, SSP_FLAG_RxFifoNotEmpty)==RESET);
   
    //SSP0_Buffer_Rx[Rx_Idx++] = SSP_ReceiveData(SSP0);
    DMA_ChannelCmd (DMA_Channel1,ENABLE);
  }
  

  

  /* Check the received data with the send ones */
  TransferStatus2 = Buffercmp(SSP1_Buffer_Tx, SSP0_Buffer_Rx, 32);
  /* TransferStatus = PASSED, if the data transmitted from SSP1 and
     received by SSP0 are the same */
  /* TransferStatus = FAILED, if the data transmitted from SSP1 and
     received by SSP0 are different */
  
  while(1);
}

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configure the used I/O ports pins
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GPIO_Configuration(void)
{
  GPIO_InitTypeDef  GPIO_InitStructure;

  /* SSP0 and SSP1 pins Config */

  GPIO_DeInit(GPIO2);
  /*Configure SSP0_CLK, SSP0_MOSI, SSP0_nSS pins */
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_InitStructure.GPIO_Alternate = GPIO_OutputAlt2  ;
  GPIO_Init (GPIO2, &GPIO_InitStructure);

   /*Configure SSP0_MISO pin GPIO2.6*/
  GPIO_InitStructure.GPIO_Direction = GPIO_PinInput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Enable;
  GPIO_InitStructure.GPIO_Alternate = GPIO_InputAlt1  ;
  GPIO_Init (GPIO2, &GPIO_InitStructure);

  GPIO_DeInit(GPIO3);
  /*Configure SSP1_MISO pin */
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Enable;
  GPIO_InitStructure.GPIO_Alternate = GPIO_OutputAlt2  ;
  GPIO_Init (GPIO3, &GPIO_InitStructure);

   /*Configure SSP0_CLK, SSP0_MOSI, SSP0_nSS pins */
  GPIO_InitStructure.GPIO_Direction = GPIO_PinInput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4| GPIO_Pin_6|GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Enable;
  GPIO_InitStructure.GPIO_Alternate = GPIO_InputAlt1  ;
  GPIO_Init (GPIO3, &GPIO_InitStructure);
}

/*******************************************************************************
* Function Name  : SCU_Configuration
* Description    : Configure the different system clocks
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SCU_Configuration(void)
{
  /* Enable the __SSP0 Clock */
  SCU_APBPeriphClockConfig(__SSP0 ,ENABLE);

  /* Enable the __SSP1 Clock */
  SCU_APBPeriphClockConfig(__SSP1 ,ENABLE);

  /* Enable the __GPIO2 for SSP0 Clock */
  SCU_APBPeriphClockConfig(__GPIO2 ,ENABLE);

  /* Enable the __GPIO3 for SSP1 Clock */
  SCU_APBPeriphClockConfig(__GPIO3 ,ENABLE);
  
  /* Enable the __DMA Clock */
  SCU_AHBPeriphClockConfig(__DMA,ENABLE); 
}

/*******************************************************************************
* Function Name  : Buffercmp
* Description    : Compares two buffers.
* Input          : - pBuffer1, pBuffer2: buffers to be compared.
*                : - BufferLength: buffer's length
* Output         : None
* Return         : PASSED: pBuffer1 identical to pBuffer2
*                  FAILED: pBuffer1 differs from pBuffer2
*******************************************************************************/
TestStatus Buffercmp(u8* pBuffer1, u8* pBuffer2, u16 BufferLength)
{
  while(BufferLength--)
  {
    if(*pBuffer1 != *pBuffer2)
    {
      return FAILED;
    }

    pBuffer1++;
    pBuffer2++;
  }

  return PASSED;
}

/******************* (C) COPYRIGHT 2006 STMicroelectronics *****END OF FILE****/
