/*!
 * MFSK Modulation and Demodulation  Module
 *
 * @file    mfskproc.c
 * @author  Anshu
 *
 */

#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "dsp.h"
#include "mfskproc.h"
#include "schemeproc.h"
#include "dspdebug.h"
#include "goertzel.h"

/*################################################################################*/
/*################################################################################*/

/* Constants */
#define PI              3.141592654
#define Fs              18000    //Sampling frequency of the baseband signal
#define Ts              0.00005555 //Time duration of each sample in seconds (1/Fs)

/*################################################################################*/
/*################################################################################*/

/* Working Variables */

unsigned int freqLower,freqUpper,samplesPerSymb,numFreqTones,tonesPerBand,maxFreqBands,numFreqTones,bitsPerSymb;
float symbolDuration;
int *freqTones;
int *freqTonesRX;


/* Function declarations */
void MFSKProc_loadParams(uint8_t scheme);
void MFSKProc_init(void);
en_dspRetType MFSKProc_getDefaultParams(int *config);
int MFSKProc_setSchemeParam(uint8_t scheme, uint32_t param, int value);
int MFSKProc_computeSignalLength(uint32_t bits, uint8_t scheme);
en_dspRetType MFSKProc_validationCheck(uint8_t scheme);
uint32_t MFSKProc_processTx(float* databuf, BufferPtr_t sigbuf, uint32_t bits, uint8_t scheme);
void MFSKProc_processRx(BufferPtr_t sigbuf, float* databuf, uint32_t bits, uint8_t scheme);

/*################################################################################*/
/*################################################################################*/

/* Load up all the Tx and Rx parameters*/

void MFSKProc_loadParams(uint8_t scheme)
{
	int bandWidth = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BANDWIDTH];
	int freqStep = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_FREQ_STEP];
	int symbolRate = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_SYMBOL_RATE];
	int bitsPerFreq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BITS_PER_FREQ];
	int numHops = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_NUM_HOPS];

	int i;


	freqLower = -bandWidth/2;
	freqUpper = bandWidth/2;

	symbolDuration  = (float)1.0/symbolRate;
	samplesPerSymb = (int)(symbolDuration*Fs);

	if(samplesPerSymb%2!=0)
		samplesPerSymb = samplesPerSymb+1;

	numFreqTones = bandWidth/freqStep;

	free(freqTones);
	freqTones = (int *)malloc(numFreqTones*sizeof(int));


	free(freqTonesRX);
	freqTonesRX = (int *)malloc(numFreqTones*sizeof(int));

	tonesPerBand = pow(2,bitsPerFreq) * numHops;

	maxFreqBands = numFreqTones/tonesPerBand;
	numFreqTones = maxFreqBands*tonesPerBand;

	bitsPerSymb = bitsPerFreq*maxFreqBands;

	freqTones[0]=freqLower;
	freqTonesRX[0] = Fs+freqLower;
	for (i=1; i<numFreqTones; i++) {
		freqTones[i] = freqTones[i-1]+freqStep;
		if(freqTones[i] < 0 )
			freqTonesRX[i] = Fs + freqTones[i];
		else
			freqTonesRX[i] = freqTones[i];
	}

    printf("Feq step used : %d  total number of tones : %d on BW : %d \n",freqStep,numFreqTones,bandWidth);
    getchar();
    printf("freq tones being used : \n");
    for(i=0;i<numFreqTones;i++)
        printf("%d\n",freqTones[i]);
    getchar();

}
/*################################################################################*/
/*################################################################################*/

/* Default MFSK configuration parameters */
static int defaultMFSKConfig[MAX_MFSK_PARAMS];

/*################################################################################*/
/*################################################################################*/


/*! Initialize modulation processor */
void MFSKProc_init(void)
{
	ModProcessor mfskProcFuncs;

	memset(defaultMFSKConfig, 0, (sizeof(int) * MAX_MFSK_PARAMS));

	/*Defalut values for all Tx and Rx parameters*/
	defaultMFSKConfig[MFSK_PARAM_BANDWIDTH]  	  = 13000;
	defaultMFSKConfig[MFSK_PARAM_FREQ_STEP]  	  = 250;
	defaultMFSKConfig[MFSK_PARAM_SYMBOL_RATE]     = 40;
	defaultMFSKConfig[MFSK_PARAM_BITS_PER_FREQ]   = 2;
	defaultMFSKConfig[MFSK_PARAM_NUM_HOPS]  	  = 1;


	/* Filling the ModProcessor structure*/
	mfskProcFuncs.noOfParams          = MAX_MFSK_PARAMS;
	mfskProcFuncs.getDefaultParams    = MFSKProc_getDefaultParams;
	mfskProcFuncs.modSet              = MFSKProc_setSchemeParam;
	mfskProcFuncs.processTx           = MFSKProc_processTx;
	mfskProcFuncs.processRx           = MFSKProc_processRx;
	mfskProcFuncs.validationCheck     = MFSKProc_validationCheck;
	mfskProcFuncs.cSL                 = MFSKProc_computeSignalLength;

	/* Register modulation specific process functions */
	SchemeProc_registerModulationType(MOD_MFSK, mfskProcFuncs);

	/* Load default parameters */

	int i;
	freqLower = -defaultMFSKConfig[MFSK_PARAM_BANDWIDTH]/2;
	freqUpper = defaultMFSKConfig[MFSK_PARAM_BANDWIDTH]/2;

	symbolDuration  = (float)1.0/defaultMFSKConfig[MFSK_PARAM_SYMBOL_RATE];
	samplesPerSymb = (int)(symbolDuration*Fs);

	if(samplesPerSymb%2!=0)
		samplesPerSymb = samplesPerSymb+1;

	numFreqTones = defaultMFSKConfig[MFSK_PARAM_BANDWIDTH]/defaultMFSKConfig[MFSK_PARAM_FREQ_STEP];

	free(freqTones);
	freqTones = (int *)malloc(numFreqTones*sizeof(int));

	tonesPerBand = pow(2,defaultMFSKConfig[MFSK_PARAM_BITS_PER_FREQ]) * defaultMFSKConfig[MFSK_PARAM_NUM_HOPS];

	maxFreqBands = numFreqTones/tonesPerBand;
	numFreqTones = maxFreqBands*tonesPerBand;

	bitsPerSymb = defaultMFSKConfig[MFSK_PARAM_BITS_PER_FREQ]*maxFreqBands;

	freqTones[0]=freqLower;

	for (i=1; i<numFreqTones; i++)
		freqTones[i] = freqTones[i-1]+defaultMFSKConfig[MFSK_PARAM_FREQ_STEP];

}

/*################################################################################*/
/*################################################################################*/

/*! Get default params set */
en_dspRetType MFSKProc_getDefaultParams(int *config)
{
	memcpy(config, defaultMFSKConfig, (sizeof(int) * MAX_MFSK_PARAMS));
	return DSP_SUCCESS;
}

/*################################################################################*/
/*################################################################################*/

/*! Setting up the scheme parameters */

int MFSKProc_setSchemeParam(uint8_t scheme, uint32_t param, int value)
{
	int ret = -1;
	switch (param-MOD_DEP_PARAM_OFFSET) {

	case MFSK_PARAM_BANDWIDTH:
		schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BANDWIDTH] = value;
		ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BANDWIDTH];
		break;

	case MFSK_PARAM_FREQ_STEP:
		schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_FREQ_STEP] = value;
		ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_FREQ_STEP];
		break;

	case MFSK_PARAM_SYMBOL_RATE:
		schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_SYMBOL_RATE] = value;
		ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_SYMBOL_RATE];
		break;

	case MFSK_PARAM_BITS_PER_FREQ:
		schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BITS_PER_FREQ] = value;
		ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BITS_PER_FREQ];
		break;

	case MFSK_PARAM_NUM_HOPS:
		schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_NUM_HOPS] = value;
		ret = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_NUM_HOPS];
		break;

	}

	MFSKProc_loadParams(scheme);
	return ret;
}

/*################################################################################*/
/*################################################################################*/

/*! Compute Signal Length */
int MFSKProc_computeSignalLength(uint32_t bits, uint8_t scheme)
{
	MFSKProc_loadParams(scheme);
	int numOfSymb;
	if((bits%bitsPerSymb))
		numOfSymb = (bits/bitsPerSymb)+1;
	else
		numOfSymb = (bits/bitsPerSymb);

	int numSamples = numOfSymb * samplesPerSymb;

	printf("numb of samples : %d samples per symb : %d number of samples : %d \n ",numOfSymb,samplesPerSymb,2*numSamples );

	return 2*numSamples;
}

/*################################################################################*/
/*################################################################################*/

/*! Check if current settings are valid */
en_dspRetType MFSKProc_validationCheck(uint8_t scheme)
{
	// TODO : Implement the validation checks for the MFSK scheme
	return DSP_SUCCESS;
}

/*################################################################################*/
/*################################################################################*/

/*! TX MODULATION PROCESS */
uint32_t MFSKProc_processTx(float* databuf, BufferPtr_t sigbuf, uint32_t bits, uint8_t scheme)
{
	float *inSigFloat= databuf;
	int *out = sigbuf;
	int *isig = out;
	uint32_t i;
	complex_float *comSig;
	float *fsig;

	isig=out;
	fsig = (float*)isig;
	comSig = (complex_float*)isig; //complex_float to save the modulated data

	int numOfSymb;
	if((bits%bitsPerSymb))
		numOfSymb = (bits/bitsPerSymb)+1;
	else
		numOfSymb = (bits/bitsPerSymb);
	int numSamples = numOfSymb * samplesPerSymb;
	int numHops = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_NUM_HOPS];
	int countBits = 0;
	int curFreqBand = 0;
	int curHop = 0;
	int curFreq,curBitFreq,curBufPtr=0;
	int bitsPerFreq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BITS_PER_FREQ];
	float curVal,sampleStep;


	while(countBits < bits ) {

		curBitFreq = curFreqBand*tonesPerBand+curHop*(tonesPerBand/numHops);

		float curBit1, curBit2;
		curBit1 = inSigFloat[countBits];
		curBit2 = inSigFloat[countBits+1];
		if (curBit1 == -1.0 && curBit2 == -1.0)
			curBitFreq = curBitFreq+0;
		else if (curBit1 == -1.0 && curBit2 == 1.0)
			curBitFreq = curBitFreq+1;
		else if (curBit1 == 1.0 && curBit2 == -1.0)
			curBitFreq = curBitFreq+2;
		else if (curBit1 == 1.0 && curBit2 == 1.0)
			curBitFreq = curBitFreq+3;

		curFreq = freqTones[curBitFreq];
		sampleStep = 0;

		printf("freq used : %d \n",curFreq);
		if (curFreqBand == 0 ) {
			for(i=0; i<samplesPerSymb; i++) {
				curVal = 2*PI*sampleStep*curFreq;
				comSig[curBufPtr+i].re = cosf(curVal);
				comSig[curBufPtr+i].im = sinf(curVal);
				sampleStep += Ts;
			}
			/*#########################*/
			FILE *fp = fopen("txSignal1.txt","w");
			int j;
			for(j=0; j<samplesPerSymb; j++) {
				fprintf(fp,"%f\n",comSig[curBufPtr+j].re);
				fprintf(fp,"%f\n",comSig[curBufPtr+j].im);

			}
			fclose(fp);
			/*#########################*/
		} else {
			for(i=0; i<samplesPerSymb; i++) {

				curVal = 2*PI*sampleStep*curFreq;
				comSig[curBufPtr+i].re += cosf(curVal);
				comSig[curBufPtr+i].im += sinf(curVal);
				sampleStep += Ts;
			}
			/*#########################*/
			FILE *fp = fopen("txSignal1.txt","w");
			int j;
			for(j=0; j<samplesPerSymb; j++) {
				fprintf(fp,"%f\n",comSig[curBufPtr+j].re);
				fprintf(fp,"%f\n",comSig[curBufPtr+j].im);

			}
			fclose(fp);
			/*#########################*/
		}


		countBits=countBits+bitsPerFreq;
		curFreqBand++;

		if(curFreqBand == maxFreqBands) {
			curFreqBand = 0;
			if (curHop == 0)
				curHop = 1;
			else
				curHop = 0;
			curBufPtr += samplesPerSymb;
			printf("curBufPtr = %d \n",curBufPtr);
			printf("freq used = %d \n",curFreq);
		}

	}

	//Sacle signal to max value of 32767
	float max = 0;
	for (i = 0; i < 2*numSamples; i++){
		if (fabs(fsig[i]) > max) max = fabs(fsig[i]);

	}
	for (i = 0; i < 2*numSamples; i++) {
		float x = 32767*fsig[i]/max;
		isig[i] = (int)x;
	}

	/*#########################*/
		FILE *fo = fopen("txSignal3.txt","w");
		int l;
		for(l=0;l<samplesPerSymb;l++){
			fprintf(fo,"%d\n",isig[2*l]);
			fprintf(fo,"%d\n",isig[2*l+1]);
		}
		fclose(fo);
	/*#########################*/

	return 2*numSamples;

}

/*################################################################################*/
/*################################################################################*/

/*! Process RX */
void MFSKProc_processRx(BufferPtr_t sigbuf, float* databuf, uint32_t bits, uint8_t scheme)
{
	float *outData= databuf;
	int *curSigBlk;
	int* in = sigbuf;

	int curHop = 0;
	int rxBitsCount = 0;
	int curBufPtr = 0;
	int f;
	int curFreq;
	int k;

	int numHops = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_NUM_HOPS];
	int bitsPerFreq = schemeConfig[scheme][MOD_DEP_PARAM_OFFSET+MFSK_PARAM_BITS_PER_FREQ];

	float sigPowerDemod;
	int breakWhile = 0;

	while (rxBitsCount < bits) {
		curSigBlk = in + curBufPtr;
		curBufPtr+=2*samplesPerSymb;

		/*#########################*/
		FILE *fo = fopen("txSignal2.txt","w");
		int l;
		for(l=0;l<samplesPerSymb;l++){
			fprintf(fo,"%d\n",in[2*l]);
			fprintf(fo,"%d\n",in[2*l+1]);
		}
		fclose(fo);
		/*#########################*/

		for (f=0; f<maxFreqBands; f++) {
			curFreq = f*tonesPerBand+curHop*(tonesPerBand/numHops);

			float tempPower = 0.0;
			int maxIdx = 0;

			for (k=0; k<(tonesPerBand/numHops); k++) {

				sigPowerDemod = goertzel( samplesPerSymb,freqTonesRX[curFreq+k],Fs,curSigBlk);
				printf("sig power at k = %d  and freq = %d    : %f \n",k,freqTonesRX[curFreq+k],sigPowerDemod);
				if(k==0){
					tempPower = sigPowerDemod;
					maxIdx = k;
				}
				else {
					if(sigPowerDemod>tempPower) {
						maxIdx = k;
						tempPower = sigPowerDemod;
					}

				}

			}

			printf("max power at : %d \n",freqTonesRX[curFreq+maxIdx]);

			switch (maxIdx) {
			case 0:
				outData[rxBitsCount] = -1.0;
				outData[rxBitsCount+1] = -1.0;
				break;
			case 1:
				outData[rxBitsCount] = 1.0;
				outData[rxBitsCount+1] = -1.0;
				break;
			case 2:
				outData[rxBitsCount] = -1.0;
				outData[rxBitsCount+1] = 1.0;
				break;
			case 3:
				outData[rxBitsCount] = 1.0;
				outData[rxBitsCount+1] = 1.0;
				break;
			}

			rxBitsCount = rxBitsCount+bitsPerFreq;

			if( rxBitsCount == bits || rxBitsCount > bits) {
				breakWhile = 1;
				break;

			}

		}

		if(breakWhile) break;

		if (curHop == 0)
			curHop = 1;
		else
			curHop = 0;

	}


}

/*################################################################################*/
/*################################################################################*/
