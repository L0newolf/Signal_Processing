/*##################################################################################################*/
/*##################################################################################################

THIS IS THE AIO REAL-TIME VERSION.

/*##################################################################################################*/
/*##################################################################################################*/

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

#include "romanisRT.h"
using namespace std;


#define MAX2(x,y)      ((x)<(y) ? (y) : (x))

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

short hSensorData [SENSORS * SAMPLES];
float hBFData[2*FBINS * BEAMS * BLOCKS];

float hostBFO[FBINS * BEAMS * BLOCKS];

short* dSensorData;
float* dBFData;
float *devBFO;
float *dbfoData;

//Struct for pre-recorded beam processing thread parameters
struct beamRecordedArgs {
    char *dataPath;
    char *bfOutputFile;
    };

float bfoData[FRAMES_PER_BLOCK*BEAMS*FBINS];

float *curDispBuf;
int dispBufPtr;
/*========================================================================================*/
/* VARIABLES FOR ROMANIS DAQ SERVER  */
struct DatStruct RomanisDat[NUM_OF_DAQS][N_BUFFERS];

int daqCount[NUM_OF_DAQS];
int daqStatus[NUM_OF_DAQS];
int daqWriteStart[NUM_OF_DAQS];
int startBF = WAIT;

pthread_mutex_t stsMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  stsCond  = PTHREAD_COND_INITIALIZER;
pthread_mutex_t daqMutex = PTHREAD_MUTEX_INITIALIZER;

void error(char *msg) {
    perror(msg);
    exit(1);
    }


/*************************************/

int bfDataCount = 0, totalBF = 0;

//Buffer pointer to store the display-processed beam frames
float frameBuffer[NUM_SQRS];

// Common variables used for data processing and display
int beams,curFrame,dataIdx,fRange,bfoBufPtr,drawBufPtr;
int frameCount = 0;
float cimg[ybeams][xbeams];

float dispBufBank[DISPLAY_BUFS][FRAMES_PER_BLOCK*BEAMS*FBINS];
int disBufStatus[DISPLAY_BUFS];
int disBufFrames[DISPLAY_BUFS];

/*************************************/

/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/

/******** readDAQ() *********************
 There is a separate instance of this function
 for each connection.  It handles all communication
 once a connnection has been established.
 *****************************************/
void* readDAQ (void* pointer) {

    struct threadStruct * threadArgs = (struct threadStruct *) pointer;

    int sock = threadArgs->socket;
    int daqRead = 0;
    char *filename;
    short int i;

    int res,wr;

    struct DatStruct *ptr_0;
    void *buf;
    char start_code=START_CODE,err=0;
    struct sockaddr_in client_addr;
    socklen_t client_len;


    client_len = sizeof(client_addr);
    getpeername(sock, (struct sockaddr*)&client_addr, &client_len);

    switch(client_addr.sin_addr.s_addr & 0xFFFF0000) {
        case 0x0a000000 :
            filename = "DAQ_1";
            daqRead = DAQ1;
            break;
        case 0x0b000000 :
            filename = "DAQ_2";
            daqRead = DAQ2;
            break;
        case 0x0c000000 :
            filename = "DAQ_3";
            daqRead = DAQ3;
            break;
        case 0x0d000000 :
            filename = "DAQ_4";
            daqRead = DAQ4;
            break;

        case 0x0a0a0000 :
            filename = "DAQ_5";
            daqRead = DAQ5;
            break;
        case 0x0b0a0000 :
            filename = "DAQ_6";
            daqRead = DAQ6;
            break;
        case 0x0c0a0000 :
            filename = "DAQ_7";
            daqRead = DAQ7;
            break;
        case 0x0d0a0000 :
            filename = "DAQ_8";
            daqRead = DAQ8;
            break;
        }


    ptr_0 = &RomanisDat[daqRead][0];

    wr = write(sock, &start_code, sizeof(char));

    if(wr<0) {
        printf("Failed to write the start code for %s\n",filename);
        pthread_exit(0);
        }
    daqStatus[daqRead] = READ_IN_PROGRESS;

    while(!(ptr_0->Done)) {

        ptr_0->Status = READ_IN_PROGRESS;

        buf = (void *)&(ptr_0->Buffer);

        while(1) {
            res = read(sock, (buf + ptr_0->DataLen), (BUFFER_SIZE - ptr_0->DataLen));
            if (0 > res) {
                printf("%s: Error Reading from Socket [res= %d]\n", filename, res);
                ptr_0->err = 1;
                goto OUTLOOP;
                }

            if (0 == res) {		//No more data from source
                ptr_0->Done = 1;
                break;
                }

            ptr_0->DataLen += res;

            if (ptr_0->DataLen == BUFFER_SIZE)
                break;
            }


        ptr_0->Status = READ_COMPLETED;
        if(ptr_0->bfStatus == BF_COMPLETED) {
            ptr_0->bfStatus = BF_READY;
            }
        else {

            printf("DAQ BF STATUS CORRUPT  current status : %x , expected status : %x , wanted to change to : %x !!!!\n",ptr_0->bfStatus,BF_COMPLETED,BF_READY );
            }

        daqCount[daqRead]++;

        if(startBF == WAIT) {
            pthread_mutex_lock( &stsMutex );

            if((daqCount[0]*daqCount[1]*daqCount[2]*daqCount[3]*daqCount[4]*daqCount[5]*daqCount[6]*daqCount[7])) {
                startBF = START;
                pthread_cond_signal( &stsCond );
                printf("All DAQs have values ... Signalling beamformer to start processing ... \n");
                }
            pthread_mutex_unlock( &stsMutex );
            }

        if(!ptr_0->Done) {
            ptr_0 = ptr_0->next;
            }
        }



OUTLOOP:

    for(i=0; i<N_BUFFERS; i++) {
        if(RomanisDat[daqRead][i].err) {
            err = 1 ;
            break;
            }
        }

    if(!err)
        printf("%s: Transfer Complete\n",filename);
    daqStatus[daqRead] = READ_COMPLETED;
    pthread_exit(0);
    }

//################################################################################################//

void * daqWrite (void *args) {

    int daqNum = *((int *)args);
    char *filename;
    void *buf_1;
    int snd;
    char *f_path, *base_dir = DATA_FOLDER;
    FILE *fp;
    int totalRead = 0;

    switch(daqNum) {
        case DAQ1 :
            filename = "DAQ_1";
            break;
        case DAQ2 :
            filename = "DAQ_2";
            break;
        case DAQ3 :
            filename = "DAQ_3";
            break;
        case DAQ4 :
            filename = "DAQ_4";
            break;

        case DAQ5 :
            filename = "DAQ_5";
            break;
        case DAQ6 :
            filename = "DAQ_6";
            break;
        case DAQ7 :
            filename = "DAQ_7";
            break;
        case DAQ8 :
            filename = "DAQ_8";
            break;

        default  :
            filename = "DAQ_n";
            break;
        }

    printf("Starting write for %s ...\n",filename );
    f_path = (char *)malloc((strlen(base_dir) + strlen(filename) + 1)*sizeof(char));
    strcpy(f_path, base_dir);
    strcat(f_path, filename);

    fp = fopen(f_path,"w+");
    struct DatStruct *ptr_0;
    ptr_0 = &RomanisDat[daqNum][0];
    int wc = 0,dataLen=0,transfer_bytes=0;
    while(totalRead!=daqCount[daqNum] || daqStatus[daqNum]!= READ_COMPLETED) {

        buf_1 = (void *)&(ptr_0->Buffer);
        wc=0;
        if(ptr_0->Status == READ_COMPLETED) {

            dataLen = ptr_0->DataLen;
            while(dataLen) {
                transfer_bytes = (dataLen > WRITE_BLOCK) ? WRITE_BLOCK : dataLen;
                snd = (int)fwrite((buf_1 + wc),1,transfer_bytes,fp);

                if (snd < 0) {
                    printf("%s: Error Writing to Disk [snd= %d]\n", filename, snd);
                    fclose(fp);
                    free(filename);
                    pthread_exit(0);
                    }
                dataLen -= snd;
                wc += snd;
                }

            totalRead++;
            ptr_0->Status = WRITE_COMPLETED;
            ptr_0 = ptr_0->next;

            }
        else {
            usleep(500);
            }
        }
    fclose(fp);

    printf("File write completed for %s .. \n",filename );
    pthread_exit(0);
    }


//################################################################################################//
/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/


/* initCuda() : Select the GPU to be used and initialize it  */
void initCuda(void) {

    CUT_SAFE_CALL(cudaDeviceReset());
    int dev = cutGetMaxGflopsDeviceId();
    printf("MAX Device ID : %d\n", dev);
    cudaDeviceProp properties;
    cudaGetDeviceProperties(&properties, dev);
    printf("DEIVE NAME : %s\n", properties.name);
    CUT_SAFE_CALL(cudaSetDevice(dev));
    CUT_SAFE_CALL(gpuDeviceInit(dev));
    }

/* checkCudaMem() : Check for available memory in the GPU   */
void checkCudaMem(void) {
    size_t total, avail;
    CUT_SAFE_CALL(cudaMemGetInfo(&avail, &total));
    printf("CUDA Memory: total = %ld, free = %ld\n", total, avail);
    }

/* allocCudaMem() : Allocate memory in the GPU */
void allocCudaMem(void) {
    CUT_SAFE_CALL(cudaMalloc((void**)&dSensorData, sizeof(short)*SENSORS*DFTSIZE*BLOCKS));
    CUT_SAFE_CALL(cudaMalloc((void** )&dBFData, sizeof(hBFData)));
    CUT_SAFE_CALL(cudaMalloc((void** )&dBFRe, sizeof(hBFRe)));
    CUT_SAFE_CALL(cudaMalloc((void** )&dBFIm, sizeof(hBFIm)));
    CUT_SAFE_CALL(cudaMalloc((void** )&devBFO, sizeof(hostBFO)));
    CUT_SAFE_CALL(cudaMalloc((void** )&dbfoData, sizeof(bfoData)));
    }

/* shutdown() : Free up GPU memory and reset GPU  */
void shutdown(void) {
    CUT_SAFE_CALL(cudaFree(dBFRe));
    CUT_SAFE_CALL(cudaFree(dBFIm));
    CUT_SAFE_CALL(cudaFree(dBFData));
    CUT_SAFE_CALL(cudaFree(dSensorData));
    CUT_SAFE_CALL(cudaFree(devBFO));
    CUT_SAFE_CALL(cudaFree(dbfoData));
    CUT_SAFE_CALL(cudaDeviceReset());
    }

/* initDFT() : Initialize the DFT arrays  */
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

/* initBF() : Initialize the beamformer arrays  */
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
    CUT_SAFE_CALL(cudaMemcpy(dBFRe, hBFRe, sizeof(hBFRe), cudaMemcpyHostToDevice));
    CUT_SAFE_CALL(cudaMemcpy(dBFIm, hBFIm, sizeof(hBFIm), cudaMemcpyHostToDevice));
    }

/* readScale() : Read calibration of sensors  */
void readScale() {

    FILE* fh = fopen("calib.txt", "rt");
    if (fh == NULL) {
        printf("Sensor calibration not available\n");
        for (int i = 0; i < SENSORS; i++)
            hScale[i] = 1;
        }
    else {
        for (int i = 0; i < SENSORS; i++) {
            float s, o;
            fscanf(fh, "%f %f", &s, &o);
            hScale[i] = s;
            }
        fclose(fh);
        }
    CUT_SAFE_CALL(cudaMemcpyToSymbol(dScale, hScale, sizeof(hScale)));
    }


/* process() : beam-former CUDA kernel  */

__global__ void process(short* dataIn, float* dataOut, float* dBFRe,float* dBFIm,float *devBFO) {
    __shared__ float re[SENSORS];
    __shared__ float im[SENSORS];
    int f = blockIdx.x;
    int n = blockIdx.y;
    int s = threadIdx.x;

    int offSet1,offSet2;

    if (s < SENSORS) {
        float sumRe = 0;
        float sumIm = 0;
        offSet1 = f * DFTSIZE;
        offSet2 = n * DFTSIZE*SENSORS;

        for (int i = 0; i < DFTSIZE; i++) {
            sumRe += dDFTCos[offSet1 + i]* dataIn[offSet2 + s];
            sumIm += dDFTSin[offSet1 + i]* dataIn[offSet2 + s];
            offSet2+=SENSORS;
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
        offSet1 = f * SENSORS* BEAMS;
        for (int i = start; i < start + SENSORS / BEAMBLKS; i++) {
            int tn = offSet1 + b;
            float tr = re[i] * dBFRe[tn] - im[i] * dBFIm[tn];
            float ti = im[i] * dBFRe[tn] + re[i] * dBFIm[tn];
            sumRe += tr;
            sumIm += ti;
            offSet1+=BEAMS;
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

    __syncthreads();
    int b = s % BEAMS;
    int outndx2 = 2 * ((n * BEAMS + b) * FBINS + f);
    //devBFO[outndx2/2] = sqrt(pow(dataOut[outndx2],2)+pow(dataOut[outndx2 + 1],2));
    devBFO[outndx2/2] = (fabs(dataOut[outndx2])+fabs(dataOut[outndx2 + 1]))/2;

    }

/* ###################################################################################*/
/* ###################################################################################*/
template <typename T>
std::string to_string(T value) {
    std::ostringstream os ;
    os << value ;
    return os.str() ;
    }


// Initializes all the parameters and variables
void initVars() {
    fRange = freqBinUpper-freqBinLower+1;
    beams = ybeams*xbeams*fbins;
    curFrame = 0;
    //intialize the cimg array to all zeros
    for(int y=0; y<ybeams; y++) {
        for(int x=0; x<xbeams; x++) {
            cimg[y][x]=0.0f;
            }
        }
    dataIdx = 0;

    for(int i=0; i<DISPLAY_BUFS; i++) {
        for(int j=0; j<FRAMES_PER_BLOCK*BEAMS*FBINS; j++) {
            dispBufBank[i][j] = 0.0;
            }
        disBufStatus[i] = HOLD;
        }

    //Initialization
    for(int d=0; d<NUM_OF_DAQS; d++) {
        for(int i=0; i<N_BUFFERS; i++) {
            RomanisDat[d][i].err = 0;
            RomanisDat[d][i].DataLen = 0;
            RomanisDat[d][i].Status = WRITE_COMPLETED;
            RomanisDat[d][i].bfStatus = BF_COMPLETED;
            RomanisDat[d][i].Done = 0;
            if((N_BUFFERS-1) == i)
                RomanisDat[d][i].next = (struct DatStruct*)&RomanisDat[d][0];
            else
                RomanisDat[d][i].next = (struct DatStruct*)&RomanisDat[d][i+1];
            }
        }

    dispBufPtr = 0;
    }
/* ###################################################################################*/
/* ###################################################################################*/
// Interpolation Function
float interpolate (float in[ybeams][xbeams], float out[ybeamsInt][xbeamsInt]) {

    float xStep,yStep;
    float maxVal = 0.0;
    /* Fill all first rows */
    for(int j=0; j<ybeams; j++) {
        for(int i = 0; i<xbeams-1; i++) {
            xStep = (in[j][i+1] - in[j][i])/(INTERPOLATION_FACTOR);
            out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i] = in[j][i];
            for(int k=1; k<INTERPOLATION_FACTOR; k++) {
                out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i+k] = in[j][i] + k*xStep;
                if (maxVal<out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i+k])
                    maxVal = out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i+k];
                }
            }
        out[INTERPOLATION_FACTOR*j][xbeamsInt-1] = in[j][xbeams-1];
        if (maxVal<out[INTERPOLATION_FACTOR*j][xbeamsInt-1])
            maxVal = out[INTERPOLATION_FACTOR*j][xbeamsInt-1];
        }

    /* Fill up all the clomuns */
    for(int i=0; i<ybeams-1; i++) {
        for(int j=0; j<xbeamsInt; j++) {
            yStep = (out[INTERPOLATION_FACTOR*(i+1)][j] - out[INTERPOLATION_FACTOR*i][j])/INTERPOLATION_FACTOR;
            for(int k=1; k<INTERPOLATION_FACTOR; k++) {
                out[INTERPOLATION_FACTOR*i+k][j] = out[INTERPOLATION_FACTOR*i][j] + k*yStep;
                if (maxVal<out[INTERPOLATION_FACTOR*i+k][j])
                    maxVal = out[INTERPOLATION_FACTOR*i+k][j];

                }
            }
        }

    return 20*log10(maxVal);
    }
/* ###################################################################################
                    Beamformer Output Processing
   ################################################################################### */

void preprocBF(float *hBFData,float *bfoData, int framesToDraw ) {


    float bfoFrameAvg[FrameSize][beams];
    float bfoSum = 0.0;

    int k;
    int dataCount = 0;

    for(k=0; k<framesToDraw; k++) {

        int i,j;
        for( i=0; i<beams; i++) {
            bfoSum = 0.0;
            for( j=0; j<FrameSize; j++) {
                bfoSum += hBFData[FrameSize*beams*k+beams*j+i];
                }
            bfoData[beams*k+i] = bfoSum/FrameSize;
            }

        }
    }

__global__ void preProcBF(float *dataIn, float *dataOut) {

    int dataPtr = threadIdx.x * FBINS*BEAMS*FRAMESIZE;
    int dataOutPtr = threadIdx.x * FBINS*BEAMS;
    float *threadBuf = dataIn + dataPtr;
    int i,j,dataCount = 0;;
    float bfoSum;

    for( i=0; i<FBINS*BEAMS; i++) {
            bfoSum = 0.0;
            dataCount = i;
            for( j=0; j<FRAMESIZE; j++) {
                bfoSum += threadBuf[dataCount];
                dataCount+=BEAMS*FBINS;
                }
            dataOut[dataOutPtr+i] = bfoSum/FRAMESIZE;
            }

    }

void processBF(float *bfOutput) {

    float sum,maxVal;
    float beamFrames[xbeams][ybeams][fbins];
    float frameFreqAvg[xbeams][ybeams];
    float cimgInt[ybeamsInt][xbeamsInt];
    int bufIdx = 0;
    int dynAdd;

    sum =0;
    maxVal = 0;

//Select the frames in blocks of Framesize,Average out the frames over the desired frequency range

    for(int y=ybeams-1; y>-1; y--) {
        for(int x=xbeams-1; x>-1; x--) {

            //dataIdx += FBINS*BEAMS*(freqBinLower-1);
            for(int f=0; f<fbins; f++) {
                beamFrames[x][y][f] = bfOutput[dataIdx];
                dataIdx++;
                }
            sum = 0.0f;
            for(int f=freqBinLower-1; f<freqBinUpper; f++) {
                sum += beamFrames[x][y][f];
                }
            frameFreqAvg[x][y] = sum/fRange;
            cimg[y][x] = ExpAvg*cimg[y][x] + (1.0-ExpAvg)*(sum/fRange);
            }
        }


//Interpolate cimg
    maxVal = interpolate(cimg,cimgInt);
    dynAdd = -maxVal+DynRange;

//Take log of interpolated cimg and do dynamic ranging
float temp;
    for(int y=0; y<ybeamsInt; y++) {
        for(int x=0; x<xbeamsInt; x++) {
            temp = (20*log10(cimgInt[y][x])+dynAdd)/DynRange;
            if(temp<0)
                frameBuffer[y*xbeamsInt + x +y-2] = 0.0;
            else if(temp>1.0)
                frameBuffer[y*xbeamsInt + x +y-2] = 63.0;
            else
                frameBuffer[y*xbeamsInt + x +y-2] = 63.0*temp;
            }
        }
    }

/******************BEAM PROCESSING FOR PRE-RECORDED DATA SET********************************************/
void * beamProcess(void *args) {

    printf("Starting beam-forming .... \n");

    int hinCount;

    int i=0,blks;
    int samples = 0;

    int rounds = 0;

    int offSet = 0;

    readScale();

    initCuda();
    checkCudaMem();
    initSensors();
    allocCudaMem();
    checkCudaMem();
    initDFT();
    initBF();

    struct DatStruct *ptr_daq1 = &RomanisDat[DAQ1][0];
    struct DatStruct *ptr_daq2 = &RomanisDat[DAQ2][0];
    struct DatStruct *ptr_daq3 = &RomanisDat[DAQ3][0];
    struct DatStruct *ptr_daq4 = &RomanisDat[DAQ4][0];
    struct DatStruct *ptr_daq5 = &RomanisDat[DAQ5][0];
    struct DatStruct *ptr_daq6 = &RomanisDat[DAQ6][0];
    struct DatStruct *ptr_daq7 = &RomanisDat[DAQ7][0];
    struct DatStruct *ptr_daq8 = &RomanisDat[DAQ8][0];

    bfDataCount = 0;
    totalBF = 0;
    printf("Beam-former Initialized ... Start DAQ accquisition ... \n");

    pthread_mutex_lock( &stsMutex );
    while( startBF != START ) {
        pthread_cond_wait( &stsCond, &stsMutex );
        }
    pthread_mutex_unlock( &stsMutex );

    printf("Starting beam-forming process ..... \n");
    while(1) {
        samples = 0;

        if(ptr_daq1->bfStatus == BF_READY && ptr_daq3->bfStatus == BF_READY && ptr_daq5->bfStatus == BF_READY && ptr_daq7->bfStatus == BF_READY &&
                ptr_daq2->bfStatus == BF_READY && ptr_daq4->bfStatus == BF_READY && ptr_daq6->bfStatus == BF_READY && ptr_daq8->bfStatus == BF_READY ) {


            for(int daq=0; daq<NUM_OF_DAQS; daq++) {

                int n = (RomanisDat[daq][totalBF].DataLen - offSet)/( (64 * sizeof(short) + 4));
                if(daq==0)
                    samples = n;
                else if (n < samples)
                    samples = n;
                }

            int daqPtr = offSet/2 ,bufPtr = 0;

            short *curBuf;

            for (int j = 0; j < 0.75*samples; j++) {

                daqPtr+=2;

                curBuf = ptr_daq1->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq2->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq3->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq4->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq5->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq6->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq7->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,64*sizeof(short));
                bufPtr+=64;

                curBuf = ptr_daq8->Buffer + offSet;
                memcpy(hSensorData+bufPtr,curBuf+daqPtr,60*sizeof(short));
                bufPtr+=60;

                daqPtr+=64;

				if(j%4 == 0) daqPtr+=66;

                }

            offSet = 132 - ((RomanisDat[0][totalBF].DataLen - offSet) % (64 * sizeof(short) + 4));


            i = 0;

            while (i < samples) {
                blks = (samples - i) / DFTSIZE;
                if (blks > BLOCKS)
                    blks = BLOCKS;

                CUT_SAFE_CALL(cudaMemcpy(dSensorData, hSensorData+SENSORS*i, DFTSIZE*SENSORS*blks*sizeof(short), cudaMemcpyHostToDevice));
                dim3 threads(MAX2(SENSORS,BEAMS*BEAMBLKS));
                dim3 grid(FBINS, blks);
                process<<<grid, threads>>>(dSensorData, dBFData, dBFRe, dBFIm,devBFO);


                dim3 threads1(blks/FRAMESIZE);
                dim3 grid1(1, 1);
                preProcBF<<<grid1, threads1>>>(devBFO, dbfoData);
                CUT_SAFE_CALL(cudaMemcpy(bfoData, dbfoData, sizeof(bfoData),cudaMemcpyDeviceToHost));

                for(int j=0; j<(blks/FRAMESIZE)*BEAMS*FBINS; j++)
                    dispBufBank[bfDataCount%DISPLAY_BUFS][j] = bfoData[j];
                disBufFrames[bfDataCount%DISPLAY_BUFS] = blks/FRAMESIZE;
                disBufStatus[bfDataCount%DISPLAY_BUFS] = DRAW;
                bfDataCount++;


                i += DFTSIZE * BLOCKS;

                }

            totalBF++;
            int nextBuf = totalBF%N_BUFFERS;

            ptr_daq1->bfStatus = BF_COMPLETED;
            ptr_daq1 = &RomanisDat[DAQ1][nextBuf];
            ptr_daq3->bfStatus = BF_COMPLETED;
            ptr_daq3 = &RomanisDat[DAQ2][nextBuf];
            ptr_daq5->bfStatus = BF_COMPLETED;
            ptr_daq5 = &RomanisDat[DAQ3][nextBuf];
            ptr_daq7->bfStatus = BF_COMPLETED;
            ptr_daq7 = &RomanisDat[DAQ4][nextBuf];
            ptr_daq2->bfStatus = BF_COMPLETED;
            ptr_daq2 = &RomanisDat[DAQ5][nextBuf];
            ptr_daq4->bfStatus = BF_COMPLETED;
            ptr_daq4 = &RomanisDat[DAQ6][nextBuf];
            ptr_daq6->bfStatus = BF_COMPLETED;
            ptr_daq6 = &RomanisDat[DAQ7][nextBuf];
            ptr_daq8->bfStatus = BF_COMPLETED;
            ptr_daq8 = &RomanisDat[DAQ8][nextBuf];


            }
        //Exit condition
        else if(totalBF==daqCount[DAQ1] && daqStatus[DAQ1]== READ_COMPLETED) {
            printf("BF completed ... \n");
            break;
            }
        else {
            usleep(500);
            }
        }

    shutdown();
    printf("Total data blocks processed in BF : %d\n",totalBF);
    printf("Total blocks sent to display : %d\n",bfDataCount);
    pthread_exit(0);
    }
/**********************************************************************************************/

/* ###################################################################################
					Beamformer Display using OpenGL
   ################################################################################### */

void printText(int x, int y, string textDisplay) {

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, WIN_WIDTH, 0, WIN_HEIGHT, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    glPushAttrib(GL_DEPTH_TEST);
    glDisable(GL_DEPTH_TEST);
    glRasterPos2i(x,y);
    for (int i=0; i<textDisplay.size(); i++) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, textDisplay[i]);
        }
    glPopAttrib();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    }

void displayMsg() {

    //Set Colour to white
    glColor3f(1.0,1.0,1.0);
    string textDisplay;

    //Display all option parameters
    textDisplay="Current Lower Frequency Bin : "+to_string(freqBinLower);
    printText(10,7,textDisplay);
    textDisplay="Current Lower Frequency Bin : "+to_string(freqBinUpper);
    printText(10,24,textDisplay);
    textDisplay="Current Dynamic Range Limit : "+to_string(DynRange);
    printText(10,41,textDisplay);

    //Display guide to change values of the parameters
    textDisplay="Press UP key to raise and  DOWN key to lower the Lower Frequency Bin limit";
    printText(270,41,textDisplay);
    textDisplay="Press RIGHT key to raise and LEFT key to lower the Upper Frequency Bin limit";
    printText(270,24,textDisplay);

    //Display Cloour bar text
    textDisplay="Colour Bar for Signal Strength  : ";
    printText(10,115,textDisplay);

    //Display color bar values
    textDisplay="  0               10               20               30               40                50               60               70                 80 ";
    printText(30,80,textDisplay);

    //Display azimuthal angle values
    textDisplay="-8.8 -7.2  -6.4  -5.6  -4.8  -4.0  -3.2  -2.4  -1.6  -0.8   0.0   0.8   1.6   2.4   3.2    4.0   4.8   5.6   6.4   7.2   8.0   8.8";
    printText(25,165,textDisplay);
    textDisplay="Azimuthal";
    printText(320,150,textDisplay);

    //Display Elevation angle values
    textDisplay="-4.0";
    printText(10,180,textDisplay);
    textDisplay="-3.2";
    printText(10,213.5,textDisplay);
    textDisplay="-2.4";
    printText(10,247,textDisplay);
    textDisplay="-1.6";
    printText(10,280.5,textDisplay);
    textDisplay="-0.8";
    printText(10,314,textDisplay);
    textDisplay="0.0";
    printText(15,347.5,textDisplay);
    textDisplay="0.8";
    printText(15,381,textDisplay);
    textDisplay="1.6";
    printText(15,414.5,textDisplay);
    textDisplay="2.4";
    printText(15,448,textDisplay);
    textDisplay="3.2";
    printText(15,481.5,textDisplay);
    textDisplay="4.0";
    printText(15,515,textDisplay);

    //Display "Elevation" as text
    textDisplay="E";
    printText(700,420,textDisplay);
    textDisplay="l";
    printText(700,405,textDisplay);
    textDisplay="e";
    printText(700,390,textDisplay);
    textDisplay="v";
    printText(700,375,textDisplay);
    textDisplay="a";
    printText(700,360,textDisplay);
    textDisplay="t";
    printText(700,345,textDisplay);
    textDisplay="i";
    printText(700,330,textDisplay);
    textDisplay="o";
    printText(700,315,textDisplay);
    textDisplay="n";
    printText(700,300,textDisplay);


    }
//! Create a timer event for refresh
void timerEvent(int value) {
    if(disBufStatus[dispBufPtr] == DRAW) {
        updateFrame();
        glutPostRedisplay();
        }
    glutTimerFunc(refreshDelay, timerEvent, 0);
    }

void genVerticesDisplay() {

    int i;
    int x=0;
    int y=0;
    int clr;
    float xcords[xPoints];
    float ycords[yPoints];

    int clrPtr;
    float xstep = (2*xLim)/(float)(xPoints-1);
    float ystep = (2*yLim)/(float)(yPoints-1);

    for(i=0; i<xPoints; i++)
        xcords[i] = -xLim + i*xstep;

    for(i=0; i<yPoints; i++)
        ycords[i] = -yLim + i*ystep+yOffset;

    clrPtr = 0;

    for (i=0; i<NUM_SQRS; i++) {
        if (x==xPoints-1) {
            x=0;
            y=y+1;
            }

        clr = (int)(frameBuffer[clrPtr]/2.0);
        if (clr < MAX_COLOURS)
            glColor3f(accousColor[clr][0],accousColor[clr][1],accousColor[clr][2]);
        else
            glColor3f(accousColor[MAX_COLOURS-1][0],accousColor[MAX_COLOURS-1][1],accousColor[MAX_COLOURS-1][2]);

        glVertex3f(xcords[x], ycords[y], 0.0);
        glVertex3f(xcords[x+1], ycords[y], 0.0);
        glVertex3f(xcords[x+1],  ycords[y+1], 0.0);
        glVertex3f( xcords[x], ycords[y+1], 0.0);

        x+=1;
        clrPtr+=1;

        }

    //Draw the colour bar
    x=0;
    float yColorBar[] = {-0.65,-0.6};
    int curColour = 0;
    int drawCnt = 0;

    for(i=0; i<4*xPoints; i+=4) {

        glColor3f(accousColor[curColour][0],accousColor[curColour][1],accousColor[curColour][2]);
        glVertex3f(xcords[x], yColorBar[0], 0.0);
        glVertex3f(xcords[x+1], yColorBar[0], 0.0);
        glVertex3f(xcords[x+1],  yColorBar[1], 0.0);
        glVertex3f( xcords[x], yColorBar[1], 0.0);

        drawCnt+=1;
        if(drawCnt % 5 == 0)
            curColour++;

        x+=1;
        }


    }

void fpsDisplay() {
    char fps[64];
    curTime = (float)frameCount*timePerFrame;
    sprintf(fps, "ROMANIS RT DISPLAY  Current Time : %0.3f  Frame Number : %d",curTime,frameCount);
    glutSetWindowTitle(fps);
    }

void display(void) {

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glClear( GL_COLOR_BUFFER_BIT);

    glShadeModel(GL_SMOOTH);
    glBegin(GL_QUADS);

    genVerticesDisplay();

    glEnd();
    glFlush();

    displayMsg();

    fpsDisplay();

    frameCount++;
    curFrame++;
    glutSwapBuffers();



    }

void special(int key, int x, int y) {
    switch (key) {
        case GLUT_KEY_LEFT:
            if(freqBinUpper > freqBinLower)
                freqBinUpper--;
            break;
        case GLUT_KEY_RIGHT:
            if(freqBinUpper<FBINS-1)
                freqBinUpper++;
            break;
        case GLUT_KEY_UP:
            if(freqBinLower<freqBinUpper)
                freqBinLower++;
            break;
        case GLUT_KEY_DOWN:
            if(freqBinLower>0)
                freqBinLower--;
            break;
        }

    glutPostRedisplay();
    }

void drawFrame(int argc, char *argv[]) {

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
    glutInitWindowSize(WIN_WIDTH, WIN_HEIGHT);
    glutInitWindowPosition(0, 0);

    glutCreateWindow("ROMANIS BEAM VISULISATION ");

    glutTimerFunc(refreshDelay, timerEvent, 0);
    glutDisplayFunc(display);
    glutSpecialFunc(special);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glutMainLoop();
    }


void * startDraw(void *args) {

    char fakeParam[] = "fake";
    char *fakeargv[] = { fakeParam, NULL };
    int fakeargc = 1;
    initVars();
    drawFrame(fakeargc,fakeargv);

    pthread_exit(0);
    }

void updateFrame() {


    if(curFrame == disBufFrames[dispBufPtr] && frameCount!=0) {
        dataIdx = 0;
        curFrame = 0;
        memset(&dispBufBank[dispBufPtr][0],0.0,(FRAMES_PER_BLOCK*BEAMS*FBINS)*sizeof(float));
        disBufStatus[dispBufPtr] = HOLD;
        dispBufPtr++;
        if(dispBufPtr == DISPLAY_BUFS ) dispBufPtr = 0;

        }

    curDispBuf = &dispBufBank[dispBufPtr][0];

    processBF(curDispBuf);

    }
/* ###################################################################################
					 Main function
   ################################################################################### */
int main(int argc, char* argv[]) {

    initVars();
    int sockfd, newsockfd[NUM_OF_DAQS], portno;
    struct sockaddr_in serv_addr, cli_addr;
    socklen_t clilen;

    if (argc < 2) {
        fprintf(stderr,"ERROR, no port provided\n");
        exit(1);
        }
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0)
        error("ERROR opening socket");
    bzero((char *) &serv_addr, sizeof(serv_addr));
    portno = atoi(argv[1]);
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(portno);
    if (bind(sockfd, (struct sockaddr *) &serv_addr,
             sizeof(serv_addr)) < 0)
        error("ERROR on binding");
    listen(sockfd,5);
    clilen = sizeof(cli_addr);
    signal(SIGCHLD,SIG_IGN);

    printf("\n");
    system("date;");

    int i;
    for(i=0; i<NUM_OF_DAQS; i++) {
        daqCount[i] = 0;
        daqWriteStart[i] = i;
        }

    pthread_t threadDAQ[NUM_OF_DAQS],threadWrite[NUM_OF_DAQS],threadBF;

    struct threadStruct daq[NUM_OF_DAQS];
    int daqNum = 0;

    printf("Launching BF thread now ... \n");
    pthread_create(&threadBF,NULL,beamProcess,(void *)&startBF);
    

    pthread_attr_t attrDAQ;
    pthread_attr_init(&attrDAQ);
    pthread_attr_setscope(&attrDAQ,PTHREAD_SCOPE_SYSTEM);

    while (daqNum < NUM_OF_DAQS) {
        newsockfd[daqNum] = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);

        if (newsockfd[daqNum] < 0)
            error("ERROR on accept");
        else {

            daq[daqNum].socket = newsockfd[daqNum];
            daq[daqNum].daqNum = daqNum;

            pthread_create(&threadWrite[daqNum],NULL,daqWrite,(void *)&daqWriteStart[daqNum]);
            pthread_create(&threadDAQ[daqNum],&attrDAQ,readDAQ,(void *)&daq[daqNum]);

            daqNum++;
            }
        } /* end of while */
        
    pthread_t threadDraw;
    void *dummy = 0x0000;
    pthread_create(&threadDraw,NULL,startDraw,dummy);
        
    pthread_attr_destroy(&attrDAQ);

    pthread_join(threadDAQ[0],NULL);
    pthread_join(threadDAQ[1],NULL);
    pthread_join(threadDAQ[2],NULL);
    pthread_join(threadDAQ[3],NULL);
    pthread_join(threadDAQ[4],NULL);
    pthread_join(threadDAQ[5],NULL);
    pthread_join(threadDAQ[6],NULL);
    pthread_join(threadDAQ[7],NULL);


    pthread_join(threadWrite[0],NULL);
    pthread_join(threadWrite[1],NULL);
    pthread_join(threadWrite[2],NULL);
    pthread_join(threadWrite[3],NULL);
    pthread_join(threadWrite[4],NULL);
    pthread_join(threadWrite[5],NULL);
    pthread_join(threadWrite[6],NULL);
    pthread_join(threadWrite[7],NULL);

    pthread_join(threadBF,NULL);

    printf("Real Time Processing completed ... Please close display window to exit .... \n");

    pthread_join(threadDraw,NULL);

    return 0;

    }
