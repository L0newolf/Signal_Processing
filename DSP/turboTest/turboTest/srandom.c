
/*!
 * Implementation of S-Random Interleaver
 *
 * @file    srandom.c
 * @author  Anshu
 */

#include "srandom.h"
#include <stdlib.h>

void sRandm(int len,int seed,int *sRandA)
{
    srand(seed);
    sRandA[0] = rand()%len;
    int k;
    int j;
    
    
    for(j=1;j<len;j++)
    {
        
        sRandA[j]=rand()%len;
        for(k=0;k<j;k++)
        {
            if(sRandA[j]==sRandA[k])
            {
                j=j-1;
                
                break;
            }
        }
    }
}
