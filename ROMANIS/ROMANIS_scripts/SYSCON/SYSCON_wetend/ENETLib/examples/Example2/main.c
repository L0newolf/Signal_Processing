/******************** (C) COPYRIGHT 2007 STMicroelectronics ********************
* File Name          : main.c
* Author             : MCD Application Team
* Version            : V2.0
* Date               : 12/07/2007
* Description        : ENET example  
********************************************************************************
* THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS WITH
* CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME. AS
* A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT, INDIRECT
* OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE CONTENT
* OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING INFORMATION
* CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "91x_lib.h"
#include "hw_config.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
#define EthHeader 14
#define Data1Size 1500
#define Data2Size 1000
#define Data3Size 500
#define Pkt1Length (EthHeader+Data1Size) 
#define Pkt2Length (EthHeader+Data2Size)
#define Pkt3Length (EthHeader+Data3Size)

/* Private variables ---------------------------------------------------------*/
u8 EthFrame[3][ENET_MAX_PACKET_SIZE];
u8 buffer1[ENET_MAX_PACKET_SIZE];
u8 buffer2[ENET_MAX_PACKET_SIZE];
u8 buffer3[ENET_MAX_PACKET_SIZE];
u16 TabSize[ENET_TXBUFNB];
u16 size1=0, size2=0, size3=0;

/* Private function prototypes -----------------------------------------------*/
void EthPktSet(void);

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
   
  int i; 
    
  /* System clocks and GPIO setting */
  Set_System();
  
  /* Put the PHY device in the loop back mode */
  ENET_PHYLoopBack(PHY_ADDRESS, ENABLE);

  /* Set data to be sent */
  EthPktSet();
  
  /* Clear the receiving buffers */
  for(i=0;i<1520;i++)
  {
    buffer1[i] = 0;
    buffer2[i] = 0;
    buffer3[i] = 0;
  }
  
  /* Send Three packets */
  TabSize[0] = Pkt1Length;
  TabSize[1] = Pkt2Length;
  TabSize[2] = Pkt3Length;
  ENET_DMACpyTxPkt(EthFrame,TabSize);
  
  while(!(size1 = ENET_HandleRxPkt(buffer1)));
  while(!(size2 = ENET_HandleRxPkt(buffer2)));
  while(!(size3 = ENET_HandleRxPkt(buffer3)));  
  
  while(1);
}
/*******************************************************************************
* Function Name  : EthSet
* Description    : Ethernet frame setting
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void EthPktSet(void)
{
  /** Setting the Ethernet frames **/
  
  int i;
  
  /* Set the MAC Destination address: broadcast address */
  for(i=0;i<(EthHeader-6-2);i++)
  {
    EthFrame[0][i] = 0xFF;
    EthFrame[1][i] = 0xFF;
    EthFrame[2][i] = 0xFF;
  }
  /* Set the MAC source address: 00:02:04:08:0a:0d */
  
  EthFrame[0][i] = 0x00;
  EthFrame[1][i] = 0x00;
  EthFrame[2][i] = 0x00;
  i++;
  EthFrame[0][i] = 0x02;
  EthFrame[1][i] = 0x02;
  EthFrame[2][i] = 0x02;
  i++;
  EthFrame[0][i] = 0x04;
  EthFrame[1][i] = 0x04;
  EthFrame[2][i] = 0x04;
  i++;
  EthFrame[0][i] = 0x08;
  EthFrame[1][i] = 0x08;
  EthFrame[2][i] = 0x08;
  i++;
  EthFrame[0][i] = 0x0A;
  EthFrame[1][i] = 0x0A;
  EthFrame[2][i] = 0x0A;
  i++;
  EthFrame[0][i] = 0x0D;
  EthFrame[1][i] = 0x0D;
  EthFrame[2][i] = 0x0D;
  i++;
  
  /* Set the packets sizes: (1500 = 0x5DC); (1000 = 0x3E8); (500 = 0x1F4) */
  
  EthFrame[0][i] = 0x05;
  EthFrame[1][i] = 0x03;
  EthFrame[2][i] = 0x01;
  i++;
  EthFrame[0][i] = 0xDC;
  EthFrame[1][i] = 0xE8;
  EthFrame[2][i] = 0xF4;
  i++;
  
  /* Set the packet1's data */
  for(;i<Pkt1Length;i+=2)
  {
    /* First packet contain 'ST' */
    EthFrame[0][i] = 0x53;//S
    EthFrame[0][i+1] = 0x54;//T
  }
  
  /* Set the packet2's data */
  for(i=EthHeader;i<Pkt2Length;i+=2)
  {
    /* Second packet contain '0x12 0x34' */
    EthFrame[1][i] = 0x12;
    EthFrame[1][i+1] = 0x34;
  }
  
  /* Set the packet3's data */
  for(i=EthHeader;i<Pkt3Length;i+=2)
  {  
    /* Third packet contain '0xAB 0xCD' */
    EthFrame[2][i] = 0xAB;
    EthFrame[2][i+1] = 0xCD;
    
  }
  
}
/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
