#ifndef _BFSKPROC_H_
#define _BFSKPROC_H_

#include "dspcommon.h"

#define MAX_BFSK_PARAMS     4

#define ARL_OP_MODE 2
#define WHOI_OP_MODE 3
#define JANUS_OP_MODE 4

typedef enum
{
    BFSK_PARAM_SYMB_RATE       = 0,    /* Symbol rate (80 or 160)*/
    BFSK_PARAM_HOP_SEQ         = 1,    /* Number of frequency hops ( 7 or 13)  */
    BFSK_SYNC_BITS_SEQ         = 2,    /* Sequence of the synchronization bits being sent out*/
    BFSK_OP_MODE               = 3
} bfskParams;

/*Stuct to save all Tx and Rx parameters*/
typedef struct
{
    int hopFreq;
    int numHops;
    int syncBits;
    float symbDur;
} paramSet;

/*
 * Initialization Function
 * Passes the schemeConfig array, parses using the MOD_DEP_PARAM_OFFSET
 * Fills the ModProcessor structure and invokes
 * SchemeProc_registerModulationType() of the scheme processor
 */
void BFSKProc_init(void);

#endif //_BFSKPROC_H_
