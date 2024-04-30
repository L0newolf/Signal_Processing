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
File	: ether.c
----------------------------
Project	: ANI-II
----------------------------
Module	: Syscon-Server Interface Program
----------------------------
CPU	: STR912, ARM9 Core

File Description:-
	This file contains the ethernet/UDP implementation for ARM9, It looks for the UDP command from the
	dry-end server, performs the request and reply the response.

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
|11/02/2010|	V2.0	|	SUBASH K	|  Programmed GPIO for 4 front-end power ON
|08/03/2010|	V2.0	|	SUBASH K	|  Added Temperature and Leak Support
==========================================================================================*/

#include "string.h"
#include "stdlib.h"
#include "91x_conf.h"
#include "91x_lib.h"
#include "91x_enet.h"
#include "timestamp.h"
#include "stdio.h"
#include "ether.h"
int ETHER_icmp(struct icmp_packet *pin_icmp,int size) ;
static void get_time(struct timestamp_data *pts,struct timestamp_data *p_date, unsigned int tics, unsigned int clocks) ;
struct ethersetup g_eth;
extern struct timestamp_data g_ts;
extern volatile unsigned int  g_tics;
extern volatile unsigned int g_tx_clock,g_rx_clock;
extern volatile int g_gps_lock;
extern volatile unsigned short g_rx_counter;
extern volatile unsigned short g_tx_counter;
extern float g_oxo_frequency;
extern TIM_InitTypeDef TIM_InitStructure;
static void hex_to_bin(char *in,int insz,char *out,int *outsz);
//#define TEST
//API to initialize the Ethernet
char MAC_ADDR0;
char MAC_ADDR1;
char MAC_ADDR2;
char MAC_ADDR3;
char MAC_ADDR4;
char MAC_ADDR5;

void ETHER_init() {
   GPIO_InitTypeDef GPIO_Struct;
   ENET_MACConfig MAC_Config;
  /* CPU running @96MHZ*/
  /* Enable ENET and MII PHY clocks */
  SCU_AHBPeriphClockConfig(__ENET, ENABLE);
  SCU_AHBPeriphReset(__ENET,DISABLE);
  SCU_PHYCLKConfig(ENABLE);
#if 0
  /* Configure ENET GPIO */
  GPIO_DeInit(GPIO1);
  GPIO_Struct.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2 |GPIO_Pin_3 |GPIO_Pin_4 |GPIO_Pin_7 ;
  GPIO_Struct.GPIO_Type = GPIO_Type_PushPull;
  GPIO_Struct.GPIO_Direction = GPIO_PinOutput;
  GPIO_Struct.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_Struct.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init(GPIO1, &GPIO_Struct);

  GPIO_DeInit(GPIO5);
  GPIO_Struct.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_3;
  GPIO_Struct.GPIO_Type = GPIO_Type_PushPull;
  GPIO_Struct.GPIO_Direction = GPIO_PinOutput;
  GPIO_Struct.GPIO_IPConnected = GPIO_IPConnected_Disable;
  GPIO_Struct.GPIO_Alternate=GPIO_OutputAlt2;
  GPIO_Init(GPIO5, &GPIO_Struct);
#endif
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
  ENET_SetOperatingMode(AUTO_NEGOTIATION);
  return;
}

void ETHER_start() {
  ENET_Start();
}
int ETHER_setup(unsigned char *pip,unsigned char *pmac,u16 port) {

  unsigned char *ptr = (unsigned char *) &g_eth.my_ipaddr;
  char token[10][80];
  char mymac[8];
  int sz;
  int max=10;
  u32 token_cnt;

#if 0
  g_eth.my_mac[0]=MAC_ADDR0;
  g_eth.my_mac[1]=MAC_ADDR1;
  g_eth.my_mac[2]=MAC_ADDR2;
  g_eth.my_mac[3]=MAC_ADDR3;
  g_eth.my_mac[4]=MAC_ADDR4;
  g_eth.my_mac[5]=MAC_ADDR5;
#endif
#if 1
  hex_to_bin(pmac,12,mymac,&sz);
  MAC_ADDR0=mymac[0];
  MAC_ADDR1=mymac[1];
  MAC_ADDR2=mymac[2];
  MAC_ADDR3=mymac[3];
  MAC_ADDR4=mymac[4];
  MAC_ADDR5=mymac[5];
  g_eth.my_mac[0]=MAC_ADDR0;
  g_eth.my_mac[1]=MAC_ADDR1;
  g_eth.my_mac[2]=MAC_ADDR2;
  g_eth.my_mac[3]=MAC_ADDR3;
  g_eth.my_mac[4]=MAC_ADDR4;
  g_eth.my_mac[5]=MAC_ADDR5;

#endif
  token_cnt = tokenize((char *)pip,token,'.',max);
  if (4> token_cnt){
  	return ERROR;
   }
   ptr[0]=atoi(token[0]);
   ptr[1]=atoi(token[1]);
   ptr[2]=atoi(token[2]);
   ptr[3]=atoi(token[3]);

   g_eth.my_port=HTONS(port);
   g_eth.delay_clocks=(g_oxo_frequency/10);
   return 1;
}
int ETHER_setup_other(unsigned char *pip,unsigned char *pmac,u16 port) {

  unsigned char *ptr = (unsigned char *) &g_eth.other_ipaddr;
  char token[10][80];
  char other_mac[8];
  int sz;
  int max=10;
  u32 token_cnt;

  hex_to_bin(pmac,12,other_mac,&sz);
  g_eth.other_mac[0]=other_mac[0];
  g_eth.other_mac[1]=other_mac[1];
  g_eth.other_mac[2]=other_mac[2];
  g_eth.other_mac[3]=other_mac[3];
  g_eth.other_mac[4]=other_mac[4];
  g_eth.other_mac[5]=other_mac[5];

  token_cnt = tokenize((char *)pip,token,'.',max);
  if (4> token_cnt){
  	return ERROR;
   }
   ptr[0]=atoi(token[0]);
   ptr[1]=atoi(token[1]);
   ptr[2]=atoi(token[2]);
   ptr[3]=atoi(token[3]);

   g_eth.other_port=HTONS(port);
   g_eth.delay_clocks=(g_oxo_frequency/10);
   return 1;
}

int ETHER_icmp(struct icmp_packet *pin_icmp,int size) {
    char buffer[1500];
    char *data_out, *data_in;
    u16 checksum;
    struct icmp_packet *ipk = (struct icmp_packet *)buffer;
    int datalen,icmplen;
    datalen = size - sizeof(struct icmp_packet);
    icmplen = sizeof(struct iphdr) + sizeof(struct icmphdr)+ datalen;
    data_in = (char *) ( (unsigned char *)pin_icmp + sizeof(struct icmp_packet));
    data_out = (char *) ( buffer + sizeof(struct icmp_packet));
    memcpy(data_out,data_in,(size - sizeof(struct icmp_packet)));

    //Eth Header
    memcpy((char *)ipk->ehdr.h_dest,(char *)g_eth.other_mac,6);
    memcpy((char *)ipk->ehdr.h_source,(char *)g_eth.my_mac,6);
    ipk->ehdr.h_proto=HTONS(IPPROTO);
    //IP header
    ipk->ihdr.version=4;
    ipk->ihdr.ihl=5;
    ipk->ihdr.tos=0;
    ipk->ihdr.tot_len  = HTONS(icmplen);
    ipk->ihdr.id=0;
    ipk->ihdr.frag_off=0x0040;
    ipk->ihdr.ttl=64;
    ipk->ihdr.protocol=1; //ICMP
    ipk->ihdr.saddr=g_eth.my_ipaddr;
    ipk->ihdr.daddr=g_eth.other_ipaddr;
    ipk->ihdr.check=0;
    ipk->ihdr.check=ip_fast_csum((unsigned char *)&ipk->ihdr,sizeof(struct iphdr));

    //ICMP header
    ipk->ichdr.type=0;
    ipk->ichdr.code=0;
    ipk->ichdr.check=0;
    ipk->ichdr.id=pin_icmp->ichdr.id;
    ipk->ichdr.seq=pin_icmp->ichdr.seq;
    checksum=ip_fast_csum((unsigned char *)&ipk->ichdr,size - sizeof(struct ethhdr) - sizeof(struct iphdr));
    ipk->ichdr.check=checksum;
    //Transmit
    ENET_HandleTxPkt (buffer,size);
    return 1;
}



int ETHER_arp(struct arp_packet *pin_apk) {
	char buffer[256];
	struct arp_packet *pout_apk = (struct arp_packet *) buffer;
	if ((1==HTONS(pin_apk->ahdr.opcode)) && ( pin_apk->ahdr.target_ipaddr==g_eth.my_ipaddr)){
          //Eth Header
  	    memcpy((char *)pout_apk->ehdr.h_dest,(char *)pin_apk->ehdr.h_source,6);
  	    memcpy((char *)pout_apk->ehdr.h_source,(char *)g_eth.my_mac,6);
	    pout_apk->ehdr.h_proto=HTONS(0x0806);
         // ARP body
            pout_apk->ahdr.hdr=pin_apk->ahdr.hdr;
	    pout_apk->ahdr.protocol=pin_apk->ahdr.protocol;
	    pout_apk->ahdr.hardware_len=pin_apk->ahdr.hardware_len;
	    pout_apk->ahdr.protocol_len=pin_apk->ahdr.protocol_len;
            pout_apk->ahdr.opcode=HTONS(2);
	    memcpy(pout_apk->ahdr.hardware_sender,g_eth.my_mac,6);
	    pout_apk->ahdr.sender_ipaddr=g_eth.my_ipaddr;
	    memcpy(pout_apk->ahdr.hardware_target,pin_apk->ahdr.hardware_sender,6);
	    pout_apk->ahdr.target_ipaddr=pin_apk->ahdr.sender_ipaddr;
          //Transmit
            ENET_HandleTxPkt (buffer,sizeof(struct arp_packet));
	}
	return 1;
}

//API to read the ethernet packet
int ETHER_read(int *len) {
  int res;
  struct ethernet_packet *epk;
  struct arp_packet      *apk;
  struct icmp_packet     *ipk;
//  struct command_packet *cmdpk;

  while(1) {
    res =  ENET_HandleRxPkt (g_eth.in_buffer);
    if (ERROR==res)
      continue;
    *len = res;
    //Extract Data
    epk = (struct ethernet_packet *)g_eth.in_buffer;
    apk = (struct arp_packet *)g_eth.in_buffer;
    ipk = (struct icmp_packet *)g_eth.in_buffer;
#if 0
    cmdpk=(struct command_packet *)(((char *)epk) + sizeof(struct ethernet_packet));
#endif
    if (ARPPROTO ==HTONS(apk->ehdr.h_proto) ){
    	  ETHER_arp(apk);
          continue;
    }
    if (IPPROTO !=  HTONS(apk->ehdr.h_proto)){
          continue;
    }
    //Verify the protocol
    if ( (IPPROTO_UDP!= epk->ihdr.protocol) && (IPPROTO_ICMP != epk->ihdr.protocol)) {
          continue;
    }

    if (memcmp((const char *)epk->ehdr.h_dest,(const char *)g_eth.my_mac,6)){
      continue;
    }

    if (IPPROTO_UDP == epk->ihdr.protocol) {
      if (epk->uhdr.dest != g_eth.my_port){
        continue;
      }
    }
    memcpy(g_eth.other_mac,epk->ehdr.h_source,6);
    g_eth.other_ipaddr=epk->ihdr.saddr;
    g_eth.other_port=epk->uhdr.source;
    if (IPPROTO_ICMP == epk->ihdr.protocol) {
      ETHER_icmp(ipk,res);
      continue;
    }
    *len=HTONS(epk->uhdr.len);
    return *len;
  }
  //return 1;
}


int ETHER_send(int len){
	struct checksum_packet *ptr;
	struct ethernet_packet *epk ;
	u16 checksum;
	//Calculate the checksum

	ptr = (struct checksum_packet *)( ((char *)g_eth.out_buffer) + sizeof(struct ethernet_packet) -sizeof(struct checksum_packet));
	ptr->srcIP=g_eth.my_ipaddr;
	ptr->dstIP=g_eth.other_ipaddr;
	ptr->zero=0;
	ptr->protocol=0x11;
	ptr->udplen1=HTONS(sizeof(struct udphdr)+len);
	ptr->srcPort=g_eth.my_port;
	ptr->dstPort=g_eth.other_port;
	ptr->udplen2=ptr->udplen1;
	ptr->chksum=0;
	checksum=ip_fast_csum((unsigned char *)ptr,sizeof(struct checksum_packet) + len);

	//Eth Header
	 epk = (struct ethernet_packet *) g_eth.out_buffer;
  	memcpy((char *)epk->ehdr.h_dest,(char *)g_eth.other_mac,6);
  	memcpy((char *)epk->ehdr.h_source,(char *)g_eth.my_mac,6);
	epk->ehdr.h_proto=HTONS(0x0800);

	 //IP Header
 	epk->ihdr.version=4;
   	epk->ihdr.ihl=5;
   	epk->ihdr.tos=0;
	epk->ihdr.tot_len  = HTONS(sizeof(struct iphdr) + sizeof(struct udphdr) + len);
   	epk->ihdr.id=0;
   	epk->ihdr.frag_off=0x0040;
   	epk->ihdr.ttl=64;
   	epk->ihdr.protocol=17; //UDP
   	epk->ihdr.saddr=g_eth.my_ipaddr;
   	epk->ihdr.daddr=g_eth.other_ipaddr;
        epk->ihdr.check=0;
   	epk->ihdr.check=ip_fast_csum((unsigned char *)&epk->ihdr,sizeof(struct iphdr));

	//UDP Header
	epk->uhdr.source=g_eth.my_port;
	epk->uhdr.dest=g_eth.my_port;
	epk->uhdr.len=HTONS(sizeof(struct udphdr)+len);
	epk->uhdr.check=checksum;

	//Transmit
    	ENET_HandleTxPkt (g_eth.out_buffer,sizeof(struct ethernet_packet) + len);
	return len;
}
int ETHER_broadcast_data(char *pdata,int len){
	struct checksum_packet *ptr;
	struct ethernet_packet *epk ;
	u16 checksum;
        char *payload_data;
        int padding_len;
	//Calculate the checksum
	payload_data=(char *)((char *)g_eth.out_buffer + sizeof(struct ethernet_packet));
        //Copy
        memcpy((char *)payload_data,(char *)pdata,len);
        //Calculate the Checksum
	ptr = (struct checksum_packet *)( ((char *)g_eth.out_buffer) + sizeof(struct ethernet_packet) -sizeof(struct checksum_packet));
	ptr->srcIP=g_eth.my_ipaddr;
	ptr->dstIP=g_eth.other_ipaddr;
	ptr->zero=0;
	ptr->protocol=0x11;
	ptr->udplen1=HTONS(sizeof(struct udphdr)+len);
	ptr->srcPort=g_eth.my_port;
	ptr->dstPort=g_eth.other_port;
	ptr->udplen2=ptr->udplen1;
	ptr->chksum=0;
        padding_len=sizeof(struct checksum_packet) + len;
        if (1==padding_len%2){
          padding_len+=1;
          payload_data[len]=0;
        }
	checksum=ip_fast_csum((unsigned char *)ptr,padding_len);

	//Eth Header
	 epk = (struct ethernet_packet *) g_eth.out_buffer;
  	memcpy((char *)epk->ehdr.h_dest,(char *)g_eth.other_mac,6);
  	memcpy((char *)epk->ehdr.h_source,(char *)g_eth.my_mac,6);
	epk->ehdr.h_proto=HTONS(0x0800);

	 //IP Header
 	epk->ihdr.version=4;
   	epk->ihdr.ihl=5;
   	epk->ihdr.tos=0;
	epk->ihdr.tot_len  = HTONS(sizeof(struct iphdr) + sizeof(struct udphdr) + len);
   	epk->ihdr.id=0;
   	epk->ihdr.frag_off=0x0040;
   	epk->ihdr.ttl=64;
   	epk->ihdr.protocol=17; //UDP
   	epk->ihdr.saddr=g_eth.my_ipaddr;
   	epk->ihdr.daddr=g_eth.other_ipaddr;
        epk->ihdr.check=0;
   	epk->ihdr.check=ip_fast_csum((unsigned char *)&epk->ihdr,sizeof(struct iphdr));

	//UDP Header
	epk->uhdr.source=g_eth.my_port;
	epk->uhdr.dest=g_eth.other_port;
	epk->uhdr.len=HTONS(sizeof(struct udphdr)+len);
	epk->uhdr.check=checksum;

	//Transmit
    	ENET_HandleTxPkt (g_eth.out_buffer,sizeof(struct ethernet_packet) + len);
	return len;
}
void ETHER_sync() {
  volatile int sync;
  struct command_packet *cmdpk;
  struct response_packet *respk;
  int len;
  sync=0;

  cmdpk = (struct command_packet *)   ( ((char *)g_eth.in_buffer) + sizeof(struct ethernet_packet));
  respk = (struct response_packet *)  ( ((char *)g_eth.out_buffer) + sizeof(struct ethernet_packet));
  respk->cmd=0xFF;
  while(0==sync) {
    //Read the UDP data
    if (ERROR==ETHER_read(&len)) {
      continue;
    }
    if (CMD_SET_TIMESTAMP==cmdpk->cmd){
      if (1==g_gps_lock){
        //VIC_ITCmd(EXTIT1_ITLine, DISABLE);
        g_ts.sec=cmdpk->param1;
        g_ts.msec=0;
        g_ts.usec=0;
        g_ts.lock=1;
        respk->cmd=cmdpk->cmd;
        respk->value1=cmdpk->param1;
        respk->value2=0;
        respk->value3=0;
        for(int i=0;i<5;i++) {
          ETHER_send(sizeof(struct response_packet));
        }
        sync=1;
      }
    }
  }
  return;
}
void ETHER_protocol() {
	struct command_packet *cmdpk;
	struct response_packet *respk;
	int len;
	u16 cntr_value,delta,cmp_value;
        s16 Temp;
        u32 res_value;
        char temp1, temp2, leak;
        struct timestamp_data ts;

	cmdpk = (struct command_packet *)   ( ((char *)g_eth.in_buffer) + sizeof(struct ethernet_packet));
	respk = (struct response_packet *)  ( ((char *)g_eth.out_buffer) + sizeof(struct ethernet_packet));
        respk->cmd=0xFF;
        //while(1) ETHER_send(sizeof(struct response_packet));
	while(1) {

 	//Read the UDP data
		if (ERROR==ETHER_read(&len)) {
			continue;
		}
		/* Actual ANI implementation starts here...*/
		switch(cmdpk->cmd) {

                case SYSCON_CMD_TURN_ON_DAQ:        //Turn on the Power supply for DAQ
                  respk->cmd=SYSCON_RES_CMD_NOT_SUP;
                  //GPIO_WriteBit(GPIO6,GPIO_Pin_0,Bit_SET);
                  break;

		case SYSCON_CMD_TURN_OFF_DAQ:       //Turn off the Power supply for DAQ
                  respk->cmd=SYSCON_RES_CMD_NOT_SUP;
                  //GPIO_WriteBit(GPIO6,GPIO_Pin_0,Bit_RESET);
                  break;

                case SYSCON_CMD_TURN_ON_FNT1:        //Turn on the Power supply for Front End Electronics-section 1
                  respk->cmd=SYSCON_RES_TURN_ON_FNT1;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_1,Bit_SET);
                  break;

                case SYSCON_CMD_TURN_ON_FNT2:        //Turn on the Power supply for Front End Electronics-section 2
                  respk->cmd=SYSCON_RES_TURN_ON_FNT2;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_2,Bit_SET);
                  break;

                case SYSCON_CMD_TURN_ON_FNT3:        //Turn on the Power supply for Front End Electronics-section 3
                  respk->cmd=SYSCON_RES_TURN_ON_FNT3;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_3,Bit_SET);
                  break;

                case SYSCON_CMD_TURN_ON_FNT4:        //Turn on the Power supply for Front End Electronics-section 4
                  respk->cmd=SYSCON_RES_TURN_ON_FNT4;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_4,Bit_SET);
                  break;

		case SYSCON_CMD_TURN_OFF_FNT:       //Turn off the Power supply for Front End Electronics
                  respk->cmd=SYSCON_RES_TURN_OFF_FNT;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_1,Bit_RESET);
                  GPIO_WriteBit(GPIO6,GPIO_Pin_2,Bit_RESET);
                  GPIO_WriteBit(GPIO6,GPIO_Pin_3,Bit_RESET);
                  GPIO_WriteBit(GPIO6,GPIO_Pin_4,Bit_RESET);
                  break;

                  case SYSCON_CMD_START_SAMPLE_CLK: //Start the sampling clock
                  respk->cmd=SYSCON_RES_START_SAMPLE_CLK;
                  TIM_CounterCmd(TIM2, TIM_START);
                  break;

		case SYSCON_CMD_STOP_SAMPLE_CLK: //Stop the sampling clock
                  respk->cmd=SYSCON_RES_STOP_SAMPLE_CLK;
                  TIM_CounterCmd(TIM2, TIM_STOP);
                  break;

                case SYSCON_CMD_START_FANS: //Turn On the cooling Fans
                  respk->cmd=SYSCON_RES_START_FANS;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_0,Bit_SET);
                  break;

		case SYSCON_CMD_STOP_FANS://Turn off the cooling fans
                  respk->cmd=SYSCON_RES_STOP_FANS;
                  GPIO_WriteBit(GPIO6,GPIO_Pin_0,Bit_RESET);
                  break;

                case SYSCON_CMD_SET_AGC_VAL:        //Set AGC value
                  respk->cmd=SYSCON_RES_SET_AGC_VAL;
                  temp1 = (char)cmdpk->param1;
                  temp1 = temp1<<5;
                  temp2 = 0x1F & GPIO_Read(GPIO6);
                  GPIO_Write(GPIO6, temp2|temp1);
                  respk->value1 = (temp2|temp1)>>5;
                  break;

                case SYSCON_CMD_GET_TEMP_VAL:        //Get Onboard Temperature value
                  respk->cmd=SYSCON_RES_GET_TEMP_VAL;
                  Temp = readTempExt(0x90);
                  respk->value1 = Temp;
                  Temp = readTempExt(0x92);
                  respk->value2 = Temp;
                  Temp = readTempExt(0x94);
                  respk->value3 = Temp;
                  Temp = readTempExt(0x96);
                  respk->value4 = Temp;
                  break;

                case SYSCON_CMD_LEAK_DETECT:        //Check value from Leak Detector
                   respk->cmd=SYSCON_RES_LEAK_DETECT;
                   leak = GPIO_ReadBit(GPIO7, GPIO_Pin_0);
                   respk->value1 = leak;
                   break;


		default:                  //Unknown Command
		  respk->cmd=SYSCON_RES_WRONG_CMD;
		  respk->value1=cmdpk->cmd;
		}
		ETHER_send(sizeof(struct response_packet));
	}
}

/*
 * computes the checksum of the TCP/UDP pseudo-header
 * returns a 16-bit checksum, already complemented
 */
static inline unsigned short ip_fast_csum(unsigned char * ip,
					  unsigned int len) {

  unsigned int sum=0;
  unsigned short *pip = (unsigned short *)ip;
  while(len >1){
    sum+=*pip;
   pip+=1;
    if (sum & 0x80000000)
      sum = (sum & 0xFFFF)+ (sum >> 16);
    len -=2;
  }
  if (len)
    sum += (unsigned short) *(unsigned char *)ip;

  while(sum >> 16)
    sum = (sum & 0xFFFF) + (sum >> 16);

  return ~sum;
}

void get_time(struct timestamp_data *pts,struct timestamp_data *p_date, unsigned int tics, unsigned int clocks) {
  double dsec,dmsec,dusec;
  unsigned int isec,imsec,iusec;
  volatile unsigned int what;

  dsec = (double) ((double)(tics+clocks)/g_oxo_frequency);
  isec =(int)dsec;

  dmsec=(double)(dsec-isec)*1000.0;
  imsec=(int)dmsec;

  dusec=(double)(dmsec-imsec)*1000.0;
  iusec=(int)dusec;


  pts->usec=iusec;
  pts->msec=imsec;
  pts->sec=g_ts.sec+isec;
  return;
}

/**
   Function hex_to_bin
   Parameter
           in:   Hex data
	   insz: size of the Hex Data in bytes
	   out:  converted bin data
           outsz: size of the converted bin data , is half of the hex representation
   Return
          void
   Converts from string in Hex format to binary data for programming
*/

static void hex_to_bin(char *in,int insz,char *out,int *outsz){
  int i,j,v;
  unsigned char b='0';
  for (i=0;i<insz/2;i++){
    for (j=0;j<2;j++){

      if (('9'-in[2*i+j])<0) {
	if (('Z'-in[2*i+j])<0) {
	  v=in[2*i+j]-'a'+ 10;
	} else {
	  v=in[2*i+j]-'A'+ 10;
	}
      }else {
	v=in[2*i+j]-'0';
      }
      if (0==j)
	b=(v&0x0F)<<4;
      else
	b=b|(v&0x0F);
    }
    out[i]=b;
  }
  *outsz=insz/2;
  return;
}
static int bin_to_hex(unsigned char *in, int insz, unsigned char *out,int *outsz){
  int i;
  unsigned char *p = out;

  for (i=0;i<insz;i++){
    sprintf((char *)p,"%02x",in[i]);
    p = p+2;
    *p=0;
  }
  *outsz=(p-out);
  return 1;
}

/*
**************************************************************************
Function: udp_sum_calc()
Description: Calculate UDP checksum
***************************************************************************
*/

//typedef unsigned short u16;
//typedef unsigned long u32;

u16 udp_sum_calc(u16 len_udp, u16 src_addr[],u16 dest_addr[], int padding, u16 buff[])
{
u16 prot_udp=17;
u16 padd=0;
u16 word16;
u32 sum;
u32 i;

	// Find out if the length of data is even or odd number. If odd,
	// add a padding byte = 0 at the end of packet
	if (padding&1==1){
		padd=1;
		buff[len_udp]=0;
	}

	//initialize sum to zero
	sum=0;

	// make 16 bit words out of every two adjacent 8 bit words and
	// calculate the sum of all 16 vit words
	for (i=0;i<len_udp+padd;i=i+2){
		word16 =((buff[i]<<8)&0xFF00)+(buff[i+1]&0xFF);
		sum = sum + (unsigned long)word16;
	}
	// add the UDP pseudo header which contains the IP source and destinationn addresses
	for (i=0;i<4;i=i+2){
		word16 =((src_addr[i]<<8)&0xFF00)+(src_addr[i+1]&0xFF);
		sum=sum+word16;
	}
	for (i=0;i<4;i=i+2){
		word16 =((dest_addr[i]<<8)&0xFF00)+(dest_addr[i+1]&0xFF);
		sum=sum+word16;
	}
	// the protocol number and the length of the UDP packet
	sum = sum + prot_udp + len_udp;

	// keep only the last 16 bits of the 32 bit calculated sum and add the carries
    	while (sum>>16)
		sum = (sum & 0xFFFF)+(sum >> 16);

	// Take the one's complement of sum
	sum = ~sum;

return ((u16) sum);
}

/*int waitForEvent(u16 evmask, u16 event)
{
  for (int i = 0; i < I2C_TIMEOUT; i++)
    if ((I2C_GetLastEvent(I2C0) & evmask) == event) return 0;
  return -1;
}*/

int waitForEvent(u16 evmask, u16 event)
{
  for (int i = 0; i < I2C_TIMEOUT; i++)
    if ((I2C_GetLastEvent(I2C1) & evmask) == event) return 0;
  return -1;
}


s16 readTemp(void)
{
  s16 x;
  char* b = (char*)&x;
  I2C_CheckEvent(I2C0,I2C_FLAG_BUSY);
  I2C_GenerateStart(I2C0,ENABLE);
  waitForEvent(I2C_EVENT_MASTER_MODE_SELECT,I2C_EVENT_MASTER_MODE_SELECT);
  I2C_Send7bitAddress(I2C0,I2C_ADDR,I2C_MODE_RECEIVER);
  waitForEvent(I2C_EVENT_MASTER_MODE_SELECTED,I2C_EVENT_MASTER_MODE_SELECTED);
  I2C_Cmd(I2C0,ENABLE);
  waitForEvent(I2C_EVENT_MASTER_BYTE_RECEIVED,I2C_EVENT_MASTER_BYTE_RECEIVED);
  b[1] = I2C_ReceiveData(I2C0);
  waitForEvent(I2C_EVENT_MASTER_BYTE_RECEIVED,I2C_EVENT_MASTER_BYTE_RECEIVED);
  I2C_GenerateSTOP(I2C0,ENABLE);
  b[0] = I2C_ReceiveData(I2C0);
  x >>= 7;
  I2C_DeInit(I2C0);
  I2C_Cmd(I2C0,ENABLE);
  i2c.I2C_GeneralCall = I2C_GeneralCall_Disable;
  i2c.I2C_Ack = I2C_Ack_Enable;
  i2c.I2C_CLKSpeed = I2C_CLOCK_SPEED;
  i2c.I2C_OwnAddress = 0;     // master does not require an address
  I2C_Init(I2C0,&i2c);
  I2C_ITConfig(I2C0,DISABLE);
  return x;
}


s16 readTempExt(char adrs)
{
  s16 x;
  char* b = (char*)&x;
  I2C_CheckEvent(I2C1,I2C_FLAG_BUSY);
  I2C_GenerateStart(I2C1,ENABLE);
  waitForEvent(I2C_EVENT_MASTER_MODE_SELECT,I2C_EVENT_MASTER_MODE_SELECT);
  I2C_Send7bitAddress(I2C1,adrs,I2C_MODE_RECEIVER);
  waitForEvent(I2C_EVENT_MASTER_MODE_SELECTED,I2C_EVENT_MASTER_MODE_SELECTED);
  I2C_Cmd(I2C1,ENABLE);
  waitForEvent(I2C_EVENT_MASTER_BYTE_RECEIVED,I2C_EVENT_MASTER_BYTE_RECEIVED);
  b[1] = I2C_ReceiveData(I2C1);
  waitForEvent(I2C_EVENT_MASTER_BYTE_RECEIVED,I2C_EVENT_MASTER_BYTE_RECEIVED);
  I2C_GenerateSTOP(I2C1,ENABLE);
  b[0] = I2C_ReceiveData(I2C1);
  x >>= 7;
  I2C_DeInit(I2C1);
  I2C_Cmd(I2C1,ENABLE);
  i2c.I2C_GeneralCall = I2C_GeneralCall_Disable;
  i2c.I2C_Ack = I2C_Ack_Enable;
  i2c.I2C_CLKSpeed = I2C_CLOCK_SPEED;
  i2c.I2C_OwnAddress = 0;     // master does not require an address
  I2C_Init(I2C1,&i2c);
  I2C_ITConfig(I2C1,DISABLE);
  //if (x <= 0) log->warning("Bad temperature sensor output (%d)",x);
  return x;
}



