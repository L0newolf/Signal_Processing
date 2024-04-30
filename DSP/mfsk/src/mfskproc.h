#ifndef _MFSKPROC_H_
#define _MFSKPROC_H_

#include "dspcommon.h"

#define MAX_MFSK_PARAMS     5


typedef enum
{
	MFSK_PARAM_BANDWIDTH		  = 0,
	MFSK_PARAM_FREQ_STEP		  = 1,
	MFSK_PARAM_SYMBOL_RATE		  = 2,
	MFSK_PARAM_BITS_PER_FREQ 	  = 3,
    MFSK_PARAM_NUM_HOPS		  = 4		
} mfskParams;


/*
 * Initialization Function
 * Passes the schemeConfig array, parses using the MOD_DEP_PARAM_OFFSET
 * Fills the ModProcessor structure and invokes
 * SchemeProc_registerModulationType() of the scheme processor
 */
void MFSKProc_init(void);

#endif //_MFSKPROC_H_
