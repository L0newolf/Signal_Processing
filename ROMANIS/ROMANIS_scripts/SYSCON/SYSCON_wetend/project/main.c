////////////////////////////////////////////////////////////////////////////////////////////
//			*** ACOUSTIC RESEARCH LABORATORY CONFIDENTIAL***                              //
//                                                                                        //
//	The information contained in this file remains the property of Acoustic Research      //
// Laboratory, National University Of Singapore. The information is of use for internal   //
// evaluation, operation and/or maintenence purposes within the ARL only. Without prior   //
// written consent of an authorised representative of ARL, you may not reproduce,         //
// represent, or download through any means.                                              //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////

/*========================================================================================
File	: main.c
----------------------------
Project	: ANI-II
----------------------------
Module	: Syscon-Server Interface Program
----------------------------
CPU	: STR912, ARM9 Core

File Description:-
	This is the main source file of the SYSCON in the ANI system. This receives the command from server
	through ethernet (UDP) and control the ANI system.

 Note:- This file contains lots of code which are not used for ANI, because the source files are taken from
	other project.

Procedure:-
       1. You need to have IAR workbench to compile this project, not tested with GNU tool chains
       2. Load "TimestampMCU.eww" project, compile the project, it will generate the executable in "/flash/Exe"
       3. Flash the .out file in the MCU board.

File History:-
-------------------------------------------------------------------------------------------
|xx/xx/2008|	V1.0	|	SAGAR P		|  Created Source File for STARFISH Project...
|20/11/2009|	V2.0	|	SUBASH K	|  Modified the Source code for ANI
|16/12/2009|	V2.0	| 	SUBASH K	|  Programmed the PWM to generate the sampling clock
|09/01/2010|	V2.0	|	SUBASH K	|  Programmed GPIO for 4 front-end power ON
|06/03/2010|	V2.0	|	SUBASH K	|  Changed IP address to 57
==========================================================================================*/
#include "string.h"
#include "stdlib.h"
#include "91x_conf.h"
#include "91x_lib.h"
#include "91x_enet.h"
#include "timestamp.h"
#include "ether.h"
#include "stdio.h"

/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
//The Ethernet defines
#define ETH_HEADER_SZ   14
#define ETH_TYPE_SZ     2
#define ETH_SEQ_SZ      4
#define ETH_PAYLOAD_SZ  32
#define ETH_FILLER_SZ   8
#define ETH_PACKET_LENGTH (ETH_HEADER_SZ+ETH_TYPE_SZ+ETH_SEQ_SZ+ETH_PAYLOAD_SZ+ETH_FILLER_SZ)

#define ETH_TYPE_NORMAL 0x01
#define ETH_TYPE_TIMING_ERROR 0x02
#define REFIN 2.5

//The Control Command
#define C_WR(A)  (A<<15)
#define C_SEQ(A) (A<<14)
#define C_PM  (0x0300)
#define C_SH(A)  (A<<7)
#define C_PIN(A) (A<<6)
#define C_RNG(A) (A<<5)
#define C_COD(A) (A<<4)

#define CMD_READ  (C_WR(0x1)|C_SEQ(0x0)|C_PM|C_SH(0x0)|C_PIN(0x0)|C_RNG(0x1)|C_COD(0x1))

char *g_eth_frame;

I2C_InitTypeDef   i2c;
GPIO_InitTypeDef  gpio;

struct timestamp_data g_ts;
//DEBUG
int g_interrupt_gate;
//ZDA string Visibility
int g_zda_string_seen;

void debug_get_time(struct timestamp_data *pts,unsigned int clocks) ;
extern volatile unsigned int g_tics;
extern volatile unsigned short g_rx_counter;
extern volatile unsigned short g_tx_counter;
extern volatile unsigned int g_rx_clock;
volatile float g_oxo_frequency;
unsigned int g_zda_time;
int g_zda_init;
//DEBUG ends
struct eth_frame_str {
  unsigned char dst[6] ;
  unsigned char src[6] ;
  unsigned short len ;
  unsigned short type ;
  unsigned int sequence;
  unsigned char data[32] ;
  unsigned char filler[6] ;
};

SSP_InitTypeDef   SSP_InitStructure;
DMA_InitTypeDef DMA_InitStruct;
TIM_InitTypeDef TIM_InitStructure;
UART_InitTypeDef UART_InitStructure;

/* Private function prototypes -----------------------------------------------*/
void GPIO_Configuration(void);
void SCU_Configuration(void);
void MCLK_Config (void);
void ENET_InitClocksGPIO(void);

void setup_timer();
void set_eth_system(void);
void send_packet();
u16 send_control_cmd(u16 pcmd) ;
u16 send_init_control_cmd(u16 pcmd);
int setup_eth_header() ;
void send_eth_packet(short ptype,int psequence);
void flush_fifo();
/* Interrupt Control */
volatile int interruptGate = 0;
int process_gga(u8 *ptr,int *lock) ;
int process_zda(u8 *ptr,int *lock);
void convert_date(char *date, unsigned int *sec) ;
void convert_date2(char *day,char *month, char *year, unsigned int *sec) ;

int convert_time(char *time, unsigned int *sec) ;
void GPS_setup_OXO();
void wiu_configuration();
void ENET_InitClocksGPIO(void);
void GPS_init();
int check_checksum(char *ptr,int sz) ;
volatile int g_gps_lock;

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
  //For Debug
  volatile TIM_TypeDef          *stim2 = (TIM_TypeDef *)0x58004000;
  vu16 val;
  unsigned short tim2_counter;
  unsigned int counter;
  unsigned long long total_clocks;
  int zda_string_seen=0;

  //Used
  MCLK_Config();
  /* SCU configuration */
  SCU_Configuration();
   /* GPIO pins configuration */
  GPIO_Configuration();


  /* Interrupt Controller Init */
  VIC_DeInit();
  VIC_Config(TIM2_ITLine,VIC_FIQ,1);
  VIC_ITCmd(TIM2_ITLine,ENABLE);

  TIM_DeInit(TIM2);
  TIM_StructInit(&TIM_InitStructure);
  TIM_InitStructure.TIM_Clock_Source=TIM_CLK_EXTERNAL;
  //TIM_InitStructure.TIM_Clock_Source=TIM_CLK_APB;
  TIM_InitStructure.TIM_Mode=TIM_OCM_CHANNEL_1;
  TIM_InitStructure.TIM_OC1_Modes=TIM_TIMING;
  TIM_Init(TIM2,&TIM_InitStructure);
  TIM_ITConfig(TIM2,TIM_IT_TO,ENABLE);
  TIM_ITConfig(TIM2,TIM_IT_OC1,DISABLE);
  TIM_CounterCmd(TIM2,TIM_START);
  TIM_CounterCmd(TIM2,TIM_CLEAR);


  SCU_APBPeriphClockConfig(__TIM23, ENABLE); /* Enable the clock for TIM0 and TIM1 */
  TIM_DeInit(TIM2);
  SCU_APBPeriphClockConfig(__GPIO4, ENABLE); /* Enable the clock for GPIO4 */
  /* TIM2 Structure Initialization */
  TIM_StructInit(&TIM_InitStructure);
  /* TIM0 Configuration in PWM Mode */
  TIM_InitStructure.TIM_Mode = TIM_PWM;
  TIM_InitStructure.TIM_OPM_INPUT_Edge = TIM_OPM_EDGE_RISING;
  TIM_InitStructure.TIM_Clock_Source = TIM_CLK_APB;
  TIM_InitStructure.TIM_Prescaler = 6;
  TIM_InitStructure.TIM_Pulse_Level_1 = TIM_HIGH;
  TIM_InitStructure.TIM_Period_Level = TIM_LOW;
  TIM_InitStructure.TIM_Pulse_Length_1 = 28;
  TIM_InitStructure.TIM_Full_Period = 30;
  TIM_Init (TIM2, &TIM_InitStructure);

  TIM_CounterCmd(TIM2, TIM_START);

  SCU_APBPeriphClockConfig(__GPIO2,ENABLE);
  gpio.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_1;
  gpio.GPIO_Direction = GPIO_PinOutput;
  gpio.GPIO_Type = GPIO_Type_OpenCollector;
  gpio.GPIO_IPConnected = GPIO_IPConnected_Enable;
  gpio.GPIO_Alternate = GPIO_OutputAlt2;
  GPIO_Init(GPIO2,&gpio);

  SCU_APBPeriphClockConfig(__I2C0,ENABLE);

  I2C_DeInit(I2C0);
  I2C_Cmd(I2C0,ENABLE);
  i2c.I2C_GeneralCall = I2C_GeneralCall_Disable;
  i2c.I2C_Ack = I2C_Ack_Enable;
  i2c.I2C_CLKSpeed = I2C_CLOCK_SPEED;
  i2c.I2C_OwnAddress = 0;     // master does not require an address
  I2C_Init(I2C0,&i2c);
  I2C_ITConfig(I2C0,DISABLE);


  gpio.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_3;
  gpio.GPIO_Direction = GPIO_PinOutput;
  gpio.GPIO_Type = GPIO_Type_OpenCollector;
  gpio.GPIO_IPConnected = GPIO_IPConnected_Enable;
  gpio.GPIO_Alternate = GPIO_OutputAlt2;
  GPIO_Init(GPIO2,&gpio);
  SCU_APBPeriphClockConfig(__I2C1,ENABLE);

  I2C_DeInit(I2C1);
  I2C_Cmd(I2C1,ENABLE);
  i2c.I2C_GeneralCall = I2C_GeneralCall_Disable;
  i2c.I2C_Ack = I2C_Ack_Enable;
  i2c.I2C_CLKSpeed = I2C_CLOCK_SPEED;
  i2c.I2C_OwnAddress = 0;     // master does not require an address
  I2C_Init(I2C1,&i2c);
  I2C_ITConfig(I2C1,DISABLE);


   wiu_configuration();  //FPFA & pps interrupt setup

//USER_SETUP For OXO IP address
//This is the Ethernet address of the factory PC
   ETHER_setup_other("192.168.0.22","001EC21BF416",8065);

   ETHER_setup("192.168.40.57","000204080A2F",8055);g_oxo_frequency=9765.626;
   GPIO_WriteBit(GPIO6,GPIO_Pin_1,Bit_RESET);
   GPIO_WriteBit(GPIO6,GPIO_Pin_2,Bit_RESET);
   GPIO_WriteBit(GPIO6,GPIO_Pin_3,Bit_RESET);
   GPIO_WriteBit(GPIO6,GPIO_Pin_4,Bit_RESET);

  // USER_SETUP
  ETHER_init();
  ETHER_start();


  //Now get the PPS
  //This seems to be the only working order Check the GPIO initialization for the UART
  VIC_ITCmd(EXTIT2_ITLine, ENABLE);
  VIC_ITCmd(EXTIT3_ITLine, ENABLE);
//#define CALIBRATION_MODE
#ifdef CALIBRATION_MODE
  g_interrupt_gate=0;
  counter=0;
  while(1) {
      char buffer[255];
      struct timestamp_data ts;
      sprintf(buffer,
                "OXO in Calibration Mode. Please connect pin 6.1 (Receive Interrupt to 1 Hz source like the PPS\n");
        ETHER_broadcast_data(buffer,strlen(buffer));
      while(0==g_interrupt_gate);
        g_interrupt_gate=0;
        debug_get_time(&ts,g_rx_clock);
        tim2_counter=TIM_GetCounterValue(TIM2);
        total_clocks=(unsigned long long)(g_oxo_frequency*g_ts.sec);

        sprintf(buffer,
                "OXO OXO_elapsed_sec=%u ZDA_sec= %u OXO_sec = %u  OXO_msec = %u ZDA_tics=%llu OXO_tics = %u OXO_counter=%u OXO_rx_clock=%u NOW_TIM2_counter=%u OXO_Frequency=%u\n",
                ++counter,g_ts.sec,(ts.sec+g_ts.sec), ts.msec, total_clocks,g_tics,g_rx_counter,g_rx_clock,tim2_counter,g_rx_clock/counter);
        ETHER_broadcast_data(buffer,strlen(buffer));
  }
#endif //CALIBRATION_MODE
  ETHER_protocol();

}
void debug_get_time(struct timestamp_data *pts,unsigned int clocks) {
  double dsec,dmsec,dusec;
  unsigned int isec,imsec,iusec;
  volatile unsigned int what;

  dsec = (double) ((double)(clocks)/g_oxo_frequency);
  isec =(int)dsec;

  dmsec=(double)(dsec-isec)*1000.0;
  imsec=(int)dmsec;

  dusec=(double)(dmsec-imsec)*1000.0;
  iusec=(int)dusec;


  pts->usec=iusec;
  pts->msec=imsec;
  pts->sec=isec;
  return;
}

void MCLK_Config (void)
{
  /* FMI configuration */
  FMI_Config(FMI_READ_WAIT_STATE_2, FMI_WRITE_WAIT_STATE_0, FMI_PWD_ENABLE, \
             FMI_LVD_ENABLE, FMI_FREQ_HIGH); /* FMI Wait States */

  /* Configure Factors FPLL = 96MHz */
  SCU_PLLFactorsConfig(192, 25, 2);
  /* Enable the PLL */
  SCU_PLLCmd(ENABLE);
  /* Configures the MCLK source clock */
  SCU_MCLKSourceConfig(SCU_MCLK_PLL);
   /* ARM Peripheral bus divisor*/
  SCU_PCLKDivisorConfig(SCU_PCLK_Div2);
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

  /* Enable the __GPIO6 for Clock */
  SCU_APBPeriphClockConfig(__GPIO6 ,ENABLE);
    /* Enable the __GPIO7 for Clock */
  SCU_APBPeriphClockConfig(__GPIO7 ,ENABLE);
    /* Enable the __GPIO8 for Clock */
  SCU_APBPeriphClockConfig(__GPIO8 ,ENABLE);
    /* Enable the __DMA Clock */
  SCU_AHBPeriphClockConfig(__DMA,ENABLE);
    /* Enable the __VIC Clock */
  SCU_AHBPeriphClockConfig(__VIC,ENABLE);

    /* Enable the __TIM23 Clock */
  SCU_APBPeriphClockConfig(__TIM23,ENABLE);

  SCU_TIMCLKSourceConfig(SCU_TIM23,SCU_TIMCLK_EXT);
  //SCU_TIMCLKSourceConfig(SCU_TIM23,SCU_TIMCLK_INT);

/* Enable the UART0 Clock */
  SCU_APBPeriphClockConfig(__UART0, ENABLE);

  /* Enable the GPIO3 Clock */
  SCU_APBPeriphClockConfig(__GPIO3, ENABLE);

  /* Enable the GPIO5 Clock */
  SCU_APBPeriphClockConfig(__GPIO5, ENABLE);


  /* Enable the GPIO1 Clock */
  SCU_APBPeriphClockConfig(__GPIO1, ENABLE);

}

void GPIO_Configuration(void)
{
  GPIO_InitTypeDef  GPIO_InitStructure;

  GPIO_DeInit(GPIO3);
  /*Gonfigure UART0_Tx pin GPIO3.4*/
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_Alternate = GPIO_OutputAlt3  ;
  GPIO_Init (GPIO3, &GPIO_InitStructure);

  GPIO_DeInit(GPIO5);
  /*Gonfigure UART0_Rx pin GPIO5.1*/
  GPIO_InitStructure.GPIO_Direction = GPIO_PinInput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_Alternate = GPIO_InputAlt1  ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Enable;
  GPIO_Init (GPIO5, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 ;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_InitStructure.GPIO_Alternate=GPIO_OutputAlt1;
  GPIO_Init (GPIO5, &GPIO_InitStructure);

  /* Configure ENET GPIO */
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_3;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_InitStructure.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init (GPIO5, &GPIO_InitStructure);

    /* Configure ENET GPIO */
  GPIO_DeInit(GPIO1);
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2 |GPIO_Pin_3 |GPIO_Pin_4 |GPIO_Pin_7 ;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull;
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_InitStructure.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init(GPIO1, &GPIO_InitStructure);

   /* Configure ROMANIS GPIO port 6*/
  GPIO_DeInit(GPIO6);
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_All;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_Alternate=GPIO_OutputAlt1;
  GPIO_Init (GPIO6, &GPIO_InitStructure);


  GPIO_DeInit(GPIO4);                        /* GPIO4 Deinitialization */
  /* GPIO Structure Initialization */
  GPIO_StructInit(&GPIO_InitStructure);
  /*GPIO4 configuration */
  GPIO_InitStructure.GPIO_Pin =GPIO_Pin_0 |GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Direction = GPIO_PinOutput;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull;
  GPIO_InitStructure.GPIO_Alternate = GPIO_OutputAlt2;
  GPIO_Init(GPIO4,&GPIO_InitStructure);


  GPIO_WriteBit(GPIO6,GPIO_Pin_0,Bit_RESET);  // Turn off DAQ

  GPIO_DeInit(GPIO7);
  GPIO_InitStructure.GPIO_Direction = GPIO_PinInput;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Type = GPIO_Type_PushPull ;
  GPIO_InitStructure.GPIO_Alternate = GPIO_InputAlt1  ;
  GPIO_InitStructure.GPIO_IPConnected = GPIO_IPConnected_Enable;
  GPIO_Init (GPIO5, &GPIO_InitStructure);
}

void GPS_init(){
  g_ts.lock=0;
  UART_InitStructure.UART_WordLength = UART_WordLength_8D;
  UART_InitStructure.UART_StopBits = UART_StopBits_1;
  UART_InitStructure.UART_Parity = UART_Parity_No ;
  UART_InitStructure.UART_BaudRate = 115200;
  UART_InitStructure.UART_HardwareFlowControl = UART_HardwareFlowControl_None;
  UART_InitStructure.UART_Mode = UART_Mode_Rx;
  UART_InitStructure.UART_FIFO = UART_FIFO_Enable;
  UART_InitStructure.UART_RxFIFOLevel = UART_FIFOLevel_1_2; /* FIFO size 16 bytes, FIFO level 8 bytes */
  UART_DeInit(UART0);
  UART_Init(UART0, &UART_InitStructure);
  UART_Cmd(UART0, ENABLE);
  }


int check_checksum(char *ptr,int sz) {
   u8 checksum=0;
   u32 i;
   char ck[3];
   char my[3];
   for(i=0;i<sz;i++) {
     if ('$'==ptr[i])
       continue;
     if ('*'==ptr[i]) {
       if (2<(sz - i)){
         ck[0]=ptr[i+1];
         ck[1]=ptr[i+2];
         ck[2]=0;
         sprintf((char *)my,"%02x",checksum);
         if (my[0]>96){
           my[0]-=32;
         }
         if (my[1]>96){
           my[1]-=32;
         }
         if ((my[0]==ck[0]) && (my[1]==ck[1]))
           return 1;
         else
           return 0;
       }else {
         return 0;
       }
     }
     if (0==checksum){
       checksum=ptr[i];
       continue;
     }
     checksum=checksum^ptr[i];
   }
   return 0;
}

void wiu_configuration() {
  volatile WIU_TypeDef  *gwiu = (WIU_TypeDef *)0x58001000;
  volatile VIC_TypeDef *gvic0 = (VIC_TypeDef *)0xFFFFF000;
  volatile VIC_TypeDef *gvic1 = (VIC_TypeDef *)0xFC000000;
  WIU_InitTypeDef WIU_InitStructure;
   /* Enable WIU clock */
  SCU_APBPeriphClockConfig(__WIU, ENABLE);
  WIU_DeInit();
  /* Enable the WIU & Clear the WIU line 12 pending bit */
  WIU_Cmd(ENABLE );
  WIU_ClearITPendingBit(WIU_Line12| WIU_Line17| WIU_Line25);
  WIU_InitStructure.WIU_Line = WIU_Line12| WIU_Line17 | WIU_Line25 ;
  WIU_InitStructure.WIU_TriggerEdge = WIU_RisingEdge ;
  WIU_Init(&WIU_InitStructure);
  SCU_WakeUpLineConfig(12);
  SCU_WakeUpLineConfig(17);

#ifdef OLD_BOARD
  SCU_WakeUpLineConfig(26);
#else
  SCU_WakeUpLineConfig(25);
#endif
  /* Configure the External interrupt group 3 priority */
  VIC_Config(EXTIT1_ITLine, VIC_FIQ, 1);
  VIC_Config(EXTIT2_ITLine, VIC_FIQ, 2);
  VIC_Config(EXTIT3_ITLine, VIC_FIQ, 3);

  return;
}

int process_gga(u8 *ptr,int *lock) {
  volatile WIU_TypeDef  *gwiu = (WIU_TypeDef *)0x58001000;
  volatile VIC_TypeDef *gvic0 = (VIC_TypeDef *)0xFFFFF000;
  volatile VIC_TypeDef *gvic1 = (VIC_TypeDef *)0xFC000000;
  char token[10][80];
  int max=10;
  int lck,sat;
  u32 token_cnt;
//      unsigned int  sec;
//      int res;

  token_cnt = tokenize((char *)ptr,token,',',max);
  if (8>token_cnt)
    return 0;
  lck=atoi(token[6]);
  sat=atoi(token[7]);
  if (0==lck) {
    *lock=0;
    return 0;
  }
  if ((sat>5) && ( 1==lck)){
    *lock=1;
    VIC_ITCmd(EXTIT1_ITLine, ENABLE);
    return 0;
  }


  return 0;
}
int process_zda(u8 *ptr,int *lock){
  char token[10][80];
  char buffer[255];
  int max=10;
  u32 token_cnt;
  unsigned int sec,tmp_sec;
  token_cnt=tokenize((char *)ptr,token,',',max);
  if (6>token_cnt )
    return 0;
  sec=0;
  convert_time(token[1],&sec);
  tmp_sec = sec;
  if (1!=*lock)	{
    g_zda_init=0;
    return 0;
  }
  if (1==*lock && 0==g_zda_init){
    g_zda_init=1;
    g_zda_time = sec;
    sprintf(buffer,"$GPSSYNC");
    ETHER_broadcast_data(buffer,strlen(buffer));

  }
  convert_date2(token[2],token[3],token[4],&sec);
  g_ts.sec=sec;
  //g_tics=TIM_GetCounterValue(TIM2);
  g_tics=0;
  g_zda_string_seen+=1;
  sprintf(buffer,"$ZDA ZDA count=%d ZDA_time= %d, TIM2_counter(g_tics)=%d\\n",g_zda_string_seen, g_ts.sec,g_tics);
  ETHER_broadcast_data(buffer,strlen(buffer));
  if (900 < (tmp_sec-g_zda_time)){
    g_ts.msec=g_ts.usec=0;
    g_ts.lock=1;
    VIC_ITCmd(EXTIT1_ITLine, DISABLE);
    sprintf(buffer,"$GPSEND");
    ETHER_broadcast_data(buffer,strlen(buffer));
    return 1;
    //return 0; // Debug the almanac
  }
  return 0;
}

void convert_date(char *date, unsigned int *sec) {
	char dd[3],mm[3],yy[5];
	int iy,id,im;
	int tmp;

	dd[0]=date[0];
	dd[1]=date[1];
	dd[2]=0;
	mm[0]=date[2];
	mm[1]=date[3];
	mm[2]=0;
	yy[0]='2';
	yy[1]='0';
	yy[2]=date[4];
	yy[3]=date[5];
	yy[4]=0;
	iy=atoi(yy);
	im=atoi(mm);
	id=atoi(dd);
	//Simple calculation as only difference is used
	tmp=(iy-1970)*365;
	tmp += ((im-1)*31);
	tmp += id;
	*sec += (tmp*24*3600);
	return;
}
void convert_date2(char *day,char *month, char *year, unsigned int *sec) {
	char dd[3],mm[3],yy[5];
	int iy,id,im;
	int tmp;

	dd[0]=day[0];
	dd[1]=day[1];
	dd[2]=0;
	mm[0]=month[0];
	mm[1]=month[1];
	mm[2]=0;
	yy[0]=year[0];
	yy[1]=year[1];
	yy[2]=year[2];
	yy[3]=year[3];
	yy[4]=0;
	iy=atoi(yy);
	im=atoi(mm);
	id=atoi(dd);
	//Simple calculation as only difference is used
	tmp=(iy-1970)*365;
	tmp += ((im-1)*31);
	tmp += id;
	*sec += (tmp*24*3600);
	return;
}

int convert_time(char *time, unsigned int *sec) {
	char hh[3],mm[3],ss[3],ms[4];
	int ih,im,is;
	int tmp;

	hh[0]=time[0];
	hh[1]=time[1];
	hh[2]=0;
	mm[0]=time[2];
	mm[1]=time[3];
	mm[2]=0;
	ss[0]=time[4];
	ss[1]=time[5];
	ss[2]=0;
	ms[0]=time[7];
	ms[1]=time[8];
	ms[2]=time[9];
        ms[3]=0;

	ih=atoi(hh);
	im=atoi(mm);
	is=atoi(ss);
	//Simple calculation as only difference is used
	tmp=(ih*3600);
	tmp += (im*60);
	tmp += is;
	*sec += tmp;
        return 1;
}
int tokenize(char *pptr,char token[10][80], unsigned char delim,int max) {
        char buffer[255], *ptr;
	int cnt;
	char *result;
	cnt=0;
        strcpy(buffer,pptr);
        ptr = buffer;
	result=(char *)strchr(ptr,delim);
	while(0!=result){
		if (cnt==max)
			return (cnt);
		*result=0;
		strcpy(token[cnt++],ptr);
		ptr = result+1;
		result=(char *)strchr(ptr,delim);
	}
        strcpy(token[cnt++],ptr);
	return cnt;
}





