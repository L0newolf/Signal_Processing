//
//  main.c
//  convo3
//
//  Created by Anshu Singh on 2/11/14.
//  Copyright (c) 2014 Anshu Singh. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "conv3.h"

#define BITS 2048

int main(int argc, const char * argv[])
{
    int i,j,k,err;
    float in[BITS],enc[3*BITS],out[BITS];
    
    for(i=0;i<50;i++)
    {
        for(j=0;j<50;j++)
        {
            
            srand(i*j);
            
            
            for (k=0;k<BITS;k++)
            {
                in[k] = 2*(rand()%2) - 1;
            }
            
            /* ENCODER */
            conv3_enc(&in[0],&enc[0],BITS);
            
            /*  CHANNEL EFFECTS */
            
            /* DECODER */
            conv3_dec(&enc[0],&out[0],BITS,0);
            
            err =0;
            for(k=0;k<BITS;k++)
            {
                if (in[k] != out[k])
                    err+=1;
            }
            
            printf("Err_out  : %.3f i= %d, j= %d \n",(float)err/BITS,i,j);
            
        }
    }
    return 0;
}

