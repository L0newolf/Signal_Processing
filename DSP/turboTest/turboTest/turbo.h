//
//  turbo.h
//  turboTest
//
//  Created by Anshu Singh on 2/4/14.
//  Copyright (c) 2014 Anshu Singh. All rights reserved.
//

#ifndef turboTest_turbo_h
#define turboTest_turbo_h



#endif


// tables for trellis are global
//
#define M  4      //no. of trellis states

#define N_ITERATION 4 //no. of turbo decoder iterations
#define MAP_SOVA 1		//set which algorithm to use [0=>MAP,1=>SOVA]
#define sigma 1.0
#define N    2048


void turbo_decode(
                  int *permutation,
                  float in[],
                  float out[],
                  int bits
                  );


void turbo_encode
(
 int *permutation,
 int in[],
 float out[],
 int bits
 );

void gen_tab(void);
