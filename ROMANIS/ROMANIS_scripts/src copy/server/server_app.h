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

#define N_BUFFERS	   	64	
#define BUFFER_SIZE		1024*1024*8		//in Bytes
#define WRITE_BLOCK		1024*1024		//in Bytes

#define START_CODE		52
#define ACQ_ACK			13

#define WRITE_COMPLETED 	27
#define WRITE_IN_PROGRESS 	54
#define READ_IN_PROGRESS	81
#define READ_COMPLETED 		108



struct DatStruct
{
int DataLen;
unsigned char Status, Done, err;
/*unsigned long*/ char Buffer[BUFFER_SIZE]; //slow access because of volatile
struct DatStruct* next;
};

void *WriteThread(void* pointer);
void dostuff (int sock);

#endif


