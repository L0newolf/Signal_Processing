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
Module	: Multi-buffer Server Application for ROMANIS II data acquisition (DAQ external clock)
----------------------------
CPU	: CPU	: Intel, Dell PowerEdge-T710 Server

File Description:-
	This Program recieves acquired data (sampled with external clock) from the remote DAQ clients and writes to the local hard-disk on the server

Procedure:-
       1. Run "make all" to compile this file from the local folder
       2. Syntax for calling this program is "./server_app_ext <port_no>"

File History:-
-------------------------------------------------------------------------------------------
|03/19/2010|	V1.0	|	AMOGH R	|  Created Source File...
==========================================================================================*/


#include "server_app.h"

#define DATA_FOLDER "/home/arl/ROMANIS/ext/"

volatile struct DatStruct RomanisDat[N_BUFFERS];
pthread_mutex_t sts_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  sts_cond  = PTHREAD_COND_INITIALIZER;

//unsigned long long acq_time_0 = 0;

void error(char *msg) {
    perror(msg);
    exit(1);
    }


/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/
/*------------------------------------------------------------------------------------------------*/
int main(int argc, char *argv[]) {
    int sockfd, newsockfd, portno, pid;
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
    while (1) {
        newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);

        if (newsockfd < 0)
            error("ERROR on accept");
        pid = fork();
        if (pid < 0)
            error("ERROR on fork");
        if (pid == 0) {
            close(sockfd);
            dostuff(newsockfd);
            exit(EXIT_SUCCESS);
            }
        else close(newsockfd);
        } /* end of while */
    return 0; /* we never get here */
    }


/******** DOSTUFF() *********************
 There is a separate instance of this function
 for each connection.  It handles all communication
 once a connnection has been established.
 *****************************************/
void dostuff (int sock) {
    pthread_t w_thread;
    short int i;
    int iret;
    int res, wr;
    //unsigned long long acq_time = acq_time_0;
    volatile struct DatStruct *ptr_0;
    void *buf;
    char start_code=START_CODE, /*acq_ack=0,*/ err=0;
    struct sockaddr_in client_addr;
    socklen_t client_len;
    char *filename;

    client_len = sizeof(client_addr);
    getpeername(sock, (struct sockaddr*)&client_addr, &client_len);
    //filename = inet_ntoa(client_addr.sin_addr);


    switch(client_addr.sin_addr.s_addr & 0xFFFF0000) {
        case 0x0a000000 :
            filename = "DAQ_1";
            break;
        case 0x0b000000 :
            filename = "DAQ_2";
            break;
        case 0x0c000000 :
            filename = "DAQ_3";
            break;
        case 0x0d000000 :
            filename = "DAQ_4";
            break;

        case 0x0a0a0000 :
            filename = "DAQ_5";
            break;
        case 0x0b0a0000 :
            filename = "DAQ_6";
            break;
        case 0x0c0a0000 :
            filename = "DAQ_7";
            break;
        case 0x0d0a0000 :
            filename = "DAQ_8";
            break;

        default  :
            filename = "DAQ_n";
            break;
        }


    ptr_0 = &RomanisDat[0];

    //Initialization
    for(i=0; i<N_BUFFERS; i++) {
        RomanisDat[i].err = 0;
        RomanisDat[i].DataLen = 0;
        RomanisDat[i].Status = WRITE_COMPLETED;
        RomanisDat[i].Done = 0;
        if((N_BUFFERS-1) == i)
            RomanisDat[i].next = (struct DatStruct*)&RomanisDat[0];
        else
            RomanisDat[i].next = (struct DatStruct*)&RomanisDat[i+1];
        }

    iret = pthread_create( &w_thread, NULL, WriteThread,(void *)filename);

    wr = write(sock, &start_code, sizeof(char));
    if(wr >0) printf ("%s: Start_code written\n", filename);
    else printf("%s: Start Error!!\n", filename);

    /*read() loop*/
    while(!(ptr_0->Done)) {
        pthread_mutex_lock( &sts_mutex );
        while( ptr_0->Status != WRITE_COMPLETED ) {
            pthread_cond_wait( &sts_cond, &sts_mutex );
            }
        pthread_mutex_unlock( &sts_mutex );

        ptr_0->Status = READ_IN_PROGRESS;

        buf = &(ptr_0->Buffer);
        /*read() code...*/
        while(1) {
            res = read(sock, (buf + ptr_0->DataLen), (BUFFER_SIZE - ptr_0->DataLen));
            if (0 > res) {
                printf("%s: Error Reading from Socket [res= %d]\n", filename, res);
                ptr_0->err = 1;
                //close(sock);
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

        pthread_mutex_lock( &sts_mutex );
        if(READ_COMPLETED == ptr_0->Status) {
            pthread_cond_signal( &sts_cond );
            }
        pthread_mutex_unlock( &sts_mutex );

        if(!ptr_0->Done) {
            ptr_0 = ptr_0->next;
            }
        }

OUTLOOP:
    pthread_join( w_thread, NULL);

    for(i=0; i<N_BUFFERS; i++) {
        if(RomanisDat[i].err) {
            err = 1 ;
            break;
            }
        }

    if(!err)
        printf("%s: Transfer Complete\n",filename);

    system("date;");
    }


/************* WriteThread() ****************
  Thread for writing buffered data to file.
  Runs in parallel with the read to buffer
  operation in dostuff().
*********************************************/
void *WriteThread(void* pointer) {
    int snd, fp, transfer_bytes = 0, wc = 0;
    volatile struct DatStruct *ptr;
    void *buf_1;
    char *f_path, *f_name, *base_dir = DATA_FOLDER;

    f_name = (char *) pointer;

//String manipulation for creating client ip-address specific filename
    f_path = (char *)malloc((strlen(base_dir) + strlen(f_name) + 1)*sizeof(char));
    strcpy(f_path, base_dir);
    strcat(f_path, f_name);

    fp = open(f_path, O_RDWR|O_CREAT|O_NONBLOCK, 0777);
    ptr = &RomanisDat[0];

    while(1) {
        pthread_mutex_lock( &sts_mutex );
        while( ptr->Status != READ_COMPLETED ) {
            pthread_cond_wait( &sts_cond, &sts_mutex );
            }
        pthread_mutex_unlock( &sts_mutex );

        ptr->Status = WRITE_IN_PROGRESS;
        buf_1 = &(ptr->Buffer);
        /*write() code...*/
        while(ptr->DataLen) {
            transfer_bytes = (ptr->DataLen > WRITE_BLOCK) ? WRITE_BLOCK : ptr->DataLen;
            snd = write(fp, (buf_1 + wc), transfer_bytes);

            if (snd < 0) {
                printf("%s: Error Writing to Disk [snd= %d]\n", f_name, snd);
                ptr->err = 1;
                close(fp);
                free(f_path);
                return 0;
                }

            ptr->DataLen -= snd;
            wc += snd;
            }
        ptr->Status = WRITE_COMPLETED;
        wc = 0;

        if(ptr->Done) {
            close(fp);
            break;
            }

        pthread_mutex_lock( &sts_mutex );
        if(WRITE_COMPLETED == ptr->Status) {
            pthread_cond_signal( &sts_cond );
            }
        pthread_mutex_unlock( &sts_mutex );

        ptr = ptr->next;

        }
    free(f_path);
    
    return 0;
    }



