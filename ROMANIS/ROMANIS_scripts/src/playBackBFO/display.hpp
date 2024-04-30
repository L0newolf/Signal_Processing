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

#define refreshDelay 10

#define timePerFrame 0.00033

#define FBINS         23
#define EBEAMS        12
#define ABEAMS        24
#define BEAMS         (EBEAMS*ABEAMS)
#define BLOCKS        256

#define MAX_COLOURS 42

#define SOCKET_DISPLAY_PATH "sockets/SOCKET_DISPLAY_PATH"
#define TERMINATE 1
#define NOT_TERMINATE 0

#define FRAMESIZE 32
#define PACKET_LENGTH FBINS*BEAMS*(BLOCKS)

#define MAX_BFO_BUFFER 10

#define FRAMES_PER_BUF 8

#define COMPLETE 1
#define CONTINUE 0

#define COPY_NOW 1
#define HOLD_COPY 0
