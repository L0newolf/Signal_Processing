#include <stdio.h>
#include <stdlib.h>

#define BITS 2048
int main()
{
    float in[BITS],enc[3*BITS],dec[BITS];
    int i,errCount;

    for(i=0;i<BITS;i++)
    {
        in[i] = 2*(rand()%2) - 1.0;
    }

    convo2_enc(&in[0],&enc[0],BITS);

    convo2_dec(&enc[0],&dec[0],3*BITS,0);

    errCount=0;
    for(i=0;i<BITS;i++)
    {
        if (in[i]!=dec[i])
        errCount+=1;
    }

    printf("Errors = %d",errCount);

    return 0;
}
