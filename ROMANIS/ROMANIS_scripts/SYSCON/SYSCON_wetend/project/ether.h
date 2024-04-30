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
File	: ether.h
----------------------------
Project	: ANI-II
----------------------------
Module	: Syscon-Server Interface Program
----------------------------
CPU	: STR912, ARM9 Core

File Description:-
	This is the .h file for ether.c file. It has all the macro definitions of command used.

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

#ifndef ETHER_H
#define ETHER_H


//Defines
#define IPPROTO_UDP 0x11
#define IPPROTO_ICMP 0x01
//Ethernet
#define ARPPROTO    0x0806
#define IPPROTO    0x0800


//Structures
#pragma pack(1)
struct ethhdr
{
	unsigned char	h_dest[6];	/* destination eth addr	*/
	unsigned char	h_source[6];	/* source ether addr	*/
	unsigned short	h_proto;	/* packet type ID field	*/
};
#pragma pack(1)
struct iphdr {
  u8	ihl:4,
    version:4;
  u8	tos;
  u16	tot_len;
  u16	id;
  u16	frag_off;
  u8	ttl;
  u8	protocol;
  u16	check;
  u32	saddr;
  u32	daddr;
  /*The options start here. */
};
#pragma pack(1)
struct icmphdr{
  u8 type;
  u8 code;
  u16 check;
  u16 id;
  u16 seq;
};

#pragma pack(1)
struct arphdr{
 u16 hdr;
 u16 protocol;
 u8  hardware_len;
 u8  protocol_len;
 u16  opcode;
 unsigned char hardware_sender[6];
 u32  sender_ipaddr;
 unsigned char hardware_target[6];
 u32  target_ipaddr;
};

#pragma pack(1)
 struct udphdr {
  u16	source;
  u16	dest;
  u16	len;
  u16	check;
};

#pragma pack(1)
struct ethernet_packet {
  struct ethhdr ehdr ;
  struct iphdr  ihdr ;
  struct udphdr uhdr ;
};
#pragma pack(1)
struct icmp_packet {
  struct ethhdr ehdr;
  struct iphdr  ihdr ;
  struct icmphdr ichdr;
};

#pragma pack(1)
struct arp_packet {
  struct ethhdr ehdr;
  struct arphdr ahdr;
};

#pragma pack(1)
struct checksum_packet {
  u32 srcIP;
  u32 dstIP;
  u8 zero;
  u8 protocol;
  u16 udplen1;
  u16 srcPort;
  u16 dstPort;
  u16 udplen2;
  u16 chksum;
};

#pragma pack(1)
struct ethersetup {
  char in_buffer[1500];
  char out_buffer[1500];
  int in_len,out_len;
  char my_mac[6];
  u32 my_ipaddr;
  u16 my_port;
  unsigned char other_mac[6];
   u32 other_ipaddr;
  u16 other_port;

  u32 delay_clocks;
  u32 rcv_timestamp;
  u32 send_timestamp;

};

#pragma pack(1)
struct command_packet {
	u32 cmd;
	u32 param1;
	u32 param2;
        u32 param3;
};

#pragma pack(1)
struct response_packet {
	u32 cmd;
	u32 value1;
	u32 value2;
        u32 value3;
 	u32 value4;
	u32 value5;
        u32 value6;
        u32 value7;
        u32 value8;
        u32 value9;
        u32 value10;
};

//Function Declarations

void ETHER_init();
void ETHER_protocol() ;
int ETHER_read(int *len);
int ETHER_send(int len);
int ETHER_arp(struct arp_packet *pin_apk) ;
int ETHER_setup(unsigned char *pip,unsigned char *pmac,u16 port);
int ETHER_setup_other(unsigned char *pip,unsigned char *pmac,u16 port) ;
void ETHER_start();
void ETHER_sync();
s16 readTemp(void);
s16 readTempExt(char adrs);
static inline unsigned short ip_fast_csum(unsigned char * ip,
					  unsigned int len) ;
int ETHER_broadcast_data(char *pdata,int len);
void get_time(struct timestamp_data *pts,struct timestamp_data *p_date, unsigned int tics, unsigned int clocks);
//DEFINES
//This is the outgoing Timestamp at which the first sample of the Packet was
//send in the water by FPGA
#define CMD_GET_TX_TS   1

//This is the timestamp at which the correlation was set on the packet received
//from the water
#define CMD_GET_RCV_TS    2

//This is the delay in milliseconds to arrive at the outgoing Timestamp
#define CMD_SET_DELAY    3

//This is the timestamp at which the packet will be sent in the water in the
//future by the DSP
#define CMD_GET_SEND_TS  4

//This is the command to send the appropriate frequency to the MCU board
#define CMD_SET_OXO_FREQUENCY 5

//A wrong command
#define RES_WRONG_CMD    6

//Set the seconds till now
#define CMD_SET_TIMESTAMP 6

//Response for seconds elapsed
#define RES_ELAPSED_SECONDS 7

// constants
extern I2C_InitTypeDef   i2c;
static const unsigned char I2C_ADDR = 0x90;     //!< Temperature sensor ADC's I2C address.
static const int I2C_TIMEOUT = 895;             //!< I2C timeout (approx 0.1 ms).
static const int I2C_CLOCK_SPEED = 100000;      //!< I2C bus clock speed (max 400 kHz).

// ANI SYSCON command Definitions

#define SYSCON_CMD_TURN_ON_DAQ       0xA5A5001F
#define SYSCON_CMD_TURN_OFF_DAQ      0xA5A5002F
#define SYSCON_CMD_START_SAMPLE_CLK  0xA5A5003F
#define SYSCON_CMD_STOP_SAMPLE_CLK   0xA5A5004F
#define SYSCON_CMD_START_FANS        0xA5A5005F
#define SYSCON_CMD_STOP_FANS         0xA5A5006F
#define SYSCON_CMD_SET_AGC_VAL       0xA5A5007F
#define SYSCON_CMD_GET_TEMP_VAL      0xA5A5008F
#define SYSCON_CMD_TURN_ON_FNT1      0xA5A5009F
#define SYSCON_CMD_TURN_ON_FNT2      0xA5A500AF
#define SYSCON_CMD_TURN_ON_FNT3      0xA5A500BF
#define SYSCON_CMD_TURN_ON_FNT4      0xA5A500CF
#define SYSCON_CMD_TURN_OFF_FNT      0xA5A500FF
#define SYSCON_CMD_LEAK_DETECT       0xA5A50100

#define SYSCON_RES_TURN_ON_DAQ       0xA5A50017
#define SYSCON_RES_TURN_OFF_DAQ      0xA5A50027
#define SYSCON_RES_START_SAMPLE_CLK  0xA5A50037
#define SYSCON_RES_STOP_SAMPLE_CLK   0xA5A50047
#define SYSCON_RES_START_FANS        0xA5A50057
#define SYSCON_RES_STOP_FANS         0xA5A50067
#define SYSCON_RES_SET_AGC_VAL       0xA5A50077
#define SYSCON_RES_GET_TEMP_VAL      0xA5A50087
#define SYSCON_RES_TURN_ON_FNT1      0xA5A50097
#define SYSCON_RES_TURN_ON_FNT2      0xA5A500A7
#define SYSCON_RES_TURN_ON_FNT3      0xA5A500B7
#define SYSCON_RES_TURN_ON_FNT4      0xA5A500C7
#define SYSCON_RES_TURN_OFF_FNT      0xA5A500F7
#define SYSCON_RES_LEAK_DETECT       0xA5A50107

#define SYSCON_RES_CMD_NOT_SUP       0xA5A58888
#define SYSCON_RES_WRONG_CMD         0xA5A57777


#define HTONS(n) (u16)((((u16) (n)) << 8) | (((u16) (n)) >> 8))
#define NTOHS(n) (u16)((((u16) (n)) << 8) | (((u16) (n)) >> 8))


//#define OLD_BOARD 1
#define NEW_BOARD 1

#endif // ETHER_H
