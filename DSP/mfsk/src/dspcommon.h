#ifndef _DSPCOMMON_H_
#define _DSPCOMMON_H_

#include <stdio.h>
#include <stdlib.h>

#ifndef LINUX
//#include "sysreg.h"
//#include "builtins.h"
#include <signal.h>
#include <string.h>
#include <math.h>
//#include "defTS201.h"
//asm("#include <cache_macros.h>");
//asm("#include <defts201.h>");
#endif

/* General Macros */
#define TRUE                        (1)
#define FALSE                       (0)

#define TX                          (0)
#define RX                          (1)
#define DIAG                        (2)

#define WORD_SIZE                   (4)
#define BLK_SIZE_128                (128/(8*WORD_SIZE)) /* Quad Word */

#define DISABLE                     (0)
#define ENABLE                      (1)
#define AUTO                        (2)

#define FLAG_QWORD                  (1)
#define FLAG_BUF                    (0)

#define FLAG_SIGBUF                 (1)
#define FLAG_DATABUF                (0)

#define MAX_SCHEME_COUNT            (64)
#define MAX_SCHEME_PARAMS           (512)   /* 0-255: Modulation independent, 256-512: Modulation dependent */
#define DEFAULT_SCHEME              (1)     /* Scheme 1 contains default value which act as a benchmark */

#define PROCESSOR_FREQ              (500000000) /* 500 MHz */



typedef unsigned char uint8_t;              /* One byte */
typedef unsigned short uint16_t;            /* One word */
typedef unsigned int uint32_t;              /* 4 bytes */
typedef unsigned long long int uint64_t;    /* 8 bytes */

typedef void* BufferPtr_t;                  /* Void pointer */

typedef struct __QuadWord__ {
    uint32_t    qWord[WORD_SIZE];
} QuadWord_t;                               /* 4 words */

typedef enum {
    DSP_SUCCESS             = 0,
    DSP_FAILURE             = -1,
    DSP_INVALID_VALUE       = -2,
    DSP_HOST_DMA_ACTIVE     = -3,
    DSP_FPGA_DMA_ACTIVE     = -4,
    DSP_TX_QUEUE_EMPTY      = -5,
    DSP_TX_ACTIVE_TIMER     = -6,
    DSP_TX_TIMEOUT          = -7,
    DSP_TX_TEMPTY           = -8,
    DSP_TX_INCOMPLETE       = -9,
    DSP_FPGA_RX_ONGOING     = -10
} en_dspRetType;                            /* Return type enumerator */

/*
 * Callback function prototype. For DSP-HOST TX/RX
 * Arguments:
 *              BufferPtr_t     : Buffer pointer
 *              uint16_t        : Buffer length
 *              int             : Argument 1 to be passed
 *              int             : Argument 2 to be passed
 *              en_dspRetType   : Status of TX/RX
 */
typedef void (*callBack)(BufferPtr_t, uint16_t, int, int, en_dspRetType);

/* TX/RX Callback parameters */
typedef struct __BufferParams__ {
    BufferPtr_t usrBuf;
    uint16_t    bufLen;
    callBack    cb;
    int         cbArg1;
    int         cbArg2;
} BufferParams;

#endif      //_DSPCOMMON_H_
