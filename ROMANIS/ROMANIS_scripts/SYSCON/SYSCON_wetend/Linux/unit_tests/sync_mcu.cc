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
int any_data(int fd, int sec, int usec) ;

#define  CMD_GET_TX_TS 1
#define  CMD_GET_RX_TS 2
#define  CMD_SET_DELAY 3
#define  CMD_GET_SEND_TS 4
#define  RES_WRONG_CMD 5
#define  CMD_SET_TIMESTAMP 6

int main(int argc, char **argv){
  int c;
  int ip_flag,ip2_flag;
  char ip[MAX_LINE_LENGTH] ,ip2[MAX_LINE_LENGTH];
  unsigned int  command,param1,param2,param3;
  struct timeval tv_in,tv_out;
  ip_flag=0;
  while((c=getopt(argc,argv,"i:?"))!=-1){
    switch(c){
    case 'i':
      strncpy(ip,optarg,MAX_LINE_LENGTH)[MAX_LINE_LENGTH-1]=0;
      ip_flag=1;
      break;
    case '?':
      fprintf(stderr,
	      "usage: sync_mcu -i <ip> \n");
      exit(-1);
    }
  }
  if (0==ip_flag ) {
      fprintf(stderr,
	      "usage: sync_mcu -i <ip> \n");
    exit(-1);
  }
  struct cmd_packet cmdpk;
  struct res_packet respk;
  cmdpk.cmd=CMD_SET_TIMESTAMP;

  //Create the socket
  struct sockaddr_in so_addr,si_addr;
  int s1,len,res,sync;
  
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
  fprintf(stderr,"[%u]Starting Synchronization for %s \n",getseconds(),ip);

   sync=0;
    gettimeofday(&tv_in,0);
  while(0==sync) {
    cmdpk.param1=getseconds();
    cmdpk.param2=cmdpk.param3=0;
    sendto(s1,(char *)&cmdpk,sizeof(cmdpk),0,(const struct sockaddr *)&so_addr,sizeof(so_addr));
    res=any_data(s1,0,10000);
    if (1==res) {
    	recvfrom(s1,(char *)&respk,sizeof(respk),0,(struct sockaddr *)&si_addr,(socklen_t *)&len);
	if (respk.cmd==cmdpk.cmd) {
		fprintf(stderr,"MCU synchronized\n");
		sync=1;
    	}
   	}
    }
    gettimeofday(&tv_out,0);
    fprintf(stderr,"1 The command executed in %u sec, %u microsecondsss\n",tv_out.tv_sec -tv_in.tv_sec,
	    tv_out.tv_usec - tv_in.tv_usec);
   
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
	

int any_data(int fd, int sec, int usec) {
  struct timeval timeStruct, *ptimeStruct;
  fd_set rset;
  int selRes;

  FD_ZERO(&rset);
  FD_SET(fd,&rset);

  if (-1==sec && -1==usec) {
    ptimeStruct=NULL;
  } else {
    timeStruct.tv_sec=sec;
    timeStruct.tv_usec=usec;
    ptimeStruct = &timeStruct;
  }

  selRes = select(FD_SETSIZE,&rset,NULL,NULL,ptimeStruct);
  if (selRes==-1){
    fprintf(stderr,"%s::%d::%s select failed [%s]\n",__FILE__,__LINE__,__FUNCTION__,strerror(errno));
    return -1;
  }

  if (selRes==0){
	return 0;
  }
  if (!FD_ISSET(fd,&rset)){
    fprintf(stderr,"%s::%d::%s Unknown error [%s]\n",__FILE__,__LINE__,__FUNCTION__,strerror(errno));
    return -1;
  }
  return 1;
}
