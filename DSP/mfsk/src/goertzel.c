/*! Implementation of Goertzel algorithm for single frequency */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

float goertzel(int numSamples,int TARGET_FREQUENCY,int SAMPLING_RATE, int* modData) {
    int	k,i;
    float	floatnumSamples;
    float	A,sine,cosine,B,result;
    float s0re,s0im,s1re,s1im,s2re,s2im,yre,yim;

    floatnumSamples = (float) numSamples;
    k = (int) (0.5 + ((floatnumSamples * TARGET_FREQUENCY) / SAMPLING_RATE));
    A = (2.0 * 3.1416 * k) / floatnumSamples;
    sine = sin(A);
    cosine = cos(A);
    B = 2.0 * cosine;

    s0re=0;
    s0im=0;
    s1re=0;
    s1im=0;
    s2re=0;
    s2im=0;
    result=0;

    for(i=0; i<numSamples; i++) {
        s0re = modData[2*i] + B*s1re - s2re;
        s0im = modData[2*i+1] + B*s1im - s2im;

        s2re = s1re;
        s2im = s1im;

        s1re = s0re;
        s1im = s0im;
        }

    s0re = B*s1re - s2re;
    s0im = B*s1im - s2im;

    yre = s0re -s1re*cosine - s1im*sine;
    yim = s0im + s1re*sine - s1im*cosine;

    result = sqrtf(yre*yre + yim*yim);
    return result;
    }
