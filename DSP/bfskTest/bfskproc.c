/*!
 * BFSK-FH Modulation and Demodulation  Module
 *
 * @file    bfskproc.c
 * @author  Anshu
 *
 */

#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "dsp.h"
#include "bfskproc.h"
#include "schemeproc.h"
#include "dspdebug.h"
#include "sync.h"

/*################################################################################*/
/*################################################################################*/

/* Constants And Hopping Frequencies tables */
#define PI              3.141592654
#define Fs              18000    //Sampling frequency of the baseband signal
#define Ts              0.00005555 //Time duration of each sample in seconds (1/Fs)
#define ARL_OPS_HOP_FREQ 250
#define BITS_PER_SYMBOL 5
#define JANUS_HOP_FREQ 250

/*############## WHOI SPECIFIC TX AND RX FREQUESNCIES AND HOPPING SEQUENCES ##################*/
/* Hopping Frequencies for Tx*/
static int hopFreqBB7[14]= {-2080,-1760,-1440,-1120,-800,-480,-160,160,480,800,1120,1440,1760,2080};
static int hopFreqBB13[26] = {-2000,-1840,-1680,-1520,-1360,-1200,-1040,-880,-720,-560,-400,-240,-80,80,240,400,560,720,880,1040,1200,1360,1520,1680,1840,2000};

/* Hopping Frequencies for Rx*/
static int hopFreqBBRX7[14]= {15920,16240,16560,16880,17200,17520,17840,160,480,800,1120,1440,1760,2080};
static int hopFreqBBRX13[26] = {16000,16160,16320,16480,16640,16800,16960,17120,17280,17440,17600,17760,17920,80,240,400,560,720,880,1040,1200,1360,1520,1680,1840,2000};


/* Hopping sequences for 7 hops*/
static int hopSeq7[6][7] = {
        {0,1,2,3,4,5,6},
        {0,2,4,6,1,3,5},
        {0,3,6,2,5,1,4},
        {0,4,1,5,2,6,3},
        {0,5,3,1,6,4,2},
        {0,6,5,4,3,2,1}
    };

/* Hopping sequences for 13 hops*/
static int hopSeq13[12][13]= {
        {0,1,2,3,4,5,6,7,8,9,10,11,12},
        {0,2,4,6,8,10,12,1,3,5,7,9,11},
        {0,3,6,9,12,2,5,8,11,1,4,7,10},
        {0,4,8,12,3,7,11,2,6,10,1,5,9},
        {0,5,10,2,7,12,4,9,1,6,11,3,8},
        {0,6,12,5,11,4,10,3,9,2,8,1,7},
        {0,7,1,8,2,9,3,10,4,11,5,12,6},
        {0,8,3,11,6,1,9,4,12,7,2,10,5},
        {0,9,5,1,10,6,2,11,7,3,12,8,4},
        {0,10,7,4,1,11,8,5,2,12,9,6,3},
        {0,11,9,7,5,3,1,12,10,8,6,4,2},
        {0,12,11,10,9,8,7,6,5,4,3,2,1}
    };

/*################################################################################*/


/*############## ARL SPECIFIC TX AND RX FREQUESNCIES AND HOPPING SEQUENCES ##################*/

/* Hopping Frequencies for Tx*/
static int hopFreqBB5[10] = {3750,4000,4250,4500,4750,5000,5250,5500,5750,6000};

//Band A Rx Freqs
static int hopFreqBBRX_Band_A[10]= {11750,12000,12250,12500,12750,13000,13250,13500,13750,14000};
//Band B Rx Feqs
static int hopFreqBBRX_Band_B[10]= {14250,14500,14750,15000,15250,15500,15750,16000,16250,16500};
//Band C Rx Freqs
static int hopFreqBBRX_Band_C[10]= {16750,17000,17250,17500,17750,0,250,500,750,1000};
//Band D Rx Freqs
static int hopFreqBBRX_Band_D[10]= {1250,1500,1750,2000,2250,2500,2750,3000,3250,3500};
//Band E Rx Freqs
static int hopFreqBBRX_Band_E[10]= {3750,4000,4250,4500,4750,5000,5250,5500,5750,6000};


/* Hopping Sequences for 5 hops */
static int hopSeq5[4][5] = {
        {0,1,2,3,4},
        {0,1,2,3,4},
        {0,1,2,3,4},
        {0,1,2,3,4}
    };

/*################################################################################*/


/*################################################################################*/
/*################################################################################*/

/* Working variables */

static paramSet params;              //variable to store the current Tx parameters
static int *curHopSeq;               //variable to store the current hopping order
static int *hopFreqBB;               //variable to store the baseband hopping frequencies
static int *curSyncHopSeq;           //variable to store the current Rx parameters
static int *hopFreqBBRX;

/* Prototypes */
static int BFSKProc_setSchemeParam(uint8_t scheme, uint32_t param, int value);
static en_dspRetType BFSKProc_getDefaultParams(int *BFSKConfig);
static uint32_t BFSKProc_processTx(float* databuf, BufferPtr_t sigbuf, uint32_t bits, uint8_t scheme);
static void BFSKProc_processRx(BufferPtr_t sigbuf, float* databuf, uint32_t bits, uint8_t scheme);
static int BFSKProc_computeSignalLength(uint32_t bits, uint8_t scheme);
static en_dspRetType BFSKProc_validationCheck(uint8_t scheme);
static void BFSKProc_loadParams(uint8_t scheme);
static float goertzel(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, int* modData);
void genSigSamplesWHOI (int sigLen, complex_float *comSig,int countHop,int loops,float inBit,int nextStart);
void genSigSamplesARL (int sigLen, complex_float *comSig,int countHop,int loops,float inBit,int band);

/*################################################################################*/
/*################################################################################*/

/*!Function to generate the modulated complex signal for WHOI compatible modulation scheme*/

void genSigSamplesWHOI (int sigLen, complex_float *comSig,int countHop,int loops,float inBit,int nextStart) {
    float sampleStep = 0;
    int curHopNum,curBitFreq,i;

    float curVal=0;

    curHopNum =   *(curHopSeq+countHop);
    if (inBit==-1.0)
        curBitFreq = *(hopFreqBB+2*curHopNum+1);
    else
        curBitFreq = *(hopFreqBB+2*curHopNum);

    for(i=0; i<sigLen; i++) {
        curVal=2*PI*sampleStep*(curBitFreq);

        comSig[nextStart+sigLen*loops+i].re=cosf(curVal);
        comSig[nextStart+sigLen*loops+i].im=sinf(curVal);
        sampleStep+=Ts;
        }

    }
/*################################################################################*/
/*################################################################################*/

/*!Function to generate the modulated complex signal for ARL specific modulation scheme*/

void genSigSamplesARL (int sigLen, complex_float *comSig,int countHop,int loops,float inBit,int band) {
    float sampleStep = 0;
    int curHopNum,curBitFreq,i;

    float curVal=0;

    curHopNum =   *(curHopSeq+countHop);
    if (inBit ==-1.0)
        curBitFreq = *(hopFreqBB+2*curHopNum+1);
    else
        curBitFreq = *(hopFreqBB+2*curHopNum);

    switch (band) {
        case 1:
            curBitFreq-=10000;
            break;
        case 2:
            curBitFreq -=7500;
            break;
        case 3:
            curBitFreq -=5000;
            break;
        case 4:
            curBitFreq -=2500;
            break;
        case 5:
            curBitFreq=curBitFreq;
            break;
        }

    if (band==1) {
        for(i=0; i<sigLen; i++) {
            curVal=2*PI*sampleStep*(curBitFreq);
            comSig[i].re=cosf(curVal);
            comSig[i].im=sinf(curVal);
            sampleStep+=Ts;
            }
        }
    else {
        for(i=0; i<sigLen; i++) {
            curVal=2*PI*sampleStep*(curBitFreq);
            comSig[i].re+=cosf(curVal);
            comSig[i].im+=sinf(curVal);
            sampleStep+=Ts;
            }
        }
    }
/*################################################################################*/
/*################################################################################*/

/*! Goertzel Algorithm Implementation*/

float goertzel(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, int* modData) {
    int	k,i;
    float	floatnumSamples;
    float	A,sine,cosine,B,result;
    float s0re,s0im,s1re,s1im,s2re,s2im,yre,yim;

    floatnumSamples = (float) numSamples;
    k = (int) (0.5 + ((floatnumSamples * TARGET_FREQUENCY) / SAMPLING_RATE));
    A = (2.0 * 3.1416 * k) / floatnumSamples;
    sine = sin(A);
    cosine = cos(A);
    B = 2.0 * cosine;

    s0re=0;
    s0im=0;
    s1re=0;
    s1im=0;
    s2re=0;
    s2im=0;
    result=0;

    for(i=0; i<numSamples; i++) {
        s0re = modData[2*i] + B*s1re - s2re;
        s0im = modData[2*i+1] + B*s1im - s2im;

        s2re = s1re;
        s2im = s1im;

        s1re = s0re;
        s1im = s0im;
        }

    s0re = B*s1re - s2re;
    s0im = B*s1im - s2im;

    yre = s0re -s1re*cosine - s1im*sine;
    yim = s0im + s1re*sine - s1im*cosine;

    result = sqrtf(yre*yre + yim*yim);
    return result;
    }

/*################################################################################*/
/*################################################################################*/
/*! Load up all the Tx and Rx parameters */

void BFSKProc_loadParams(uint8_t scheme) {
    int symbRate = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
    int hopSeq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ];
    int hopSeqSync = 0;

    params.symbDur= floorf(((float)1/symbRate)*100000)/100000;
    switch(symbRate) {
            /*! WHOI Compatible sonfigurations */
        case 80 :
            params.hopFreq=160;
            params.numHops=13;
            params.syncBits=26;
            hopFreqBB= &hopFreqBB13[0];
            curHopSeq = &hopSeq13[hopSeq][0] ;
            hopSeqSync = (hopSeq + 6)%12;
            curSyncHopSeq = &hopSeq13[hopSeqSync][0];
            hopFreqBBRX = &hopFreqBBRX13[0];
            break;
        case 160 :
            params.hopFreq=320;
            params.numHops=7;
            params.syncBits=21;
            hopFreqBB= &hopFreqBB7[0];
            curHopSeq = &hopSeq7[hopSeq][0] ;
            hopSeqSync = (hopSeq + 3)%6;
            curSyncHopSeq = &hopSeq7[hopSeqSync][0];
            hopFreqBBRX = &hopFreqBBRX7[0];
            break;
            /*********************************************/

            /*! ARL Specific sonfiguration */
        case 250 :
            params.hopFreq=ARL_OPS_HOP_FREQ;
            params.numHops=5;
            params.syncBits=0;
            hopFreqBB= &hopFreqBB5[0];
            curHopSeq = &hopSeq5[hopSeq][0] ;
            hopSeqSync = 0;
            curSyncHopSeq = 0;
            hopFreqBBRX = &hopFreqBBRX_Band_A[0];
            break;
            /*********************************************/
        }

    }

/*################################################################################*/
/*################################################################################*/

/* Default BFSK configuration parameters */
static int defaultBFSKConfig[MAX_BFSK_PARAMS];

/*################################################################################*/
/*################################################################################*/

/*! Initialize modulation processor */
void BFSKProc_init(void) {
    ModProcessor bfskProcFuncs;

    memset(defaultBFSKConfig, 0, (sizeof(int) * MAX_BFSK_PARAMS));

    /*Defalut values for all Tx and Rx parameters*/
    defaultBFSKConfig[BFSK_PARAM_SYMB_RATE]  = 160;
    defaultBFSKConfig[BFSK_PARAM_HOP_SEQ]    = 0;
    defaultBFSKConfig[BFSK_SYNC_BITS_SEQ]    = 0;
    defaultBFSKConfig[BFSK_OP_MODE]    = WHOI_OP_MODE;

    /*Load default values for the Tx and Rx params based on the dealut scheme*/
    params.hopFreq=320;
    params.numHops=7;
    params.syncBits=21;
    params.symbDur=floorf(((float)1/160)*100000)/100000;;
    hopFreqBB= &hopFreqBB7[0];
    curHopSeq = &hopSeq7[0][0] ;
    curSyncHopSeq = &hopSeq7[3][0];
    hopFreqBBRX = &hopFreqBBRX7[0];



    /* Filling the ModProcessor structure*/
    bfskProcFuncs.noOfParams          = MAX_BFSK_PARAMS;
    bfskProcFuncs.getDefaultParams    = BFSKProc_getDefaultParams;
    bfskProcFuncs.modSet              = BFSKProc_setSchemeParam;
    bfskProcFuncs.processTx           = BFSKProc_processTx;
    bfskProcFuncs.processRx           = BFSKProc_processRx;
    bfskProcFuncs.validationCheck     = BFSKProc_validationCheck;
    bfskProcFuncs.cSL                 = BFSKProc_computeSignalLength;

    /* Register modulation specific process functions */
    SchemeProc_registerModulationType(MOD_BFSK, bfskProcFuncs);
    }

/*################################################################################*/
/*################################################################################*/

/*! Get default params set */
en_dspRetType BFSKProc_getDefaultParams(int *config) {
    memcpy(config, defaultBFSKConfig, (sizeof(int) * MAX_BFSK_PARAMS));
    return DSP_SUCCESS;
    }

/*################################################################################*/
/*################################################################################*/


/*! Setting up the scheme parameters */

int BFSKProc_setSchemeParam(uint8_t scheme, uint32_t param, int value) {
    int ret = -1;
    switch (param-MOD_DEP_PARAM_OFFSET) {
        case BFSK_PARAM_SYMB_RATE:
            if (schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE]==ARL_OP_MODE && value!= 250)
                break;
            else if (schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE]==WHOI_OP_MODE && value!= 160) {
                if (schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE]==WHOI_OP_MODE && value!= 80)
                    break;
                }
            else {
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE] = value;
                ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
                break;
                }
        case BFSK_PARAM_HOP_SEQ:
            schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ] = value;
            ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ];
            break;
        case BFSK_SYNC_BITS_SEQ:
            schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_SYNC_BITS_SEQ] = value;
            ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_SYNC_BITS_SEQ];
            break;
        case BFSK_OP_MODE:
            schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE] = value;
            ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE];
            if (value==ARL_OP_MODE) {
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE] = 250;
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ] = 0;
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_SYNC_BITS_SEQ] = 0;
                }
            else if (value==WHOI_OP_MODE) {
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE] = 160;
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ] = 0;
                schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_SYNC_BITS_SEQ] = 0;
                }
            break;
        }

    BFSKProc_loadParams(scheme);
    return ret;
    }

/*################################################################################*/
/*################################################################################*/

/*! Compute Signal Length */
int BFSKProc_computeSignalLength(uint32_t bits, uint8_t scheme) {
    int bitsPerBlk,symbPerSec,sigLen,synchroBits,lenPerBit,numBits,opMode;
    float bitDur;
    if (bits <= 0) return 0;

    symbPerSec=schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
    opMode = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE];

    bitDur = floorf(((float)1/symbPerSec)*100000)/100000;
    switch(symbPerSec) {
        case 80 : // WHOI 80-sbs
            synchroBits=26;
            break;
        case 160 :// WHOI 160-sbs
            synchroBits=21;
            break;
        case 250 :// ARL
            synchroBits=0;
            break;
        }


    if (bitDur==0.0) {
        return DSP_FAILURE;
        }
    else {

        numBits = bits;

        //CHECK IF THE NUMBER OF BITS IS A MULTIPLE OF BITS PER SYMBOL, ELSE ADD APPROPRIATE PADDING
        if(opMode==ARL_OP_MODE) {
            int blks = bits%BITS_PER_SYMBOL;
            if (blks) {
                numBits = bits + (BITS_PER_SYMBOL-blks);
                }
            bitsPerBlk = (numBits + synchroBits)/BITS_PER_SYMBOL;
            }
        else
            bitsPerBlk = (numBits + synchroBits);

        lenPerBit=bitDur*Fs;
        sigLen=2*bitsPerBlk*lenPerBit;
        return sigLen;
        }
    }


/*################################################################################*/
/*################################################################################*/

/*! Check if current settings are valid */
en_dspRetType BFSKProc_validationCheck(uint8_t scheme) {

    int symbRate = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
    int hopSeq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_HOP_SEQ];
    int opMode = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE];

    if (opMode!=ARL_OP_MODE && opMode!= WHOI_OP_MODE && opMode!=JANUS_OP_MODE)
        return DSP_FAILURE;

    if (opMode== WHOI_OP_MODE) {
        if (symbRate!=160)
            if (symbRate !=80)
                return DSP_FAILURE;

        if (symbRate==160 ) {
            if(params.hopFreq!=320 || params.numHops!=7 || params.syncBits!=21)
                return DSP_FAILURE;
            }
        if (symbRate==80) {
            if(params.hopFreq!=160 || params.numHops!=13 || params.syncBits!=26)
                return DSP_FAILURE;
            }
        }



    if (opMode== ARL_OP_MODE) {
        if (symbRate!=250)
            return DSP_FAILURE;

        if(params.hopFreq!=ARL_OPS_HOP_FREQ)
            return DSP_FAILURE;

        if(params.numHops!=5)
            return DSP_FAILURE;

        if(params.syncBits!=0)
            return DSP_FAILURE;
        }

    if (params.numHops!=7) {
        if (params.numHops!=13) {
            if (params.numHops!=5){
                if (params.numHops != /*fill in the num of hops here from JANUS specs*/)
                return DSP_FAILURE;
                }
            }

        }


    if (params.numHops==7 && hopSeq>6) return DSP_FAILURE;
    if (params.numHops==13 && hopSeq>12) return DSP_FAILURE;
    if (params.numHops==5 && hopSeq>4) return DSP_FAILURE;
    
    return DSP_SUCCESS;
    }

/*################################################################################*/
/*################################################################################*/

/*! TX MODULATION PROCESS */
uint32_t BFSKProc_processTx(float* databuf, BufferPtr_t sigbuf, uint32_t bits, uint8_t scheme) {
    int bitsPerBlk,sigLen,countHop,nextStart,baudRate,countBits,blks,numBits;
    float *inSigFloat= databuf;
    int *out = sigbuf;
    int *isig = out;
    uint32_t i,j,k;
    float max;
    complex_float *comSig;
    float *fsig;

    float *syncBitsPtr;

    isig=out;
    fsig = (float*)isig;
    comSig = (complex_float*)isig; //complex_float to save the modulated data

    baudRate=schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
    int syncSeq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_SYNC_BITS_SEQ];
    int opMode = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE];

    sigLen=params.symbDur*Fs;//Number of samples to be taken per bit symbol duration, same as number of loops for generating the complex signals for each bit
    countHop=0;
    nextStart=0;
    countBits = 0;
    numBits = bits;

    if (bits==0)
        return 1;
    else {

        bitsPerBlk = bits + params.syncBits;


        /*! WHOI COMPATIBLE MODULATION PROCESS*/

        if (opMode == WHOI_OP_MODE) {
            for(k=0; k<(bits); k+=2) {
                if(countHop==params.numHops) countHop=0;

                //GENERATE COMPLEX SIGNAL FOR FIRST BIT
                genSigSamplesWHOI (sigLen,comSig,countHop,countBits,inSigFloat[countBits],nextStart);
                countHop+=1;
                countBits+=1;

                if(countHop==params.numHops) countHop=0;

                //GENERATE COMPLEX SIGNAL FOR SECOND BIT
                genSigSamplesWHOI (sigLen,comSig,countHop,countBits,inSigFloat[countBits],nextStart);
                countHop+=1;
                countBits+=1;

                if (baudRate==160 && (countBits%2)==0 && countBits!=0) {
                    //increment the pointer by 2 and append 2 zeroes ot comSig array
                    comSig[nextStart+sigLen*countBits].re=cosf(0);
                    comSig[nextStart+sigLen*countBits].im=sinf(0);
                    nextStart+=1;
                    }


                }//END OF LOOPS FOR DATA BITS


            nextStart=sigLen*bits;

            //FOR SUFFIXING THE SYNCHRO BITS (21 or 26 BITS)

            countBits =0;

            switch(params.syncBits) {
                case 21 :
                    syncBitsPtr = &sync7[syncSeq][0];
                    break;
                case 26 :
                    syncBitsPtr = &sync13[syncSeq][0];
                    break;
                }


            countHop=0;
            for(j=0; j<(params.syncBits); j+=2) { //LOOP FOR SYNC BITS
                if(countHop==params.numHops) countHop=0;

                //GENERATE COMPLEX SIGNAL FOR EACH BIT
                genSigSamplesWHOI (sigLen,comSig,countHop,countBits,*(syncBitsPtr+countBits),nextStart);
                countHop+=1;
                countBits+=1;

                if(countHop==params.numHops) countHop=0;

                //GENERATE COMPLEX SIGNAL FOR EACH BIT
                genSigSamplesWHOI (sigLen,comSig,countHop,countBits,*(syncBitsPtr+countBits),nextStart);
                countHop+=1;
                countBits+=1;
                }//END OF LOOP FOR SYNC BITS

            if (baudRate==160) {
                genSigSamplesWHOI (sigLen,comSig,countHop,countBits,*(syncBitsPtr+countBits),nextStart);
                }

            }

        /*################################################################################*/

        /*! ARL SPECIFIC MODULATION PROCESS*/

        if (opMode == ARL_OP_MODE) {
            //CHECK IF THE NUMBER OF BITS IS A MULTIPLE OF 5, ELSE ADD APPROPRIATE PADDING
            blks = bits%BITS_PER_SYMBOL;
            if (blks) {
                bitsPerBlk = (bitsPerBlk + (BITS_PER_SYMBOL-blks));
                }

            bitsPerBlk/=BITS_PER_SYMBOL;

            numBits +=(BITS_PER_SYMBOL-blks);

            while (countBits<numBits) {
                if(countHop==params.numHops) countHop=0;

                int j;

                for(j=1; j<BITS_PER_SYMBOL+1; j++) {
                    genSigSamplesARL(sigLen,&comSig[nextStart],countHop,countBits,inSigFloat[countBits],j);
                    countBits+=1;
                    }
                countHop+=1;
                nextStart = sigLen+ nextStart;
                }
            }
        }
    //Sacle signal to max value of 32767
    max = 0;
    for (i = 0; i < 2*bitsPerBlk*sigLen; i++)
        if (fabs(fsig[i]) > max) max = fabs(fsig[i]);
    for (i = 0; i < 2*bitsPerBlk*sigLen; i++) {
        float x = 32767*fsig[i]/max;
        isig[i] = (int)x;
        }


    return (2*bitsPerBlk*sigLen);

    }

/*! END OF TX FUNCTION*/

/*################################################################################*/
/*################################################################################*/

/*! Process RX */
void BFSKProc_processRx(BufferPtr_t sigbuf, float* databuf, uint32_t bits, uint8_t scheme) {
    int sigLen,countHop,curZeroFreq,curOneFreq,curBitFreq,curHopNum,countBits,baudRate,nextStart;
    float *outData= databuf;
    uint32_t i;
    float powerZero,powerOne;
    int *curSigBlk;
    int* in = sigbuf;
    int* isig;
    float* fsig;

    isig = (int *)in;
    fsig = (float*)isig;

    sigLen=params.symbDur*Fs;//Number of samples to be taken per bit symbol duration, same as number of loops for generating the complex signals for each bit

    baudRate=schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_PARAM_SYMB_RATE];
    int opMode = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+BFSK_OP_MODE];

    /*Initialize all counters*/
    countHop=0;
    countBits = 0;
    nextStart = 0;

    /*! WHOI COMPATIBLE DEMODULATION PROCESS*/

    if (opMode == WHOI_OP_MODE) {
        for(i=0; i<(bits); i+=2) { //Loop for number of data bits, ignoring all the synchronization bits
            if(countHop==params.numHops) countHop=0;

            powerZero=0;
            powerOne=0;

            curSigBlk = in + 2*sigLen*countBits + nextStart;

            curHopNum = *(curHopSeq+countHop);
            curBitFreq =2*curHopNum;

            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX+curBitFreq);      //current expected frequency of 0 bit
            curOneFreq=*(hopFreqBBRX+curBitFreq+1);    //current expected frequency of 1 bit
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency
            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////


            countHop+=1;
            countBits+=1;

            //////////////////////////////////////////////////////
            //2nd bit demod

            if(countHop==params.numHops) countHop=0;

            powerZero=0;
            powerOne=0;

            curSigBlk = in + 2*sigLen*countBits+nextStart;

            curHopNum = *(curHopSeq+countHop);
            curBitFreq =2*curHopNum;

            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX+curBitFreq);      //current expected frequency of 0 bit
            curOneFreq=*(hopFreqBBRX+curBitFreq+1);    //current expected frequency of 1 bit
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency
            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countHop+=1;
            countBits+=1;

            ///////////////////////////////////////////////////////
            if (baudRate==160 && (countBits%2)==0 && countBits!=0) {
                //increment the pointer to input array by 2
                nextStart+=2;
                }

            }
        }
    /*################################################################################*/

    /*! ARL SPECIFIC DE-MODULATION PROCESS*/

    if (opMode == ARL_OP_MODE) {
        int nextStart=0;
        while(countBits < bits) {
            if(countHop==params.numHops) countHop=0;

            powerZero=0;
            powerOne=0;

            curSigBlk = in + nextStart;

            curHopNum = *(curHopSeq+countHop);
            curBitFreq =2*curHopNum;

            /*BAND A*/
            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX_Band_A+curBitFreq);
            curOneFreq=*(hopFreqBBRX_Band_A+curBitFreq+1);
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency
            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countBits+=1;
            if (countBits == bits) break;

            /*BAND B*/
            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX_Band_B+curBitFreq);
            curOneFreq=*(hopFreqBBRX_Band_B+curBitFreq+1);
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency
            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countBits+=1;
            if (countBits == bits) break;

            /*BAND C*/
            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX_Band_C+curBitFreq);
            curOneFreq=*(hopFreqBBRX_Band_C+curBitFreq+1);
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency
            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countBits+=1;
            if (countBits == bits) break;

            /*BAND D*/
            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX_Band_D+curBitFreq);
            curOneFreq=*(hopFreqBBRX_Band_D+curBitFreq+1);
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency

            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countBits+=1;
            if (countBits == bits) break;

            /*BAND E*/
            /////////////////////////////////////////////////////////////////////////////////////////
            curZeroFreq=*(hopFreqBBRX_Band_E+curBitFreq);
            curOneFreq=*(hopFreqBBRX_Band_E+curBitFreq+1);
            powerZero=goertzel(sigLen,curZeroFreq,Fs,curSigBlk);  //Power at 0's frequency
            powerOne=goertzel(sigLen,curOneFreq,Fs,curSigBlk);  //Power at 1's frequency

            if(powerZero>powerOne) {
                outData[countBits]=1.0;
                }
            else {
                outData[countBits]=-1.0;
                }
            /////////////////////////////////////////////////////////////////////////////////////////

            countBits+=1;
            if (countBits == bits) break;

            countHop+=1;
            nextStart = nextStart + 2*sigLen;
            }

        }

    /*################################################################################*/
    }/*! END OF RX FUNCTION*/

/*################################################################################*/
/*################################################################################*/
