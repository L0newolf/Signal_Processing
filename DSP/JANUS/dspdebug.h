
#ifndef _DSP_DEBUG_H_
#define _DSP_DEBUG_H_

#include "dspcommon.h"

/* 
 * Sends a debug ntf to host with string as data.
 * Host logs this message till it see a zero.
 */
void
DspDebug_print(char *s);

#endif  //_DSP_DEBUG_H_
