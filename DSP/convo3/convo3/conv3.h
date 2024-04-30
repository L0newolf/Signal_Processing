#ifndef _CONV3_H_
#define _CONV3_H_

void conv3_init(void);
void conv3_enc(float* in, float* out, int len);
void conv3_dec(float* in, float* out, int len, int term);

#endif  //_CONV3_H_
