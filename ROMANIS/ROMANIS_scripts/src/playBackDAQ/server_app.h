////////////////////////////////////////////////////////////////////////////////////////////
//			*** ACOUSTIC RESEARCH LABORATORY CONFIDENTIAL***		  //
// 											  //
//	The information contained in this file remains the property of Acoustic Research  //
// Laboratory, National University Of Singapore. The information is of use for internal   //
// evaluation, operation and/or maintenence purposes within the ARL only. Without prior   //
// written consent of an authorised representative of ARL, you may not reproduce,         //
// represent, or download through any means.						  //
//											  //
////////////////////////////////////////////////////////////////////////////////////////////

/*========================================================================================
File	: server_app.c
----------------------------
Project	: ANI-II
----------------------------
Module	: Multi-buffer Server Application header file
----------------------------
CPU	: CPU	: Intel, Dell PowerEdge-T710 Server

File Description:-


Procedure:-


File History:-
-------------------------------------------------------------------------------------------
|03/19/2010|	V1.0	|	AMOGH R	|  Created Source File...
==========================================================================================*/

#ifndef SERVER_APP_H
#define SERVER_APP_H

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <signal.h>

#include <sched.h>

#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#define N_BUFFERS	   	256
#define BUFFER_SIZE		1024*1024*8		//in Bytes
#define WRITE_BLOCK		1024*1024		//in Bytes

#define START_CODE		52
#define ACQ_ACK			13

#define WRITE_COMPLETED 	27
#define READ_COMPLETED 		108
#define READ_IN_PROGRESS    216

#define BF_COMPLETED 	    0x00ff
#define BF_READY            0x00aa

#define NUM_OF_DAQS 8

#define DAQ1 0
#define DAQ2 1
#define DAQ3 2
#define DAQ4 3
#define DAQ5 4
#define DAQ6 5
#define DAQ7 6
#define DAQ8 7

#define DATA_FOLDER "/home/arl/ROMANIS_RECORD/ext/"

#define START 0
#define WAIT 1

#define SAMPLES 63550

struct DatStruct
{
int DataLen;
unsigned char Status, Done, err,bfStatus;
short Buffer[BUFFER_SIZE/2];//char Buffer[BUFFER_SIZE]; //slow access because of volatile
struct DatStruct* next;
};

struct threadStruct{

	int socket;
	int daqNum;
};

void *readDAQ(void* pointer);
void * daqWrite (void *args);


/*========================================================================================*/
/* INCLUDES AND DEFINITIONS FOR BEAM-FORMER */

// includes, system
#include <math.h>

// includes, cuda
#include <cuda_runtime.h>

// Utilities and timing functions
#include <helper_functions.h>    // includes cuda.h and cuda_runtime_api.h
#include <timer.h>               // timing functions
// CUDA helper functions
#include <helper_cuda.h>         // helper functions for CUDA error check
#include <vector_types.h>

#include "colourBar.h"
#include "sensors.h"

#define PI            3.1415926535897932385
#define SOUNDSPEED    1540.0
#define FBIN0         9
#define FBINS         23
#define DFTSIZE       64
#define FILES         8
#define RATE          196000
#define BLOCKS        1024
#define EBEAMS        12
#define ABEAMS        24
#define BEAMSPC       (0.8*PI/180)
#define BEAMS         (EBEAMS*ABEAMS)
#define BEAMBLKS      2

#define TERMINATE 1
#define NOT_TERMINATE 0

#define TRANSFER 0
#define PROCESS 1
#define COMPLETE 2

#define FRAMESIZE 32

#define FRAMES_PER_BLOCK BLOCKS/FRAMESIZE

#define MAX2(x,y)      ((x)<(y) ? (y) : (x))


//Macros for CUDA 5.5 compatibility
#define CUT_SAFE_CALL(x) checkCudaErrors((cudaError_t)x)
#define cutGetMaxGflopsDeviceId() gpuGetMaxGflopsDeviceId()


/*========================================================================================*/
/*========================================================================================*/

#include <iostream>
#include <cstdio>
#include <string>
#include <sstream>
#include <cstdlib>
#include <math.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <pthread.h>

//OpenGL specific includes
#include <GL/glew.h>
#include <GL/glut.h>


#define xbeams 24
#define ybeams 12
#define fbins 23

#define Fs 196032

#define INTERPOLATION_FACTOR 9

#define ybeamsInt  (ybeams-1)*INTERPOLATION_FACTOR +1
#define xbeamsInt  (xbeams-1)*INTERPOLATION_FACTOR +1

struct complexNum {
     float real;
     float imag;
};

#define yOffset 0.3
#define xLim 0.9
#define yLim 0.65

#define xPoints (xbeams-1)*INTERPOLATION_FACTOR + 2
#define yPoints (ybeams-1)*INTERPOLATION_FACTOR + 2

#define NUM_SQRS (xPoints-1)*(yPoints-1) //208*100

#define WIN_HEIGHT 540
#define WIN_WIDTH 730

#define refreshDelay 50

#define timePerFrame 0.01046

#define MAX_COLOURS 42

#define DISPLAY_BUFS 4096

#define HOLD 128
#define DRAW 256

void genVerticesDisplay();
void updateFrame();

//Default User Options
int FrameSize = 32;
int freqBinLower = 5;
int freqBinUpper = 15;
float ExpAvg = 0.9;
float DynRange = 12.0;
float curTime = 0;
#endif


