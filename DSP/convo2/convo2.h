#ifndef _CONVO2_H_
#define _CONVO2_H_

void convo2_init(void);
void convo2_enc(float* in, float* out, int len);
void convo2_dec(float* in, float* out, int len, int term);

#endif  //_CONV)2_H_
