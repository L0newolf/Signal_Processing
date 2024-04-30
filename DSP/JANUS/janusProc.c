/*!
 * JANUS Compatible Modulation and Demodulation  Module
 *
 * @file    janusProc.c
 * @author  Anshu
 *
 */

#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "dsp.h"
#include "janusProc.h"
#include "schemeproc.h"
#include "dspdebug.h"


/*################################################################################*/
/*################################################################################*/

/* Constants */
#define PI              3.141592654
#define Fs              18000    //Sampling frequency of the baseband signal
#define Ts              0.00005555 //Time duration of each sample in seconds (1/Fs)
#define JANUS_SYMBOL_RATE 140

/*################################################################################*/
/*################################################################################*/

/* Default JANUS configuration parameters */
static int defaultJANUSConfig[MAX_JANUS_PARAMS];

/*################################################################################*/
/*################################################################################*/

/*! Initialize modulation processor */
void JANUSProc_init(void) {
    ModProcessor janusProcFuncs;

    memset(defaultJANUSConfig, 0, (sizeof(int) * MAX_JANUS_PARAMS));

    /*Defalut values for all Tx and Rx parameters*/

    // ALL default parameter values for the JANUS mode go here

    /* Filling the ModProcessor structure*/
    janusProcFuncs.noOfParams          = MAX_JANUS_PARAMS;
    janusProcFuncs.getDefaultParams    = JANUSProc_getDefaultParams;
    janusProcFuncs.modSet              = JANUSProc_setSchemeParam;
    janusProcFuncs.processTx           = JANUSProc_processTx;
    janusProcFuncs.processRx           = JANUSProc_processRx;
    janusProcFuncs.validationCheck     = JANUSProc_validationCheck;
    janusProcFuncs.cSL                 = JANUSProc_computeSignalLength;

    /* Register modulation specific process functions */
    SchemeProc_registerModulationType(MOD_JANUS, janusProcFuncs);
    }

/*################################################################################*/
/*################################################################################*/

/*! Get default params set */
en_dspRetType JANUSProc_getDefaultParams(int *config) {
    memcpy(config, defaultJANUSConfig, (sizeof(int) * MAX_JANUS_PARAMS));
    return DSP_SUCCESS;
    }

/*################################################################################*/
/*################################################################################*/


/*! Setting up the scheme parameters */

int JANUSProc_setSchemeParam(uint8_t scheme, uint32_t param, int value) {
    int ret = -1;
    switch (param-MOD_DEP_PARAM_OFFSET) {

        case /* Parameter goes here */:
            schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+/* Parameter goes here */] = value;
            ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+/* Parameter goes here */];
            break;
            break;
        }
    return ret;
    }

/*################################################################################*/
/*################################################################################*/

/*! Compute Signal Length */
int BFSKProc_computeSignalLength(uint32_t bits, uint8_t scheme) {
        int sigLen;

        /* Compute the signal length in terms of the number of samples required, both real and imaginary*/

        return sigLen;
        }
    }


/*################################################################################*/
/*################################################################################*/


/*! Check if current settings are valid */
en_dspRetType BFSKProc_validationCheck(uint8_t scheme) {

    /* Check all the parameter combinations for validity here and return DSP_FAILURE  when there is an invalid parameter combination*/

    return DSP_SUCCESS;
    }

/*################################################################################*/
/*################################################################################*/

/*! TX MODULATION PROCESS */
uint32_t BFSKProc_processTx(float* databuf, BufferPtr_t sigbuf, uint32_t bits, uint8_t scheme) {

    float *inSigFloat= databuf;
    int *out = sigbuf;
    int *isig = out;
    float max;
    complex_float *comSig;
    float *fsig;


    isig=out;
    fsig = (float*)isig;
    comSig = (complex_float*)isig; //complex_float to save the modulated data

    sigLen=params.symbDur*Fs;//Number of samples to be taken per bit symbol duration, same as number of loops for generating the complex signals for each bit


    if (bits==0)
        return 1;
    else {

    /* Modulation process goes here, use inSig to read the {+1,-1} bipolar float inputs*/

    }

    //Sacle signal to max value of 32767
    max = 0;
    for (i = 0; i < 2*bitsPerBlk*sigLen; i++)
        if (fabs(fsig[i]) > max) max = fabs(fsig[i]);
    for (i = 0; i < 2*bitsPerBlk*sigLen; i++) {
        float x = 32767*fsig[i]/max;
        isig[i] = (int)x;
        }
    return (/*signal length in terms of the number of samples required, both real and imaginary*/);

    }

/*! END OF TX FUNCTION*/

/*################################################################################*/
/*################################################################################*/

/*! Process RX */
void BFSKProc_processRx(BufferPtr_t sigbuf, float* databuf, uint32_t bits, uint8_t scheme) {

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

    /* Demodulation Process goes here , save the ouput {+1.-1} bipolar bits sequences in outData array*/

    /*################################################################################*/
    }/*! END OF RX FUNCTION*/

/*################################################################################*/
/*################################################################################*/
