#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <regex.h>
#include <fcntl.h>
#include <errno.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <unistd.h>
#include <regex.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <time.h>

#define MAX_LINE_LENGTH 255
struct cmd_packet {
  unsigned int cmd;
  unsigned int param1;
  unsigned int param2;
  unsigned int param3;
};

struct res_packet2 {
  unsigned int cmd;
  unsigned int value1;
  unsigned int value2;
  unsigned int value3;
};

struct res_packet {
  unsigned int cmd;
  unsigned int value1;
  unsigned int value2;
  unsigned int value3;
  unsigned int value4;
  unsigned int value5;
  unsigned int value6;
};

char g_buffer[255];
int getseconds() ;

#define  CMD_GET_TX_TS 1
#define  CMD_GET_RX_TS 2
#define  CMD_SET_DELAY 3
#define  CMD_GET_SEND_TS 4
#define  RES_WRONG_CMD 5
int main(int argc, char **argv){
  int c;
  int command_flag, ip_flag,ip2_flag,param_flag;
  char ip[MAX_LINE_LENGTH] ,ip2[MAX_LINE_LENGTH];
  unsigned int  command,param1,param2,param3;
  struct timeval tv_in,tv_out;
  int repeat,delay;
  param1=param2=param3=0;
  command_flag=ip_flag=ip2_flag=param_flag=0;
  repeat=1;
  delay=0;
  while((c=getopt(argc,argv,"p:i:c:f:s:t:r:d:?"))!=-1){
    switch(c){
    case 'i':
      strncpy(ip,optarg,MAX_LINE_LENGTH)[MAX_LINE_LENGTH-1]=0;
      ip_flag=1;
      break;
    case 'p':
      strncpy(ip2,optarg,MAX_LINE_LENGTH)[MAX_LINE_LENGTH-1]=0;
      ip2_flag=1;
      break;
    case 'c':
      command = atoi(optarg);
      command_flag=1;
      break;
    case 'f':
      param1 = atoi(optarg);
      param_flag=1;
      break;
    case 's':
      param2 = atoi(optarg);
      param_flag=1;
      break;
    case 't':
      param3 = atoi(optarg);
      param_flag=1;
      break;
    case 'r':
      repeat=atoi(optarg);
      break;
    case 'd':
      delay=atoi(optarg);
      break;
    case '?':
      fprintf(stderr,
	      "usage: test_timestamp_mcu -i <ip> [-r<repeat> -d<delayms>] -c <command> -f <first param> -s <sec param> -t <third param>\n");
      fprintf(stderr,"Commands are as follows\n");
      fprintf(stderr, "1 CMD_GET_TX_TS  :Gets the Time at which the packet was Transmitted by the FPGA\n");
      fprintf(stderr, "2 CMD_GET_RCV_TS :Gets the Time at which the packet was Received by Modem\n");
      fprintf(stderr, "3 CMD_SET_DELAY  :Time for which the MCU is to wait before Triggering the FPGA\n");
      fprintf(stderr, "4 CMD_GET_SEND_TS:Gets the Time at which the packet will be Transmited into water\n");
      fprintf(stderr, "5 RES_WRONG_CMD  :Wrong command notification\n");
      exit(-1);
    }
  }
  if (!(command_flag && ip_flag &&param_flag)) {
    fprintf(stderr,
	    "usage: test_timestamp_mcu -i <ip>  [-r<repeat> -d <delayms>] -c <command> -f <first param> -s <sec param> -t <third param>\n");
    exit(-1);
  }
  struct cmd_packet cmdpk;
  struct res_packet respk;
  cmdpk.cmd=command;
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
  if (1==ip2_flag) {
    memset((char *)&so2_addr,0,sizeof(so2_addr));
    so2_addr.sin_family=AF_INET;
    so2_addr.sin_port=htons(8055);
    if (0==inet_aton(ip2,&so2_addr.sin_addr)){
      fprintf(stderr,"Error in inet_aton for ip2 address %s\n",ip2);
      exit(1);
    }

  }

  if (-1==bind(s1,(const struct sockaddr *)&si_addr,sizeof(si_addr))){
    fprintf(stderr,"Error in bind for ip address %s\n",ip);
    exit(1);
  }
  fprintf(stderr,"[%u]Starting test at %s\n",getseconds(),g_buffer);

  for(int i=0;i<repeat;i++ ) {
    gettimeofday(&tv_in,0);
    sendto(s1,(char *)&cmdpk,sizeof(cmdpk),0,(const struct sockaddr *)&so_addr,sizeof(so_addr));
    recvfrom(s1,(char *)&respk,sizeof(respk),0,(struct sockaddr *)&si_addr,(socklen_t *)&len);
    gettimeofday(&tv_out,0);
    fprintf(stderr,"1 The command executed in %u sec, %u microsecondsss\n",tv_out.tv_sec -tv_in.tv_sec,
	    tv_out.tv_usec - tv_in.tv_usec);
    switch(respk.cmd) {
    case CMD_GET_TX_TS:
      fprintf(stderr,"1 [%u]The Last Packet was Transmitted in %u sec %u msec %u usec\n",
	      getseconds(),respk.value1,respk.value2,respk.value3);	
      break;
    case CMD_GET_RX_TS:
      if (1000<respk.value3) { 
	fprintf(stderr,"Opps..");
      }
      fprintf(stderr,"1 [%u]The Last Packet was Received in %u sec %u msec %u usec\n",
	      getseconds(),respk.value1,respk.value2,respk.value3);	
      fprintf(stderr,"1 [%u]More Data g_rx_clock [%u] g_tics[%u] g_counter[%u]\n",
	      getseconds(),respk.value4,respk.value5,respk.value6);	
      break;
    case CMD_SET_DELAY:
      fprintf(stderr,"1 [%u]The Delay was %u ms with %u HZ the clock value = %u\n",
	      getseconds(),respk.value1,respk.value2,respk.value3);
      break;
    case CMD_GET_SEND_TS:
      fprintf(stderr,"1 [%u]The packet will be send in %u sec %u msec %u usec\n",
	      getseconds(),respk.value1,respk.value2,respk.value3);
      break;
    case RES_WRONG_CMD:
      fprintf(stderr,"1 [%u]The packet cmd was not deciphered cmd=%u\n",
	      getseconds(),respk.value1);
      break;
    } 
   
    if (1==ip2_flag) {

      gettimeofday(&tv_in,0);
      sendto(s1,(char *)&cmdpk,sizeof(cmdpk),0,(const struct sockaddr *)&so2_addr,sizeof(so2_addr));
      recvfrom(s1,(char *)&respk,sizeof(respk),0,(struct sockaddr *)&si_addr,(socklen_t *)&len);
      gettimeofday(&tv_out,0);
      fprintf(stderr,"2 The command2 executed in %u sec, %u microsecondsss\n",tv_out.tv_sec -tv_in.tv_sec,
	      tv_out.tv_usec - tv_in.tv_usec);
      switch(respk.cmd) {
      case CMD_GET_TX_TS:
	fprintf(stderr,"2 [%u]The Last Packet was Transmitted in %u sec %u msec %u usec\n",
		getseconds(),respk.value1,respk.value2,respk.value3);	
	break;
      case CMD_GET_RX_TS:
	if (1000<respk.value3) { 
	  fprintf(stderr,"Opps..");
	}
	fprintf(stderr,"2 [%u]The Last Packet was Received in %u sec %u msec %u usec\n",
		getseconds(),respk.value1,respk.value2,respk.value3);	
      fprintf(stderr,"2 [%u]More Data g_rx_clock [%u] g_tics[%u] g_counter[%u]\n",
	      getseconds(),respk.value4,respk.value5,respk.value6);	
	break;
      case CMD_SET_DELAY:
	fprintf(stderr,"2 [%u]The Delay was %u ms with %u HZ the clock value = %u\n",
		getseconds(),respk.value1,respk.value2,respk.value3);
	break;
      case CMD_GET_SEND_TS:
	fprintf(stderr,"2 [%u]The packet will be send in %u sec %u msec %u usec\n",
		getseconds(),respk.value1,respk.value2,respk.value3);
	break;
      case RES_WRONG_CMD:
	fprintf(stderr,"2 [%u]The packet cmd was not deciphered cmd=%u\n",
		getseconds(),respk.value1);
	break;
      } 
    }
    if (delay) 
      usleep(delay*1000);
  } 
  close(s1);
  exit(0);


}
int getseconds() {
  time_t t;
  struct tm *tmp;
  int val;
    
  t = time(NULL);
  tmp = localtime(&t);
  if (tmp == NULL) {
    fprintf(stderr,"ERROR in localtime\n");
    return 0;
  }
  val = (tmp->tm_year - 70)*365 ;
  val += ((tmp->tm_mon)*31);
  val += (tmp->tm_mday);
  val = val*24*3600;
  val += (tmp->tm_hour*3600);
  val += (tmp->tm_min*60);
  val += (tmp->tm_sec);
  val -= (8*3600);

  if (strftime(g_buffer,255,"%F:%H:%M:%S]", tmp) == 0) {
    fprintf(stderr,"ERROR in strftime\n");
    return 0;
  }
  return val;
}
	
