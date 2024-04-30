#ifndef _TIMESTAMP_H
#define _TIMESTAMP_H


struct timestamp_data {
  unsigned int sec;
  unsigned int msec;
  unsigned int usec;
  unsigned int lock;
  unsigned int clock;
};
int tokenize(char *ptr,char token[10][80],unsigned char delim,int max) ;

#endif //_TIMESTAMP_H

