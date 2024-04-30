#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include "bfskproc.h"
#include "dsp.h"
#include "schemeproc.h"

#define DATABUF_LEN   1200
#define SIGBUF_LEN    65536
#define PKTLEN        1200

ModProcessor mod;
float data[DATABUF_LEN];
float data2[DATABUF_LEN];
int sigbuf[SIGBUF_LEN];
int schemeConfig[MAX_SCHEME_COUNT][MAX_SCHEME_PARAMS];

void dotest(char* name, int rv)
{
  if (rv == 0) printf("%32s: PASS\n",name);
  else {printf("%32s: FAIL (%d) *** ... Press key \n",name,rv);getchar();}
}

void dump(char* filename, int* data, int len)
{
  int i;
  FILE* fp = fopen(filename,"wt");
  for (i = 0; i < len; i++)
    fprintf(fp,"%d\n",data[i]);
  fclose(fp);
}

void SchemeProc_registerModulationType(en_modulationType modType, ModProcessor m)
{
  memcpy(&mod,&m,sizeof(ModProcessor));
}

int testTx(void)
{
  int i, len, xlen;
  for (i = 0; i < PKTLEN; i++)
    data[i] = 2*(rand()%2)-1;
  xlen = (*(mod.cSL))(PKTLEN,0);
  if (xlen > SIGBUF_LEN) return -1;
  len = (*(mod.processTx))(data,sigbuf,PKTLEN,0);
  if (len != xlen) {printf("CSL = %d , TX = %d\n",xlen,len);return -2;}
  dump("signal.txt",sigbuf,len);
  return 0;
}

int testRx(void)
{
  int i, err;
  (*(mod.processRx))(sigbuf,data2,PKTLEN,0);
  err = 0;
  for (i = 0; i < PKTLEN; i++) {
    if (data[i] != data2[i]){ err++;printf("%d  %f  %f\n",i,data[i],data2[i]);}

  }
  return err;
}

void setParam(int param,int value)
{
  int ret;
  ret=(*(mod.modSet))(0,param+MOD_DEP_PARAM_OFFSET,value);
  if (ret==-1)
  {
    printf("PARAM SET FAILED !!\n");
    getchar();
  }
}

int main()
{

	int i;
  BFSKProc_init();
  (*(mod.getDefaultParams))(&schemeConfig[0][MOD_DEP_PARAM_OFFSET]);

  setParam(BFSK_OP_MODE,ARL_OP_MODE);

  en_dspRetType check = (*(mod.validationCheck))(0);
  if (check==DSP_FAILURE)
  {
    printf("CHECK FAILED \n");
    getchar();
  }
  else
  {
    printf("CHECKS PASSED !!!\n");
    getchar();
  }


  for(i=0;i<100;i++)
  {
	  srand(i);
  dotest("TX",testTx());
  //getchar();
  dotest("RX",testRx());
  }
  return 0;
}
