////////////////////////////////////////////////////////////////////////////////////////////
//			*** ACOUSTIC RESEARCH LABORATORY CONFIDENTIAL***		  //
// 											  //
//	The information contained in this file remains the property of Acoustic Research  //
// Laboratory, National University Of Singapore. The information is of use for internal   //
// evaluation, operation and/or maintenence purposes within the ARL only. Without prior   //
// written consent of an authorised representative of ARL, you may not reproduce,         //
// represent, or download through any means.						  //
//											  //
////////////////////////////////////////////////////////////////////////////////////////////

/*========================================================================================
File	: syscon.c
----------------------------
Project	: ANI-II
----------------------------
Module	: Syscon-Server Interface Program
----------------------------
CPU	: Intel, Dell PowerEdge-T710 Server

File Description:-
	This Program Sends command to the syscon (ARM9-system Controller) and receives the 
responce, prints it on the display...

Procedure:-
       1. Compile This file: gcc -Wall syscon.c -o ATT
       2. copy ATT to /usr/bin. e.g: sudo cp ATT /usr/bin
       3. Now you can send command. e.g: "ATT fanon"
       4. Type "ATT help" to get the list of all Commands 

File History:-
-------------------------------------------------------------------------------------------
|02/11/2009|	V1.0	|	SUBASH K	|  Created Source File...
|24/11/2009|	V1.0	|	SUBASH K	|  Added Help Messages... 	
|19/12/2009|	V1.0	| 	SUBASH K	|  Added Frontend control Command...
|07/03/2010|	V1.0	|	SUBASH K	|  Added 4 temp display
|22/03/2010|	V1.0	|	SUBASH K	|  Changed IP address to 57
==========================================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <regex.h>
#include <fcntl.h>
#include <errno.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <regex.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <time.h>

#define MAX_LINE_LENGTH 255

/*All the Commands are Self explanatory*/
#define SYSCON_CMD_TURN_ON_DAQ       0xA5A5001F
#define SYSCON_CMD_TURN_OFF_DAQ      0xA5A5002F
#define SYSCON_CMD_START_SAMPLE_CLK  0xA5A5003F
#define SYSCON_CMD_STOP_SAMPLE_CLK   0xA5A5004F
#define SYSCON_CMD_START_FANS        0xA5A5005F
#define SYSCON_CMD_STOP_FANS         0xA5A5006F
#define SYSCON_CMD_SET_PGC_VAL       0xA5A5007F
#define SYSCON_CMD_GET_TEMP_VAL      0xA5A5008F
#define SYSCON_CMD_TURN_ON_FNT1      0xA5A5009F
#define SYSCON_CMD_TURN_ON_FNT2      0xA5A500AF
#define SYSCON_CMD_TURN_ON_FNT3      0xA5A500BF
#define SYSCON_CMD_TURN_ON_FNT4      0xA5A500CF
#define SYSCON_CMD_TURN_OFF_FNT      0xA5A500FF
#define SYSCON_CMD_LEAK_DETECT	     0xA5A50100	

#define SYSCON_RES_TURN_ON_DAQ       0xA5A50017
#define SYSCON_RES_TURN_OFF_DAQ      0xA5A50027
#define SYSCON_RES_START_SAMPLE_CLK  0xA5A50037
#define SYSCON_RES_STOP_SAMPLE_CLK   0xA5A50047
#define SYSCON_RES_START_FANS        0xA5A50057
#define SYSCON_RES_STOP_FANS         0xA5A50067
#define SYSCON_RES_SET_PGC_VAL       0xA5A50077
#define SYSCON_RES_GET_TEMP_VAL      0xA5A50087
#define SYSCON_RES_TURN_ON_FNT1      0xA5A50097
#define SYSCON_RES_TURN_ON_FNT2      0xA5A500A7
#define SYSCON_RES_TURN_ON_FNT3      0xA5A500B7
#define SYSCON_RES_TURN_ON_FNT4      0xA5A500C7
#define SYSCON_RES_TURN_OFF_FNT      0xA5A500F7
#define SYSCON_RES_LEAK_DETECT	     0xA5A50107	


#define SYSCON_RES_CMD_NOT_SUP       0xA5A58888
#define SYSCON_RES_WRONG_CMD         0xA5A57777


struct cmd_packet {
  unsigned int cmd;
  unsigned int param1;
  unsigned int param2;
  unsigned int param3;
};/*Control Packet from /server to syscon*/


struct res_packet {
  unsigned int cmd;
  unsigned int value1;
  unsigned int value2;
  unsigned int value3;
  unsigned int value4;
  unsigned int value5;
  unsigned int value6;
};/*Response packet from syscon to server*/

int main (int argc, char *argv[]){
unsigned int  command,param1,param2,param3;
  struct timeval tv_in,tv_out;
  int repeat,delay;
  struct cmd_packet cmdpk;
  struct res_packet respk;

  int c;/* UDP  related*/
  int command_flag, ip_flag,ip2_flag,param_flag;
  char ip[MAX_LINE_LENGTH] ,ip2[MAX_LINE_LENGTH];
  float temp;
  char leak;
 	
 strcpy(ip,"192.168.0.47"); 
  
if (argc < 1){puts("\nInvalid Number of Arguments");exit(0);}

/*..... Identify the Command .....*/
if (!strcmp(argv[1],"damon"))
	cmdpk.cmd=SYSCON_CMD_TURN_ON_DAQ;

else if (!strcmp(argv[1],"damoff"))
	cmdpk.cmd=SYSCON_CMD_TURN_OFF_DAQ;

else if (!strcmp(argv[1],"fanon"))
	cmdpk.cmd=SYSCON_CMD_START_FANS;

else if (!strcmp(argv[1],"fanoff"))
	cmdpk.cmd=SYSCON_CMD_STOP_FANS;

else if (!strcmp(argv[1],"startacq"))
	cmdpk.cmd=SYSCON_CMD_START_SAMPLE_CLK;

else if (!strcmp(argv[1],"stopacq"))
	cmdpk.cmd=SYSCON_CMD_STOP_SAMPLE_CLK;

else if (!strcmp(argv[1],"setpgc"))
	{
		cmdpk.cmd=SYSCON_CMD_SET_PGC_VAL;
		param1=atoi(argv[2]);
	}

else if (!strcmp(argv[1],"gettemp"))
	cmdpk.cmd=SYSCON_CMD_GET_TEMP_VAL;

else if (!strcmp(argv[1],"fnt1on"))
	cmdpk.cmd=SYSCON_CMD_TURN_ON_FNT1;

else if (!strcmp(argv[1],"fnt2on"))
	cmdpk.cmd=SYSCON_CMD_TURN_ON_FNT2;

else if (!strcmp(argv[1],"fnt3on"))
	cmdpk.cmd=SYSCON_CMD_TURN_ON_FNT3;

else if (!strcmp(argv[1],"fnt4on"))
	cmdpk.cmd=SYSCON_CMD_TURN_ON_FNT4;

else if (!strcmp(argv[1],"fntoff"))
	cmdpk.cmd=SYSCON_CMD_TURN_OFF_FNT;

else if (!strcmp(argv[1],"getleak"))
	cmdpk.cmd=SYSCON_CMD_LEAK_DETECT;


else
	{	/* Help Messages*/	
		printf("\nInvalid Command..");
		printf("\n===========Command Help============");
		printf("\n**To Turn on DAM\t-> damon");
		printf("\n**To Turn Off DAM\t-> damoff");
		printf("\nTo Turn on Front End\t-> fnt1on");
		printf("\nTo Turn on Front End\t-> fnt2on");
		printf("\nTo Turn on Front End\t-> fnt3on");
		printf("\nTo Turn on Front End\t-> fnt4on");
		printf("\nTo Turn Off Front End\t-> fntoff");
		printf("\nTo start Aquisition\t-> startacq");
		printf("\nTo stop Aquisition\t-> stopacq");
		printf("\n**To Turn on system cooling fans\t-> fanon");
		printf("\n**To Turn off system cooling fans\t-> fanoff");
		printf("\nTo set Gain Value\t-> setpgc (0-7)");
		printf("\nTo get internal case temperature\t-> gettemp");
		printf("\nTo get Leak Detector output\t-> getleak");
		printf("\n=========Stay Tuned!!!=============\n");
		printf("\n** - (Disabled)\n\n");
		exit(0);
	}

   
  param2=param3=0;
  
  cmdpk.param1=param1;
  cmdpk.param2=param2;
  cmdpk.param3=param3;

//Create the socket
  struct sockaddr_in so_addr,so2_addr,si_addr;
  int s1,len;
  
  s1 = socket(AF_INET, SOCK_DGRAM,IPPROTO_UDP);
  if (-1==s1) {
    fprintf(stderr,"Error in creating socket\n");
    exit(1);
  }
  memset((char *)&si_addr,0,sizeof(si_addr));
  si_addr.sin_family=AF_INET;
  si_addr.sin_port=htons(8055);
  si_addr.sin_addr.s_addr=htons(INADDR_ANY);

 memset((char *)&so_addr,0,sizeof(so_addr));
  so_addr.sin_family=AF_INET;
  so_addr.sin_port=htons(8055);
 if (0==inet_aton(ip,&so_addr.sin_addr)){
    fprintf(stderr,"Error in inet_aton for ip address %s\n",ip);
    exit(1);
  }
 
  if (-1==bind(s1,(const struct sockaddr *)&si_addr,sizeof(si_addr))){
    fprintf(stderr,"Error in bind for ip address %s\n",ip);
    exit(1);
  }
 

    sendto(s1,(char *)&cmdpk,sizeof(cmdpk),0,(const struct sockaddr *)&so_addr,sizeof(so_addr)); // Send to syscon
	//printf("Command Sent\n");
    recvfrom(s1,(char *)&respk,sizeof(respk),0,(struct sockaddr *)&si_addr,(socklen_t *)&len); //Receive from syscon

switch(respk.cmd){ /*Identify the Response*/
case SYSCON_RES_TURN_ON_DAQ:
	printf("\nDAM system is ON\n");
	break;
case SYSCON_RES_TURN_OFF_DAQ:
	printf("\nDAM system is OFF\n");
	break;
case SYSCON_RES_TURN_ON_FNT1:
	printf("\nFront End system 1 is ON\n");
	break;
case SYSCON_RES_TURN_ON_FNT2:
	printf("\nFront End system 2 is ON\n");
	break;
case SYSCON_RES_TURN_ON_FNT3:
	printf("\nFront End system 3 is ON\n");
	break;
case SYSCON_RES_TURN_ON_FNT4:
	printf("\nFront End system 4 is ON\n");
	break;
case SYSCON_RES_TURN_OFF_FNT:
	printf("\nFront End system is OFF\n");
	break;
case SYSCON_RES_START_FANS:
	printf("\nSystem Cooling ON\n");
	break;
case SYSCON_RES_STOP_FANS:
	printf("\nSystem Cooling OFF\n");
	break;
case SYSCON_RES_START_SAMPLE_CLK:
	printf("\nData Acquisition Clock STARTED\n");
	break;
case SYSCON_RES_STOP_SAMPLE_CLK:
	printf("\nData Acquisition Clock STOPPED\n");
	break;
case SYSCON_RES_SET_PGC_VAL:
	printf("\nPGC Set Value = %d\n",respk.value1);
	break;
case SYSCON_RES_GET_TEMP_VAL:
	temp = 0.5*(float)respk.value1;
	printf("\nANI System Temperature:");
	printf("\tSensor 1 = %2.1f deg",temp);
	temp = 0.5*(float)respk.value2;
	printf("\tSensor 2 = %2.1f deg\n",temp);
	/*temp = 0.5*(float)respk.value3;
	printf("\t%2.1f deg",temp);
	temp = 0.5*(float)respk.value4;
	printf("\t%2.1f deg\n",temp);*/
	break;
case SYSCON_RES_LEAK_DETECT:
	leak = respk.value1;
	printf("\nANI System Leak Status:");
	if(!leak)
	printf("\tLEAK DETECTED!!\n");
	else printf("\tNO leak so far...\n");
	break;
case SYSCON_RES_WRONG_CMD:
	printf("\nWrong Command = %x\n",respk.value1);
	break;

case SYSCON_RES_CMD_NOT_SUP:
	printf("\nCommand Removed\n");
	break;
default:
	printf("\nCommand Unsuccessful \n");	
}
	    
return 0;
}
