
/*!
 * (23,12,7) Covolutional FEC implementation by Mandar Chitre.
 * Taken from doppler resiliant scheme implementation in UNET I
 *
 * @file    conv3.c
 * @author  Anshu
 */

#include <stdio.h>
#include <stdlib.h>
#include "conv3.h"
#include <time.h>

#define STATES       256
#define LARGE        1e9

static unsigned char outputs[STATES] = {
#include "conv3out.dat"
};


static inline int nextState(int s, int b)
{
    return (b<<7)|(s>>1);
}

static inline int outBits(int s, int b)
{
    return (b?outputs[s]:(outputs[s]>>4)) & 0x07;
}

static inline float bipolar(int x, int b)
{
    float biplr_opt= ((x>>b)&1)?-1.0:1.0;
	return biplr_opt;
}

static inline float branchMetric(int s, int b, float* y)
{
    int bm = 0;
    int x = outBits(s,b);
    if (bipolar(x,0)*y[0] < 0) bm++;
    if (bipolar(x,1)*y[1] < 0) bm++;
    if (bipolar(x,2)*y[2] < 0) bm++;
    return (float)bm;
}

void conv3_init(void)
{
    // do nothing
}

void conv3_enc(float* in, float* out, int len)
{
    int i, s;
    
    s = 0;                                // initial state is 0
    for (i = 0; i < len; i++) {
        int b = (in[i]<0)?1:0;
        int x = outBits(s,b);
        s = nextState(s,b);
        out[i*3] = bipolar(x,0);
        out[i*3+1] = bipolar(x,1);
        out[i*3+2] = bipolar(x,2);
    }
}

void conv3_dec(float* in, float* out, int len, int term)
{
    static unsigned int tb[2*STATES];   // implicit traceback of 32 bits
    static float cost[2*STATES];
    float *curCost, *nextCost;
    unsigned int *curTB, *nextTB;
    int i, j, s, counter;
    int bm0,bm1,s0,s1;
    counter=len/3;
    
    // initialize cost and traceback arrays
    curCost = cost;
    curTB = tb;
    curCost[0] = 0;                     // initial state is 0
    curTB[0] = 0;
    
    for (s = 1; s < STATES; s++) {
        curCost[s] = LARGE;
        curTB[s] = 0;
    }
    
    nextCost = cost+STATES;
    nextTB = tb+STATES;
    // Viterbi algorithm
    for (i = 0; i <counter; i++) {
        // output a bit if traceback is about to overflow
        if (i > 31) {
            
            j = 0;
            for (s = 1; s < STATES; s++)
                if (curCost[s] < curCost[j]) j = s;
            
            out[i-32] = bipolar(curTB[j],31);
        }
        // initialize next state costs
        
        for (s = 0; s < STATES; s++)
            nextCost[s] = LARGE;
        
        
        // compute next state costs
        
        for (s = 0; s < STATES; s++) {
            bm0 = curCost[s] + branchMetric(s,0,in+i*3);
            bm1 = curCost[s] + branchMetric(s,1,in+i*3);
            s0 = nextState(s,0);
            s1 = nextState(s,1);
            if (nextCost[s0] > bm0) {
                nextCost[s0] = bm0;
                nextTB[s0] = curTB[s]<<1;
            }
            if (nextCost[s1] > bm1) {
                nextCost[s1] = bm1;
                nextTB[s1] = (curTB[s]<<1)|1;
            }
        }
        
        // swap state cost and traceback buffers
        curCost = nextCost;
        curTB = nextTB;
        if (curCost == cost) {
            nextCost = cost+STATES;
            nextTB = tb+STATES;
        } else {
            nextCost = cost;
            nextTB = tb;
        }
    }
    // output remaining bits
    j = 0;
    if (!term) {
        for (s = 1; s < STATES; s++)
            if (curCost[s] < curCost[j]) j = s;
    }
    
#pragma vector_for
    for (i = 31; i >= 0; i--)
        out[len/3-i-1] = bipolar(curTB[j],i);
    
    
}
