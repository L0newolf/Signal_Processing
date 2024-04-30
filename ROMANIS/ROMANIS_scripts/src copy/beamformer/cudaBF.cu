// includes, system
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <pthread.h>
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

//Pointers for generating real-time processing bauffers
short **daq1Buffer, **daq2Buffer, **daq3Buffer, **daq4Buffer, **daq5Buffer,
		**daq6Buffer, **daq7Buffer, **daq8Buffer;
int *daq1Len, *daq2Len, *daq3Len, *daq4Len, *daq5Len, *daq6Len, *daq7Len,
		*daq8Len;
int daq1Count, daq2Count, daq3Count, daq4Count, daq5Count, daq6Count, daq7Count,
		daq8Count;

//Struct for pre-recorded beam processing thread parameters
struct beamRecordedArgs {
	char *dataPath;
	char *bfOutputFile;
};

/*  Socket and Queue Related stuff */
#define SOCKET_DISPLAY_PATH "sockets/SOCKET_DISPLAY_PATH"
#define SOCKET_DAQ1_PATH "sockets/SOCKET_DAQ1_PATH"
#define SOCKET_DAQ2_PATH "sockets/SOCKET_DAQ2_PATH"
#define SOCKET_DAQ3_PATH "sockets/SOCKET_DAQ3_PATH"
#define SOCKET_DAQ4_PATH "sockets/SOCKET_DAQ4_PATH"
#define SOCKET_DAQ5_PATH "sockets/SOCKET_DAQ5_PATH"
#define SOCKET_DAQ6_PATH "sockets/SOCKET_DAQ6_PATH"
#define SOCKET_DAQ7_PATH "sockets/SOCKET_DAQ7_PATH"
#define SOCKET_DAQ8_PATH "sockets/SOCKET_DAQ8_PATH"

#define TRANSFER 0
#define PROCESS 1
#define COMPLETE 2

#define TERMINATE 1
#define NOT_TERMINATE 0

#define FRAMESIZE 32
#define PACKET_LENGTH 8
int dispSockCon;
int processStatus = PROCESS;
int BFcomplete = PROCESS;
float txPackDisp[PACKET_LENGTH * BEAMS * FBINS];
int bfDataCount = 0;
int sockDataCount = 0;
int daqStatus = PROCESS;
pthread_mutex_t bfmutex, daqMutex;

int daqSock[NUM_DAQS];
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
	/*
	int samples = 0;
	FILE *hin = fopen("/home/arl/Dropbox/ROMANIS/HIN_RT","rb");
	fseek(hin, 0, SEEK_END);
	samples = ftell(hin) / (SENSORS*sizeof(short));
	printf("samples : %d  length : %0.2f \n",samples, (float) samples / RATE);
	hSensorData = (short*) malloc(SENSORS * samples * sizeof(short));
	fseek(hin, 0, SEEK_SET);
	fread(hSensorData, sizeof(short), SENSORS * samples, hin);
	fclose(hin);
	*/

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

	
	/*FILE *hin = fopen("/home/arl/Dropbox/ROMANIS/HIN", "wb");
	for(int k=0;k<SENSORS * samples;k++)
        {
            fprintf(hin, "%d\n", hSensorData[k]);
        }
	fclose(hin);*/

	return samples;
}

void readScale(char* filename) {
	char fn[256];
	sprintf(fn, "calib.txt", filename);
	FILE* fh = fopen(fn, "rt");
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
void * beamProcessRecorded(void *args) {

	struct beamRecordedArgs *params = (struct beamRecordedArgs *) args;
	int blks;
	FILE* out = NULL;
	int samples = readData(params->dataPath);
	

	
	readScale(params->dataPath);
	out = fopen(params->bfOutputFile, "wb");
	if (out == NULL) {
		printf("Failed to create beamformed output file\n");
		return 0;
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
	processStatus = PROCESS;

	if (processStatus == PROCESS) {
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
				//for(int k=0;k<2*FBINS*BEAMS*blks;k++)
                //        fprintf(out, "%0.2f\n",hBFData[k] );
                }
			i += DFTSIZE * BLOCKS;
			//////////////////////////////////////////////////////////
			int beams = BEAMS * FBINS;
			int FrameSize = FRAMESIZE;
			int framesToDisplay = sizeof(hBFData)
					/ (2 * BEAMS * FBINS * FRAMESIZE * sizeof(float));

			float bfoFrameAvg[FrameSize][beams];
			int dataCount = 0;
			int dataFrameCount = 0;
			float bfoSum = 0.0;

			for (int k = 0; k < framesToDisplay; k++) {
				for (int i = 0; i < FrameSize; i++) {
					for (int j = 0; j < beams; j++) {
						bfoFrameAvg[i][j] = sqrt(
								pow(hBFData[dataCount], 2)
										+ pow(hBFData[dataCount + 1], 2));
						dataCount += 2;
					}
				}

				for (int i = 0; i < beams; i++) {
					bfoSum = 0.0;
					for (int j = 0; j < FrameSize; j++) {
						bfoSum += bfoFrameAvg[j][i];
					}
					txPackDisp[dataFrameCount] = bfoSum / FrameSize;
					dataFrameCount++;
				}
			}
			//////////////////////////////////////////////////////////
			//printf("PACKETS PROCESSED : %d\n",++processCounter );
			pthread_mutex_lock(&bfmutex);
			processStatus = TRANSFER;
			pthread_mutex_unlock(&bfmutex);
		}
	}

	stopTimer("Processing time");

	if (out != NULL)
		fclose(out);
	shutdown();
	pthread_mutex_lock(&bfmutex);
	BFcomplete = COMPLETE;
	pthread_mutex_unlock(&bfmutex);
	printf("Beam-forming process completed\n");
	return 0;
}
/**********************************************************************************************/

/************ DAQ SOCKET SERVER FUNCTION ************/
void *startSockServer(void * args) {
	int lenSock,daqSockCon;
	struct sockaddr_un localDAQ;
	int respDAQ;
	int *daq = (int *) args;
	if ((daqSock[*(daq)-1] = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
		perror("socket");
		exit(-1);
	}

	localDAQ.sun_family = AF_UNIX;

	switch (*(daq)) {
	case DAQ1:
		strcpy(localDAQ.sun_path, SOCKET_DAQ1_PATH);
		break;
	case DAQ2:
		strcpy(localDAQ.sun_path, SOCKET_DAQ2_PATH);
		break;
	case DAQ3:
		strcpy(localDAQ.sun_path, SOCKET_DAQ3_PATH);
		break;
	case DAQ4:
		strcpy(localDAQ.sun_path, SOCKET_DAQ4_PATH);
		break;
	case DAQ5:
		strcpy(localDAQ.sun_path, SOCKET_DAQ5_PATH);
		break;
	case DAQ6:
		strcpy(localDAQ.sun_path, SOCKET_DAQ6_PATH);
		break;
	case DAQ7:
		strcpy(localDAQ.sun_path, SOCKET_DAQ7_PATH);
		break;
	case DAQ8:
		strcpy(localDAQ.sun_path, SOCKET_DAQ8_PATH);
		break;
	}

	unlink(localDAQ.sun_path);
	lenSock = strlen(localDAQ.sun_path) + sizeof(localDAQ.sun_family);
	if (bind(daqSock[*(daq)-1], (struct sockaddr *) &localDAQ, lenSock) == -1) {
		perror("bind");
		exit(-1);
	}
	if (listen(daqSock[*(daq)-1], 100) == -1) {
		perror("listen");
		exit(-1);
	}

	int daqConn;
	struct sockaddr_un remoteDAQ;
	int status;
	daqConn = sizeof(remoteDAQ);

	if ((daqSockCon = accept(daqSock[*(daq)-1], (struct sockaddr *) &remoteDAQ,(socklen_t *) &daqConn)) == -1) {
			perror("accept");
			exit(-1);
		}

	respDAQ = NOT_TERMINATE;
	do {

		//printf("DAQ found \n");
		status = recv(daqSockCon, &respDAQ, sizeof(int), 0);

		if (status != -1) {
			if (respDAQ == NOT_TERMINATE) {

				//receive the data length (number of bytes) as int
				//receive the data buffer as short

				// Copy data into the correct arrays here based on the daqNum value

				switch (*(daq)) {
				case DAQ1:
					//printf("DAQ 1 rcvd \n");
					if (recv(daqSockCon, &daq1Len[daq1Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq1Buffer[daq1Count][0],daq1Len[daq1Count] * sizeof(short), 0)==-1) perror("recv");
					daq1Count++;
					if (daq1Count == MAX_DAQ_BUFFERS)
						daq1Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq1Count);
					break;
				case DAQ2:
					//printf("DAQ 2 rcvd \n");
					if (recv(daqSockCon, &daq2Len[daq2Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq2Buffer[daq2Count][0],daq2Len[daq2Count] * sizeof(short), 0)==-1) perror("recv");
					daq2Count++;
					if (daq2Count == MAX_DAQ_BUFFERS)
						daq2Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq2Count);
					break;
				case DAQ3:
					//printf("DAQ 3 rcvd \n");
					if (recv(daqSockCon, &daq3Len[daq3Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq3Buffer[daq3Count][0],daq3Len[daq3Count] * sizeof(short), 0)==-1) perror("recv");
					daq3Count++;
					if (daq3Count == MAX_DAQ_BUFFERS)
						daq3Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq3Count);
					break;
				case DAQ4:
					//printf("DAQ 4 rcvd \n");
					if (recv(daqSockCon, &daq4Len[daq4Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq4Buffer[daq4Count][0],daq4Len[daq4Count] * sizeof(short), 0)==-1) perror("recv");
					daq4Count++;
					if (daq4Count == MAX_DAQ_BUFFERS)
						daq4Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq4Count);
					break;
				case DAQ5:
					//printf("DAQ 5 rcvd \n");
					if (recv(daqSockCon, &daq5Len[daq5Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq5Buffer[daq5Count][0],daq5Len[daq5Count] * sizeof(short), 0)==-1) perror("recv");
					daq5Count++;
					if (daq5Count == MAX_DAQ_BUFFERS)
						daq5Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq5Count);
					break;
				case DAQ6:
					//printf("DAQ 6 rcvd \n");
					if (recv(daqSockCon, &daq6Len[daq6Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq6Buffer[daq6Count][0],daq6Len[daq6Count] * sizeof(short), 0)==-1) perror("recv");
					daq6Count++;
					if (daq6Count == MAX_DAQ_BUFFERS)
						daq6Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq6Count);
					break;
				case DAQ7:
					//printf("DAQ 7 rcvd \n");
					if (recv(daqSockCon, &daq7Len[daq7Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq7Buffer[daq7Count][0],daq7Len[daq7Count] * sizeof(short), 0)==-1) perror("recv");
					daq7Count++;
					if (daq7Count == MAX_DAQ_BUFFERS)
						daq7Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq7Count);
					break;
				case DAQ8:
					//printf("DAQ 8 rcvd \n");
					if (recv(daqSockCon, &daq8Len[daq8Count], sizeof(int), 0)==-1) perror("recv");
					if (recv(daqSockCon, &daq8Buffer[daq8Count][0],daq8Len[daq8Count] * sizeof(short), 0)==-1) perror("recv");
					daq8Count++;
					if (daq8Count == MAX_DAQ_BUFFERS)
						daq8Count = 0;
					printf("DAQ %d count : %d \n",*(daq),daq8Count);
					break;
				}
				//printf("Got data from DAQ\n");
			}
			pthread_mutex_lock(&bfmutex);
			++sockDataCount;
			pthread_mutex_unlock(&bfmutex);


		} else {
			perror("recv");
			printf("Error in getting status message !!!!\n");
		}

	} while (respDAQ != TERMINATE);

	pthread_mutex_lock(&bfmutex);
	printf("Total packets rcvd from DAQ : %d\n", sockDataCount-8);
	pthread_mutex_unlock(&bfmutex);
	printf("Closing Connection to DAQ system \n");

	close(daqSockCon);
	close(daqSock[*(daq)-1]);


	switch (*(daq)) {
	case DAQ1:
		unlink(SOCKET_DAQ1_PATH);
		break;
	case DAQ2:
		unlink(SOCKET_DAQ2_PATH);
		break;
	case DAQ3:
		unlink(SOCKET_DAQ3_PATH);
		break;
	case DAQ4:
		unlink(SOCKET_DAQ4_PATH);
		break;
	case DAQ5:
		unlink(SOCKET_DAQ5_PATH);
		break;
	case DAQ6:
		unlink(SOCKET_DAQ6_PATH);
		break;
	case DAQ7:
		unlink(SOCKET_DAQ7_PATH);
		break;
	case DAQ8:
		unlink(SOCKET_DAQ8_PATH);
		break;
	}

	daqStatus = COMPLETE;
	return 0;

}
/*************************************************************/

/************ BEAM PROCESSING FOR REAL TIME RECORDED DATA SET ************/

void * beamProcessRealTime(void *args) {

	int daq1Read = 0;
	int daq2Read = 0;
	int daq3Read = 0;
	int daq4Read = 0;
	int daq5Read = 0;
	int daq6Read = 0;
	int daq7Read = 0;
	int daq8Read = 0;

	int samples = 0;

	FILE* out = NULL;

	out = fopen("bfo_RT", "w");

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

	readScale("calibartion");



	// CHECK FOR THE EXIT CONDITION OF THIS WHILE LOOP

	while ((8*bfDataCount)!=(sockDataCount-8) || daqStatus != COMPLETE) {
		//printf("Got here!!! %d %d  \n",8*bfDataCount,(sockDataCount-8));
		int n = 0;
		if (daq1Count!=daq1Read && daq2Count!=daq2Read && daq3Count!=daq3Read && daq4Count!=daq4Read
				&& daq5Count!=daq5Read && daq6Count!=daq6Read && daq7Count!=daq7Read
				&& daq8Count!=daq8Read) {

			n = daq1Len[daq1Read] / (64 * sizeof(short) + 4);
			//printf(" daq1Len[daq1Read] : %d\n", daq1Len[daq1Read]);
			samples = n;

			n = daq2Len[daq2Read] / (64 * sizeof(short) + 4);
			//printf(" daq2Len[daq2Read] : %d\n", daq2Len[daq2Read]);
			if (n < samples)
				samples = n;

			n = daq3Len[daq3Read] / (64 * sizeof(short) + 4);
			//printf(" daq3Len[daq3Read] : %d\n", daq3Len[daq3Read]);
			if (n < samples)
				samples = n;

			n = daq4Len[daq4Read] / (64 * sizeof(short) + 4);
			//printf(" daq4Len[daq4Read] : %d\n", daq4Len[daq4Read]);
			if (n < samples)
				samples = n;

			n = daq5Len[daq5Read] / (64 * sizeof(short) + 4);
			//printf(" daq5Len[daq5Read] : %d\n", daq5Len[daq5Read]);
			if (n < samples)
				samples = n;

			n = daq6Len[daq6Read] / (64 * sizeof(short) + 4);
			//printf(" daq6Len[daq6Read] : %d\n", daq6Len[daq6Read]);
			if (n < samples)
				samples = n;

			n = daq7Len[daq7Read] / (64 * sizeof(short) + 4);
			//printf(" daq7Len[daq7Read] : %d\n", daq7Len[daq7Read]);
			if (n < samples)
				samples = n;

			n = daq8Len[daq8Read] / (64 * sizeof(short) + 4);
			//printf(" daq8Len[daq8Read] : %d\n", daq8Len[daq8Read]);
			if (n < samples)
				samples = n;

			//printf(" samples  : %d\n", samples);
			hSensorData = (short*) malloc(SENSORS * samples * sizeof(short));
			if (hSensorData == NULL) {
				fprintf(stderr, "Out of memory!");
				exit(1);
			}

			int daq1Ptr = 2;
			int daq2Ptr = 2;
			int daq3Ptr = 2;
			int daq4Ptr = 2;
			int daq5Ptr = 2;
			int daq6Ptr = 2;
			int daq7Ptr = 2;
			int daq8Ptr = 2;

			int bufPtr = 0;
			for (int j = 0; j < samples; j++) {
				for (int i = 0; i < 60; i++) {
					hSensorData[bufPtr] = daq1Buffer[daq1Read][daq1Ptr];
					bufPtr++;
					daq1Ptr++;
				}
				daq1Ptr += 4;

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq2Buffer[daq2Read][daq2Ptr];
					bufPtr++;
					daq2Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq3Buffer[daq3Read][daq3Ptr];
					bufPtr++;
					daq3Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq4Buffer[daq4Read][daq4Ptr];
					bufPtr++;
					daq4Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq5Buffer[daq5Read][daq5Ptr];
					bufPtr++;
					daq5Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq6Buffer[daq6Read][daq6Ptr];
					bufPtr++;
					daq6Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq7Buffer[daq7Read][daq7Ptr];
					bufPtr++;
					daq7Ptr++;
				}

				for (int i = 0; i < 64; i++) {
					hSensorData[bufPtr] = daq8Buffer[daq8Read][daq8Ptr];
					bufPtr++;
					daq8Ptr++;
				}
			}

			daq1Read++;
			if (daq1Read == MAX_DAQ_BUFFERS)
				daq1Read = 0;
			daq2Read++;
			if (daq2Read == MAX_DAQ_BUFFERS)
				daq2Read = 0;
			daq3Read++;
			if (daq3Read == MAX_DAQ_BUFFERS)
				daq3Read = 0;
			daq4Read++;
			if (daq4Read == MAX_DAQ_BUFFERS)
				daq4Read = 0;
			daq5Read++;
			if (daq5Read == MAX_DAQ_BUFFERS)
				daq5Read = 0;
			daq6Read++;
			if (daq6Read == MAX_DAQ_BUFFERS)
				daq6Read = 0;
			daq7Read++;
			if (daq7Read == MAX_DAQ_BUFFERS)
				daq7Read = 0;
			daq8Read++;
			if (daq8Read == MAX_DAQ_BUFFERS)
				daq8Read = 0;

			int blks;
			int i = 0;

			if (processStatus == PROCESS) {
				while (i < samples) {
					//printf("PROCESS STATUS : %d  \n",processStatus);

					blks = (samples - i) / DFTSIZE;
					if (blks > BLOCKS)
						blks = BLOCKS;
					CUT_SAFE_CALL(
							cudaMemcpy(dSensorData, hSensorData+SENSORS*i, DFTSIZE*SENSORS*blks*sizeof(short), cudaMemcpyHostToDevice));
					dim3 threads(MAX2(SENSORS,BEAMS*BEAMBLKS));
					dim3 grid(FBINS, blks);
					process<<<grid, threads>>>(dSensorData, dBFData, dBFRe,
							dBFIm);
					CUT_SAFE_CALL(
							cudaMemcpy(hBFData, dBFData, sizeof(hBFData),
									cudaMemcpyDeviceToHost));
					fwrite(hBFData, 2 * FBINS * BEAMS * blks, sizeof(float),
							out);
					i += DFTSIZE * BLOCKS;
					//////////////////////////////////////////////////////////
					int beams = BEAMS * FBINS;
					int FrameSize = FRAMESIZE;
					int framesToDisplay = sizeof(hBFData)
							/ (2 * BEAMS * FBINS * FRAMESIZE * sizeof(float));

					float bfoFrameAvg[FrameSize][beams];
					int dataCount = 0;
					int dataFrameCount = 0;
					float bfoSum = 0.0;

					for (int k = 0; k < framesToDisplay; k++) {
						for (int i = 0; i < FrameSize; i++) {
							for (int j = 0; j < beams; j++) {
								bfoFrameAvg[i][j] = sqrt(
										pow(hBFData[dataCount], 2)
												+ pow(hBFData[dataCount + 1],
														2));
								dataCount += 2;
							}
						}

						for (int i = 0; i < beams; i++) {
							bfoSum = 0.0;
							for (int j = 0; j < FrameSize; j++) {
								bfoSum += bfoFrameAvg[j][i];
							}
							txPackDisp[dataFrameCount] = bfoSum / FrameSize;
							dataFrameCount++;
						}
					}
					//////////////////////////////////////////////////////////
					//printf("PACKETS PROCESSED \n");

					pthread_mutex_lock(&bfmutex);
					processStatus = TRANSFER;
					pthread_mutex_unlock(&bfmutex);
				}
				printf("Total Processed BF Data : %d\n", ++bfDataCount);
			}

		}
	}

	fclose(out);
	shutdown();
	pthread_mutex_lock(&bfmutex);
	BFcomplete = COMPLETE;
	pthread_mutex_unlock(&bfmutex);
	printf("Beam-forming process completed\n");
	return 0;
}
/*************************************************************************/

/*****RAEL TIME DATA PROCESSING BUFFER MEMORY ALLOCATION******/

int allocMemRT() {

	if ((daq1Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
			== NULL
			|| (daq2Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq3Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq4Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq5Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq6Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq7Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq8Buffer = (short **) malloc(MAX_DAQ_BUFFERS * sizeof(short*)))
					== NULL
			|| (daq1Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq2Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq3Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq4Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq5Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq6Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq7Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL
			|| (daq8Len = (int*) malloc(MAX_DAQ_BUFFERS * sizeof(int))) == NULL) {
		return 0;
	}

	for (int i = 0; i < MAX_DAQ_BUFFERS; i++) {
		if ((daq1Buffer[i] = (short *) malloc(DAQ_BUFFER_LEN * sizeof(short)))
				== NULL
				|| (daq2Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq3Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq4Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq5Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq6Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq7Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL
				|| (daq8Buffer[i] = (short *) malloc(
						DAQ_BUFFER_LEN * sizeof(short))) == NULL) {
			return 0;
		}

	}
	daq1Count = 0;
	daq2Count = 0;
	daq3Count = 0;
	daq4Count = 0;
	daq5Count = 0;
	daq6Count = 0;
	daq7Count = 0;
	daq8Count = 0;

	return 1;
}
/*************************************************************/
int main(int argc, char* argv[]) {

	if (argc < 2) {
		printf(
				"Usage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
				argv[0]);
		printf(
				"Operating_Mode = 0 : Real Time BF processing\nUsage: %s Operating_Mode output_file cudaBF\n",
				argv[0]);
		printf(
				"Operating_Mode = 1 : Pre-recorded data BF processing\nUsage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
				argv[0]);
		return 1;
	}
	////////////////////////////////////////////////////////////////////////////////////
	// Pre-recorded data processing mode
	////////////////////////////////////////////////////////////////////////////////////
	if (!strcmp(argv[1], "1")) {

		if (argc < 3) {
			printf(
					"Usage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
					argv[0]);
			printf(
					"Operating_Mode = 1 : Pre-recorded data BF processing\nUsage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
					argv[0]);
			return 1;
		}
		int respServer;
		pthread_t threadBF;

		pthread_mutex_init(&bfmutex, NULL);

		struct beamRecordedArgs processParams;
		processParams.dataPath = argv[2];
		processParams.bfOutputFile = argv[3];

		pthread_create(&threadBF, NULL, beamProcessRecorded,
				(void *) &processParams);

		//int packetTransferCount = 0;

		while (BFcomplete != COMPLETE) {
			if (processStatus == TRANSFER) {

				int sockDisplay, len;
				struct sockaddr_un remote;

				if ((sockDisplay = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
					perror("socket");
				}

				remote.sun_family = AF_UNIX;
				strcpy(remote.sun_path, SOCKET_DISPLAY_PATH);
				len = strlen(remote.sun_path) + sizeof(remote.sun_family);

				//printf("Checking for display...\n");
				int dispConStatus = connect(sockDisplay,
						(struct sockaddr *) &remote, len);
				if (dispConStatus == -1) {
					//printf("No display process found\n");
					pthread_mutex_lock(&bfmutex);
					processStatus = PROCESS;
					pthread_mutex_unlock(&bfmutex);
				} else {
					//printf("Display process found.. Transferring packet\n");
					respServer = NOT_TERMINATE;
					send(sockDisplay, &respServer, sizeof(int), 0);
					send(sockDisplay, txPackDisp,
							sizeof(float) * PACKET_LENGTH * BEAMS * FBINS, 0);
					usleep(300000);
					pthread_mutex_lock(&bfmutex);
					processStatus = PROCESS;
					pthread_mutex_unlock(&bfmutex);
					//printf("PACKETS TRANSFERRED : %d\n",++packetTransferCount);
				}
				close(sockDisplay);
			}
		}

		pthread_join(threadBF, NULL);
		pthread_mutex_destroy(&bfmutex);

		/* Tell server that all packets have been transmitted */
		int sockDisplay, len;
		struct sockaddr_un remote;
		if ((sockDisplay = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
			perror("socket");
		}
		remote.sun_family = AF_UNIX;
		strcpy(remote.sun_path, SOCKET_DISPLAY_PATH);
		len = strlen(remote.sun_path) + sizeof(remote.sun_family);
		int dispConStatus = connect(sockDisplay, (struct sockaddr *) &remote,
				len);
		respServer = TERMINATE;
		send(sockDisplay, &respServer, sizeof(int), 0);
		close(sockDisplay);
	}
	//////////////////////////////////////////////////////////////////////
	//Real Time Data processing mode
	///////////////////////////////////////////////////////////////////////
	else if (!strcmp(argv[1], "0")) {
		if (!allocMemRT()) {
			printf("Error allocating memory !!!\n");
			return -1;
		}

		pthread_mutex_init(&bfmutex, NULL);
		pthread_mutex_init(&daqMutex, NULL);
		int respServer;

		pthread_t threadDAQ1, threadDAQ2, threadDAQ3, threadDAQ4, threadDAQ5,
				threadDAQ6, threadDAQ7, threadDAQ8, threadBF;

		void *dummy = 0;

		pthread_create(&threadBF, NULL, beamProcessRealTime, dummy);
		int daq1 = DAQ1;
		pthread_create(&threadDAQ1, NULL, startSockServer, (void *) &daq1);
		int daq2 = DAQ2;
		pthread_create(&threadDAQ2, NULL, startSockServer, (void *) &daq2);
		int daq3 = DAQ3;
		pthread_create(&threadDAQ3, NULL, startSockServer, (void *) &daq3);
		int daq4 = DAQ4;
		pthread_create(&threadDAQ4, NULL, startSockServer, (void *) &daq4);
		int daq5 = DAQ5;
		pthread_create(&threadDAQ5, NULL, startSockServer, (void *) &daq5);
		int daq6 = DAQ6;
		pthread_create(&threadDAQ6, NULL, startSockServer, (void *) &daq6);
		int daq7 = DAQ7;
		pthread_create(&threadDAQ7, NULL, startSockServer, (void *) &daq7);
		int daq8 = DAQ8;
		pthread_create(&threadDAQ8, NULL, startSockServer, (void *) &daq8);

		//int packetTransferCount = 0;

		while (BFcomplete != COMPLETE) {
			if (processStatus == TRANSFER) {

				int sockDisplay, len;
				struct sockaddr_un remote;

				if ((sockDisplay = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
					perror("socket");
				}

				remote.sun_family = AF_UNIX;
				strcpy(remote.sun_path, SOCKET_DISPLAY_PATH);
				len = strlen(remote.sun_path) + sizeof(remote.sun_family);

				//printf("Checking for display...\n");
				int dispConStatus = connect(sockDisplay,
						(struct sockaddr *) &remote, len);
				if (dispConStatus == -1) {
					//printf("No display process found\n");
					pthread_mutex_lock(&daqMutex);
					processStatus = PROCESS;
					pthread_mutex_unlock(&daqMutex);
				} else {
					//printf("Display process found.. Transferring packet\n");
					respServer = NOT_TERMINATE;
					send(sockDisplay, &respServer, sizeof(int), 0);
					send(sockDisplay, txPackDisp,
							sizeof(float) * PACKET_LENGTH * BEAMS * FBINS, 0);
					//usleep(500000);
					pthread_mutex_lock(&daqMutex);
					processStatus = PROCESS;
					pthread_mutex_unlock(&daqMutex);
					//printf("PACKETS TRANSFERRED : %d\n",++packetTransferCount);
				}
				close(sockDisplay);
			}
		}

		pthread_join(threadBF, NULL);
		pthread_join(threadDAQ1, NULL);
		pthread_join(threadDAQ2, NULL);
		pthread_join(threadDAQ3, NULL);
		pthread_join(threadDAQ4, NULL);
		pthread_join(threadDAQ5, NULL);
		pthread_join(threadDAQ6, NULL);
		pthread_join(threadDAQ7, NULL);
		pthread_join(threadDAQ8, NULL);

		pthread_mutex_destroy(&bfmutex);
		pthread_mutex_destroy(&daqMutex);

		/* Tell server that all packets have been transmitted */
		int sockDisplay, len;
		struct sockaddr_un remote;
		if ((sockDisplay = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
			perror("socket");
		}
		remote.sun_family = AF_UNIX;
		strcpy(remote.sun_path, SOCKET_DISPLAY_PATH);
		len = strlen(remote.sun_path) + sizeof(remote.sun_family);
		int dispConStatus = connect(sockDisplay, (struct sockaddr *) &remote,
				len);
		respServer = TERMINATE;
		send(sockDisplay, &respServer, sizeof(int), 0);
		close(sockDisplay);
	}

//Error Handling for incorrect operating mode
	else {

		printf("\n\n       INVALID OPERATION MODE OPTION !!!! \n\n");
		printf(
				"Usage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
				argv[0]);
		printf(
				"Operating_Mode = 0 : Real Time BF processing\nUsage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
				argv[0]);
		printf(
				"Operating_Mode = 1 : Pre-recorded data BF processing\nUsage: %s Operating_Mode Path_to_DAQ_dataset output_file cudaBF\n",
				argv[0]);
		return 1;
	}
	return 0;
}