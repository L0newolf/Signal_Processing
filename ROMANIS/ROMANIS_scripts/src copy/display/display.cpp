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

#include "colourBar.h"
#include "display.hpp"

#define REALTIME 1
#define PREPROC 0
#define FRAMES_PER_BLOCK 8

using namespace std;

//Default User Options
int FrameSize = 32;
int freqBinLower = 0;
int freqBinUpper = 18;
float ExpAvg = 0.9;
float DynRange = 12.0;
float curTime = 0;

//Pointer to generate buffer to store the beamformed data
float* bfoData;
float **bfoBuffer;
//Buffer pointer to store the display-processed beam frames
float frameBuffer[NUM_SQRS];

// Common variables used for data processing and display
int beams,framesToDraw,dataIdx,fRange,bfoBufPtr,drawBufPtr;
int frameCount = 0;
float cimg[ybeams][xbeams];
int respClient;
int drawStatus = CONTINUE;

pthread_mutex_t dispmutex;

/* ###################################################################################
					Utility Functions
   ################################################################################### */

template <typename T>
std::string to_string(T value)
{
    std::ostringstream os ;
    os << value ;
    return os.str() ;
}

// Initializes all the parameters and variables
void initVars(int len, int mode)
{
    fRange = freqBinUpper-freqBinLower+1;
    beams = ybeams*xbeams*fbins;
    if (mode == PREPROC)
        framesToDraw = len/(BEAMS*FBINS);
    else
        framesToDraw = FRAMES_PER_BLOCK;
    //intialize the cimg array to all zeros
    for(int y=0; y<ybeams; y++)
        {
            for(int x=0; x<xbeams; x++)
                {
                    cimg[y][x]=0.0f;
                }
        }
    dataIdx = 0;
}



// Interpolation Function


/*
void interpolate (float in[ybeams][xbeams], float out[ybeamsInt][xbeamsInt])
{

    float xStep,yStep;

    // Fill all first rows
    for(int j=0; j<ybeams; j++)
        {
            for(int i = 0; i<xbeams-1; i++)
                {
                    xStep = (in[j][i+1] - in[j][i])/(INTERPOLATION_FACTOR);
                    out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i] = in[j][i];
                    for(int k=1; k<INTERPOLATION_FACTOR; k++)
                        {
                            out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i+k] = in[j][i] + k*xStep;
                        }
                }
            out[INTERPOLATION_FACTOR*j][xbeamsInt-1] = in[j][xbeams-1];
        }

    // Fill up all the clomuns
    for(int i=0; i<ybeams-1; i++)
        {
            for(int j=0; j<xbeamsInt; j++)
                {
                    yStep = (out[INTERPOLATION_FACTOR*(i+1)][j] - out[INTERPOLATION_FACTOR*i][j])/INTERPOLATION_FACTOR;
                    for(int k=1; k<INTERPOLATION_FACTOR; k++)
                        {
                            out[INTERPOLATION_FACTOR*i+k][j] = out[INTERPOLATION_FACTOR*i][j] + k*yStep;

                        }
                }
        }
}
*/
float interpolate (float in[ybeams][xbeams], float out[ybeamsInt][xbeamsInt])
{

    float xStep,yStep;
    float maxVal = 0.0;
    /* Fill all first rows */
    for(int j=0; j<ybeams; j++)
        {
            for(int i = 0; i<xbeams-1; i++)
                {
                    xStep = (in[j][i+1] - in[j][i])/(INTERPOLATION_FACTOR);
                    out[INTERPOLATION_FACTOR*j][INTERPOLATION_FACTOR*i] = in[j][i];
                    for(int k=1; k<INTERPOLATION_FACTOR; k++)
                        {
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
    for(int i=0; i<ybeams-1; i++)
        {
            for(int j=0; j<xbeamsInt; j++)
                {
                    yStep = (out[INTERPOLATION_FACTOR*(i+1)][j] - out[INTERPOLATION_FACTOR*i][j])/INTERPOLATION_FACTOR;
                    for(int k=1; k<INTERPOLATION_FACTOR; k++)
                        {
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
/*
void processBF(float *bfOutput)
{

    float sum,maxVal;
    float beamFrames[xbeams][ybeams][fbins];
    float frameFreqAvg[xbeams][ybeams];
    float cimgInt[ybeamsInt][xbeamsInt];
    int bufIdx = 0;
    int dynAdd;
//initialize the frame pointer to 1st frame
    sum =0;
    maxVal = 0;

//Select the frames in blocks of Framesize,Average out the frames over the desired frequency range

    for(int y=ybeams-1; y>-1; y--)
        {
            for(int x=xbeams-1; x>-1; x--)
                {
                    for(int f=0; f<fbins; f++)
                        {
                            beamFrames[x][y][f] = bfOutput[dataIdx];
                            dataIdx++;
                        }
                    sum = 0.0f;
                    for(int f=freqBinLower-1; f<freqBinUpper; f++)
                        {
                            sum += beamFrames[x][y][f];
                        }
                    frameFreqAvg[x][y] = sum/fRange;
                }
        }

//Avearge out the frames into a singe frame,Multiply cimg and transpose of the time average frames with ExpAvg
    for(int x=0; x<xbeams; x++)
        {
            for(int y=0; y<ybeams; y++)
                {
                    cimg[y][x] = ExpAvg*cimg[y][x] + (1.0-ExpAvg)*frameFreqAvg[x][y];
                }
        }

//Interpolate cimg
    interpolate(cimg,cimgInt);

//Take log of interpolated cimg and find maximum values
    for(int y=0; y<ybeamsInt; y++)
        {
            for(int x=0; x<xbeamsInt; x++)
                {
                    cimgInt[y][x] = 20*log10(cimgInt[y][x]);
                    if (maxVal<cimgInt[y][x])
                        maxVal = cimgInt[y][x];
                }
        }

//Set the Dynamic Range values
    dynAdd = -maxVal+DynRange;
    for(int y=0; y<ybeamsInt; y++)
        {
            for(int x=0; x<xbeamsInt; x++)
                {
                    cimgInt[y][x] = (cimgInt[y][x]+dynAdd)/DynRange;
                    if(cimgInt[y][x]<0)
                        cimgInt[y][x] = 0.0;
                    else if(cimgInt[y][x]>1.0)
                        cimgInt[y][x] = 63.0;
                    else
                        cimgInt[y][x] = 63.0*cimgInt[y][x];

                    frameBuffer[bufIdx] =  cimgInt[y][x];
                    bufIdx++;

                }
        }
}
*/


void processBF(float *bfOutput)
{

    float sum,maxVal;
    float beamFrames[xbeams][ybeams][fbins];
    float frameFreqAvg[xbeams][ybeams];
    float cimgInt[ybeamsInt][xbeamsInt];
    int bufIdx = 0;
    int dynAdd;
//initialize the frame pointer to 1st frame
    sum =0;
    maxVal = 0;

//Select the frames in blocks of Framesize,Average out the frames over the desired frequency range

    for(int y=ybeams-1; y>-1; y--)
        {
            for(int x=xbeams-1; x>-1; x--)
                {
                    for(int f=0; f<fbins; f++)
                        {
                            beamFrames[x][y][f] = bfOutput[dataIdx];
                            dataIdx++;
                        }
                    sum = 0.0f;
                    for(int f=freqBinLower-1; f<freqBinUpper; f++)
                        {
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
    for(int y=0; y<ybeamsInt; y++)
        {
            for(int x=0; x<xbeamsInt; x++)
                {
                    cimgInt[y][x] = (20*log10(cimgInt[y][x])+dynAdd)/DynRange;
                    if(cimgInt[y][x]<0)
                        cimgInt[y][x] = 0.0;
                    else if(cimgInt[y][x]>1.0)
                        cimgInt[y][x] = 63.0;
                    else
                        cimgInt[y][x] = 63.0*cimgInt[y][x];

                    frameBuffer[bufIdx] =  cimgInt[y][x];
                    bufIdx++;
                }
        }
}


/* ###################################################################################
					Beamformer Display using OpenGL
   ################################################################################### */

void printText(int x, int y, string textDisplay)
{

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
    for (int i=0; i<textDisplay.size(); i++)
        {
            glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, textDisplay[i]);
        }
    glPopAttrib();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
}

void displayMsg()
{

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
void timerEvent(int value)
{
    glutPostRedisplay();
    glutTimerFunc(refreshDelay, timerEvent, 0);
}

void genVerticesDisplay()
{

    float curColor;

    int i,j;
    int x=0;
    int y=0;
    int clr;
    int vertCount = 0;
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

    for (i=0; i<NUM_SQRS; i++)
        {
            if (x==xPoints-1)
                {
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

    for(i=0; i<4*xPoints; i+=4)
        {

            glColor3f(accousColor[curColour][0],accousColor[curColour][1],accousColor[curColour][2]);
            glVertex3f(xcords[x], yColorBar[0], 0.0);
            glVertex3f(xcords[x+1], yColorBar[0], 0.0);
            glVertex3f(xcords[x+1],  yColorBar[1], 0.0);
            glVertex3f( xcords[x], yColorBar[1], 0.0);

            drawCnt+=1;
            //xSqrs = 208
            if(drawCnt % 5 == 0)
                curColour++;


            x+=1;
        }


}

void updateFrame()
{

    if(frameCount<framesToDraw)
        {
            clock_t startClk,endClk;
            int rounds = 0;
            //////////////////////////////////////
            startClk = clock();
            ////////////////////////////////////////
            processBF(bfoData);
            genVerticesDisplay();
            ///////////////////////////////////////////////////
            endClk = clock();
            printf("Time of round %d : %f\n",++rounds,(double)(endClk-startClk)/CLOCKS_PER_SEC);
            /////////////////////////////////////////////////
        }

}

void fpsDisplay()
{
    char fps[64];
    if(frameCount < framesToDraw)
        curTime = curTime + FrameSize*timePerFrame;
    sprintf(fps, "ROMANIS BEAM VISUALISATION                    Current Time : %0.3f",curTime);
    glutSetWindowTitle(fps);
}

void display(void)
{
    if(drawStatus == CONTINUE)
        {
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_DEPTH_TEST);
            glClear( GL_COLOR_BUFFER_BIT);

            glShadeModel(GL_SMOOTH);
            glBegin(GL_QUADS);

            updateFrame();

            glEnd();
            glFlush();

            displayMsg();

            fpsDisplay();
            if(frameCount<framesToDraw)
                {
                    pthread_mutex_lock (&dispmutex);
                    frameCount++;
                    pthread_mutex_unlock (&dispmutex);
                    glutSwapBuffers();
                }
            else
                {
                    pthread_mutex_lock (&dispmutex);
                    drawStatus = COMPLETE;
                    pthread_mutex_unlock (&dispmutex);
                }

        }
}

void special(int key, int x, int y)
{
    switch (key)
        {
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

void drawFrame(int argc, char *argv[])
{

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

/************ SOCKET SERVER FUNCTION ************/
void *startSockServer(void *)
{
    int dispSock, lenSock;
    struct sockaddr_un localDisp;

    //FILE *fp;
    //fp = fopen("bfo_disp","w");

    if ((dispSock = socket(AF_UNIX, SOCK_STREAM, 0)) == -1)
        {
            perror("socket");
            exit(-1);
        }
    localDisp.sun_family = AF_UNIX;
    strcpy(localDisp.sun_path, SOCKET_DISPLAY_PATH);
    unlink(localDisp.sun_path);
    lenSock = strlen(localDisp.sun_path) + sizeof(localDisp.sun_family);
    if (bind(dispSock, (struct sockaddr *)&localDisp, lenSock) == -1)
        {
            perror("bind");
            exit(-1);
        }
    if (listen(dispSock, 5) == -1)
        {
            perror("listen");
            exit(-1);
        }
    bfoBufPtr = 0;
    drawBufPtr = 0;

    do
        {
            struct sockaddr_un remoteDisp;
            int dispSockCon,dispConn;
            int status;
            dispConn = sizeof(remoteDisp);

            if ((dispSockCon = accept(dispSock, (struct sockaddr *)&remoteDisp,(socklen_t *) &dispConn)) == -1)
                {
                    perror("accept");
                    exit(-1);
                }

            status = recv(dispSockCon, &respClient, sizeof(int),0);

            if (status != -1)
                {
                    if(respClient == NOT_TERMINATE)
                        {

                            status = recv(dispSockCon, &bfoBuffer[bfoBufPtr][0], PACKET_LENGTH*sizeof(float),0);

                            if (status == -1)
                                {
                                    perror("recv");
                                    printf("Error in getting data !!!\n");
                                }
                            else
                                {

                                    if(++bfoBufPtr == MAX_BFO_BUFFER) bfoBufPtr = 0;

                                    if(drawStatus == COMPLETE)
                                        {
                                            for(int k=0; k<PACKET_LENGTH; k++)
                                                {
                                                    bfoData[k] = bfoBuffer[drawBufPtr][k];
                                                    bfoBuffer[drawBufPtr][k] = 0.0;
                                                }

                                            //fwrite(bfoData, PACKET_LENGTH, sizeof(float), fp);

                                            if(++drawBufPtr == MAX_BFO_BUFFER) drawBufPtr = 0;
                                            pthread_mutex_lock (&dispmutex);
                                            drawStatus = CONTINUE;
                                            frameCount = 0;
                                            initVars(PACKET_LENGTH,REALTIME);
                                            pthread_mutex_unlock (&dispmutex);
                                        }
                                }
                            close(dispSockCon);
                        }
                }
            else
                {
                    perror("recv");
                    printf("Error in getting status message !!!!\n");
                }


        }
    while(respClient != TERMINATE);

    while(drawBufPtr!=MAX_BFO_BUFFER)
        {
            if(drawStatus == COMPLETE)
                {

                    for(int k=0; k<PACKET_LENGTH; k++)
                        {
                            bfoData[k] = bfoBuffer[drawBufPtr][k];
                            bfoBuffer[drawBufPtr][k] = 0.0;
                        }

                    //fwrite(bfoData, sizeof(bfoData), sizeof(float), fp);

                    pthread_mutex_lock (&dispmutex);
                    drawStatus = CONTINUE;
                    frameCount = 0;
                    initVars(PACKET_LENGTH,REALTIME);
                    pthread_mutex_unlock (&dispmutex);
                    drawBufPtr++;
                }
        }

    printf("Closing Connection to Beam processing system \n");
    close(dispSock);
    unlink(SOCKET_DISPLAY_PATH);
    //fclose(fp);
    return 0;

}
/*************************************************************/

/* ###################################################################################
					 Main function
   ################################################################################### */

int main(int argc, char *argv[])
{
    int dataSize,dispMmapFile;

    if (argc < 2)
        {
            printf("Usage: %s Operation_Mode [Path_to_Beamformer_output_file]\n",argv[0]);
            printf("Operating_Mode : 0-> Realtime Display, Beamformer output file not needed\n");
            printf("Operating_Mode : 1-> Display pre-processed data, Path to Beamformer output file needed\n");
            return 1;
        }



    /*************************************************************/
    //If the OpMode is to display BF processed data
    /*************************************************************/

    if(!strcmp(argv[1],"1"))
        {

            if(argc<3)
                {
                    printf("Usage: %s Operation_Mode Path_to_Beamformer_output_file\n",argv[0]);
                    return 1;
                }

            printf("Starting display of BF pre-processed data...\n");

            float *bfoFileData;
            FILE *fbfo;
            fbfo  = fopen(argv[2],"rb");
            fseek (fbfo,0,SEEK_END);
            dataSize = (ftell(fbfo)/4) - 4;
            bfoFileData = (float *)malloc((dataSize)*sizeof(float));
            rewind(fbfo);
            fread(bfoFileData,sizeof(float),dataSize,fbfo);
            fclose(fbfo);

            initVars(dataSize/(2*FrameSize),PREPROC);

            bfoData = (float *)malloc((framesToDraw*beams)*sizeof(float));


            float bfoFrameAvg[FrameSize][beams];
            int dataCount = 0;
            int dataFrameCount = 0;
            float bfoSum = 0.0;

            for(int k=0; k<framesToDraw; k++)
                {
                    for(int i=0; i<FrameSize; i++)
                        {
                            for(int j=0; j<beams; j++)
                                {
                                    bfoFrameAvg[i][j] = sqrt(pow(bfoFileData[dataCount],2)+pow(bfoFileData[dataCount+1],2));
                                    dataCount+=2;
                                }
                        }

                    for(int i=0; i<beams; i++)
                        {
                            bfoSum = 0.0;
                            for(int j=0; j<FrameSize; j++)
                                {
                                    bfoSum += bfoFrameAvg[j][i];
                                }
                            bfoData[dataFrameCount] = bfoSum/FrameSize;
                            dataFrameCount++;
                        }
                }

            printf("Frames to draw : %d\n",framesToDraw );
            drawFrame(argc,argv);
        }

    /*************************************************************/
    // If OpMode is Real Time display of BF processed data
    /**************************************************************/

    else if(!strcmp(argv[1],"0"))
        {

            bfoData = (float *)malloc(PACKET_LENGTH*sizeof(float));
            if((bfoBuffer = (float **)malloc(MAX_BFO_BUFFER*sizeof(float *)))==NULL)
                {
                    printf("Out of Memory !!!");
                    return -1;
                }
            for(int k=0; k<MAX_BFO_BUFFER; k++)
                if ((bfoBuffer[k] = (float *)malloc(PACKET_LENGTH*sizeof(float)))==NULL)
                    {
                        printf("Out of Memory !!!");
                        return -1;
                    }
            for(int i=0; i<MAX_BFO_BUFFER; i++)
                {
                    for(int k=0; k<PACKET_LENGTH; k++)
                        {
                            bfoBuffer[i][k] = 0.0;
                        }
                }
            pthread_t threadCopySock,threadUpdateBuf;
            pthread_mutex_init(&dispmutex, NULL);

            void *dummy = NULL;

            //create the socket connection and start server

            pthread_create(&threadCopySock,NULL,startSockServer,dummy);


            initVars(PACKET_LENGTH,REALTIME);
            drawFrame(argc,argv);

            pthread_join(threadCopySock,NULL);

        }
    //Error Handler for starting on program
    else
        {
            printf("\n\n       INVALID OPERATION MODE OPTION !!!! \n\n");
            printf("Usage: %s Operation_Mode [Path_to_Beamformer_output_file]\n",argv[0]);
            printf("Operating_Mode : 0-> Realtime Display\nUsage:%s Operation_Mode\n",argv[0]);
            printf("Operating_Mode : 1-> Display pre-processed data\nUsage: %s Operation_Mode [Path_to_Beamformer_output_file]\n\n",argv[0]);
            return 1;
        }

    return 0;
}
