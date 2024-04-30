// includes, system
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <math.h>

// includes, cuda
#include <cuda_runtime.h>

// Utilities and timing functions
#include <helper_functions.h>    // includes cuda.h and cuda_runtime_api.h
#include <timer.h>               // timing functions
// CUDA helper functions
#include <helper_cuda.h>         // helper functions for CUDA error check
#include <vector_types.h>

#include "sensors.h"

#define PI            3.1415926535897932385
#define SOUNDSPEED    1540.0
#define FBIN0         9
#define FBINS         23
#define DFTSIZE       64
#define FILES         8
#define RATE          196000
#define BLOCKS        256
#define EBEAMS        12
#define ABEAMS        24
#define BEAMSPC       (0.8*PI/180)
#define BEAMS         (EBEAMS*ABEAMS)
#define BEAMBLKS      2

#define MAX2(x,y)      ((x)<(y) ? (y) : (x))

#define DAQ_BUFFER_LEN  1024*512*8
#define MAX_DAQ_BUFFERS 512

#define DAQ1 1
#define DAQ2 2
#define DAQ3 3
#define DAQ4 4
#define DAQ5 5
#define DAQ6 6
#define DAQ7 7
#define DAQ8 8

#define NUM_DAQS 8

//Macros for CUDA 5.5 compatibility
#define CUT_SAFE_CALL(x) checkCudaErrors((cudaError_t)x)
#define cutGetMaxGflopsDeviceId() gpuGetMaxGflopsDeviceId()

StopWatchInterface *timer = NULL;

float hDFTCos[FBINS * DFTSIZE];
float hDFTSin[FBINS * DFTSIZE];
float hScale[SENSORS];

__constant__ float dDFTCos[FBINS * DFTSIZE];
__constant__ float dDFTSin[FBINS * DFTSIZE];
__constant__ float dScale[SENSORS];

float hBFRe[FBINS * BEAMS * SENSORS];
float hBFIm[FBINS * BEAMS * SENSORS];

float* dBFRe;
float* dBFIm;

short* hSensorData;
float hBFData[2 * FBINS * BEAMS * BLOCKS];

short* dSensorData;
float* dBFData;


//Struct for pre-recorded beam processing function parameters
struct beamRecordedArgs {
	char *dataPath;
	char *bfOutputFile;
};

/*************************************/

void initCuda(void) {

	cudaThreadExit();
	int dev = cutGetMaxGflopsDeviceId();
	printf("MAX Device ID : %d\n", dev);
	cudaDeviceProp properties;
	cudaGetDeviceProperties(&properties, dev);
	printf("DEIVE NAME : %s\n", properties.name);
	CUT_SAFE_CALL(cudaSetDevice(dev));
	CUT_SAFE_CALL(gpuDeviceInit(dev));
	sdkCreateTimer(&timer);
}

void checkCudaMem(void) {
	size_t total, avail;
	CUT_SAFE_CALL(cudaMemGetInfo(&avail, &total));
	printf("CUDA Memory: total = %ld, free = %ld\n", total, avail);
}

void allocCudaMem(void) {
	CUT_SAFE_CALL(
			cudaMalloc((void**)&dSensorData, sizeof(short)*SENSORS*DFTSIZE*BLOCKS));
	CUT_SAFE_CALL(cudaMalloc((void** )&dBFData, sizeof(hBFData)));
	CUT_SAFE_CALL(cudaMalloc((void** )&dBFRe, sizeof(hBFRe)));
	CUT_SAFE_CALL(cudaMalloc((void** )&dBFIm, sizeof(hBFIm)));
}

void shutdown(void) {
	free(hSensorData);
	CUT_SAFE_CALL(cudaFree(dBFRe));
	CUT_SAFE_CALL(cudaFree(dBFIm));
	CUT_SAFE_CALL(cudaFree(dBFData));
	CUT_SAFE_CALL(cudaFree(dSensorData));
	sdkDeleteTimer(&timer);
	CUT_SAFE_CALL(cudaDeviceReset());
}

void startTimer(void) {
	sdkResetTimer(&timer);
	sdkStartTimer(&timer);
}

void stopTimer(char* msg) {
	cudaThreadSynchronize();
	sdkStopTimer(&timer);
	printf("%s: %0.4f ms\n", msg, sdkGetTimerValue(&timer));
}

void initDFT(void) {
	float K = 2 * PI / DFTSIZE;
	for (int i = 0; i < DFTSIZE; i++) {
		for (int f = 0; f < FBINS; f++) {
			hDFTCos[f * DFTSIZE + i] = cos(K * (f + FBIN0) * i);
			hDFTSin[f * DFTSIZE + i] = -sin(K * (f + FBIN0) * i);
		}
	}
	CUT_SAFE_CALL(cudaMemcpyToSymbol(dDFTSin, hDFTSin, sizeof(hDFTSin)));
	CUT_SAFE_CALL(cudaMemcpyToSymbol(dDFTCos, hDFTCos, sizeof(hDFTCos)));
}

void initBF() {
	for (int e = 0; e < EBEAMS; e++) {
		float phi = e * BEAMSPC - (EBEAMS - 1) * BEAMSPC / 2;
		for (int a = 0; a < ABEAMS; a++) {
			float theta = a * BEAMSPC - (ABEAMS - 1) * BEAMSPC / 2;
			for (int f = 0; f < FBINS; f++) {
				int fb = FBIN0 + f;
				for (int i = 0; i < SENSORS; i++) {
					float w = sensorXPos[i] * sin(theta) * cos(phi)
							+ sensorYPos[i] * sin(phi);
					w *= 2 * PI * RATE / DFTSIZE * fb / SOUNDSPEED;
					int tn = (f * SENSORS + i) * BEAMS + e * ABEAMS + a;
					hBFRe[tn] = sin(w) * hScale[i];
					hBFIm[tn] = cos(w) * hScale[i];
				}
			}
		}
	}
	CUT_SAFE_CALL(
			cudaMemcpy(dBFRe, hBFRe, sizeof(hBFRe), cudaMemcpyHostToDevice));
	CUT_SAFE_CALL(
			cudaMemcpy(dBFIm, hBFIm, sizeof(hBFIm), cudaMemcpyHostToDevice));
}

int readData(char* filename) {

	int samples = 0;
	FILE* fh[FILES];
	printf("Dataset: %s\n", filename);
	for (int i = 0; i < FILES; i++) {
		char fn[256];
		sprintf(fn, "%s/DAQ_%d", filename, i + 1);
		fh[i] = fopen(fn, "rb");
		if (fh[i] == NULL) {
			fprintf(stderr, "Unable to open input file %s\n", fn);
			exit(1);
		}
		fseek(fh[i], 0, SEEK_END);
		int n = ftell(fh[i]) / (64 * sizeof(short) + 4);
		if (i == 0)
			{samples = n;}
		else if (n < samples)
			{samples = n;}
		
		printf("Samples from DAQ%i : %d  Size of File : %d  Size of data read : %d \n",i,n,ftell(fh[i]), n*66*sizeof(short));	
		fseek(fh[i], 0, SEEK_SET);
	}

  
	printf("samples : %d \n",samples );
	printf("Length: %0.2f seconds\n", (float) samples / RATE);
	hSensorData = (short*) malloc(SENSORS * samples * sizeof(short));
	if (hSensorData == NULL) {
		fprintf(stderr, "Out of memory!");
		exit(1);
	}
	static int junk[4];
	long inc = 0;
	for (int j = 0; j < samples; j++) {
		for (int i = 0; i < FILES; i++) {
			if (i == FILES - 1) {
				fread(&junk, sizeof(int), 1, fh[i]);
				fread(hSensorData + inc, sizeof(short), 60, fh[i]);
				fread(&junk, sizeof(short), 4, fh[i]);
				inc += 60;
			} else {
				fread(&junk, sizeof(int), 1, fh[i]);
				fread(hSensorData + inc, sizeof(short), 64, fh[i]);
				inc += 64;
			}
		}
	}
	for (int i = 0; i < FILES; i++) {
		fclose(fh[i]);
	}

	return samples;
}

void readScale() {

	FILE* fh = fopen("calib.txt", "rt");
	if (fh == NULL) {
		printf("Sensor calibration not available\n");
		for (int i = 0; i < SENSORS; i++)
			hScale[i] = 1;
	} else {
		for (int i = 0; i < SENSORS; i++) {
			float s, o;
			fscanf(fh, "%f %f", &s, &o);
			hScale[i] = s;
		}
		fclose(fh);
	}
	CUT_SAFE_CALL(cudaMemcpyToSymbol(dScale, hScale, sizeof(hScale)));
}

__global__ void process(short* dataIn, float* dataOut, float* dBFRe,
		float* dBFIm) {
	__shared__ float re[SENSORS];
	__shared__ float im[SENSORS];
	int f = blockIdx.x;
	int n = blockIdx.y;
	int s = threadIdx.x;
	if (s < SENSORS) {
		float sumRe = 0;
		float sumIm = 0;
		for (int i = 0; i < DFTSIZE; i++) {
			sumRe += dDFTCos[f * DFTSIZE + i]
					* dataIn[(n * DFTSIZE + i) * SENSORS + s];
			sumIm += dDFTSin[f * DFTSIZE + i]
					* dataIn[(n * DFTSIZE + i) * SENSORS + s];
		}
		re[s] = sumRe;
		im[s] = sumIm;
	}
	__syncthreads();
	if (s < BEAMBLKS * BEAMS) {
		int b = s % BEAMS;
		int start = s / BEAMS * SENSORS / BEAMBLKS;
		float sumRe = 0;
		float sumIm = 0;
		for (int i = start; i < start + SENSORS / BEAMBLKS; i++) {
			int tn = (f * SENSORS + i) * BEAMS + b;
			float tr = re[i] * dBFRe[tn] - im[i] * dBFIm[tn];
			float ti = im[i] * dBFRe[tn] + re[i] * dBFIm[tn];
			sumRe += tr;
			sumIm += ti;
		}

		int outndx2 = 2 * ((n * BEAMS + b) * FBINS + f);
		if (s < BEAMS) {
			dataOut[outndx2] = sumRe;
			dataOut[outndx2 + 1] = sumIm;
		}

		__syncthreads();
		if (s >= BEAMS) {
			dataOut[outndx2] += sumRe;
			dataOut[outndx2 + 1] += sumIm;
		}

	}
}

/******************BEAM PROCESSING FOR PRE-RECORDED DATA SET********************************************/
void beamProcessRecorded(void *args) {

	struct beamRecordedArgs *params = (struct beamRecordedArgs *) args;
	int blks;
	FILE* out = NULL;
	int samples = readData(params->dataPath);
	

	
	readScale();
	out = fopen(params->bfOutputFile, "wb");
	if (out == NULL) {
		printf("Failed to create beamformed output file\n");
		exit(0);
	}
	
	
	int header[4];
	header[0] = 0x4f464252;
	header[1] = BEAMS * FBINS;
	header[2] = DFTSIZE;
	header[3] = RATE;
	fwrite(header, sizeof(int), 4, out);

	initCuda();
	checkCudaMem();
	initSensors();
	allocCudaMem();
	checkCudaMem();
	initDFT();
	initBF();

	printf("Number of packets to be processed in BF : %d\n",
			(samples / (DFTSIZE * BLOCKS)) + 1);

	startTimer();

	int i = 0;

		while (i < samples) {
			blks = (samples - i) / DFTSIZE;
			if (blks > BLOCKS)
				blks = BLOCKS;
			CUT_SAFE_CALL(
					cudaMemcpy(dSensorData, hSensorData+SENSORS*i, DFTSIZE*SENSORS*blks*sizeof(short), cudaMemcpyHostToDevice));
			dim3 threads(MAX2(SENSORS,BEAMS*BEAMBLKS));
			dim3 grid(FBINS, blks);
			process<<<grid, threads>>>(dSensorData, dBFData, dBFRe, dBFIm);
			CUT_SAFE_CALL(
					cudaMemcpy(hBFData, dBFData, sizeof(hBFData),
							cudaMemcpyDeviceToHost));
			if (out != NULL){
				fwrite(hBFData, 2 * FBINS * BEAMS * blks, sizeof(float), out);
                }
			i += DFTSIZE * BLOCKS;

		}

	stopTimer("Processing time");

	if (out != NULL)
		fclose(out);
	shutdown();
	printf("Beam-forming process completed\n");
}
/**********************************************************************************************/

/*************************************************************/
int main(int argc, char* argv[]) {

	if (argc < 3) {
		printf(
				"Usage: %s Path_to_DAQ_dataset output_file Path_to_save_BFO_file \n",argv[0]);
		
		return 1;
	}
		

		struct beamRecordedArgs processParams;
		processParams.dataPath = argv[1];
		processParams.bfOutputFile = argv[2];

		beamProcessRecorded((void *) &processParams);
	
	return 0;
}
