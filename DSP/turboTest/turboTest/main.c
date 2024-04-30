#include <stdio.h>
#include <stdlib.h>
#include "turbo.h"
#include "srandom.h"

int main(void)
{
	float    X_h[N];    //X_hat = sliced MAP decisions
	int    k,i,j;         //databit index (trellis stage)
    int err;
    int X[N];
    int loop1=50;
    int loop2=50;
    float errP;
    int errIn;
    float enc[3*N];
    
    FILE *fp1,*fp2;
    fp1 = fopen("/Users/ARL/Desktop/GoogleDrive/turboTest/turboTest/input_errors.txt","w");
    fp2 = fopen("/Users/ARL/Desktop/GoogleDrive/turboTest/turboTest/output_errors.txt","w");
    
    int permutation[N];
    sRandm(N,10,&permutation[0]);
    int randm[3*N];
    sRandm(3*N,rand(),&randm[0]);
    
    for(i=0;i<loop1;i++)
    {
        for(j=0;j<loop2;j++)
        {
            /********************************
             *         INITIALISE           *
             ********************************/
            
            srand(i*j);    //init random number generator
            
            
            for (k=0;k<N;k++)
            {
                X[k] = rand()%2;
            }
            
            gen_tab();   //generate trellis tables
            
            
            /********************************
             *           ENCODER            *
             ********************************/
            
            
            turbo_encode(&permutation[0],X,enc,N-2);
            
            
            /********************************
             *           CHANNEL            *
             ********************************/
            /*
             int idx;
             errP = 0.01*j;
             errIn = errP*N*3;
             
             for(k=0;k<errIn;k++)
             {
             idx = randm[k];
             
             if(enc[idx] == -1.0)
             enc[idx] = 1.0;
             else
             enc[idx] = -1.0;
             }
             */
            
            errP = 0.01 * j;
            errIn = 0;
            
            for(k=0;k<3*N;k++)
            {
                float prob = (float)rand()/RAND_MAX;
                if(prob<errP)
                {
                    if(enc[k] == -1.0)
                        enc[k] = 1.0;
                    else
                        enc[k] = -1.0;
                    errIn+=1;
                }
            }
            /********************************
             *           DECODER            *
             ********************************/
            
            turbo_decode(&permutation[0],enc,X_h,N-2);
            
            err=0;
            for(k = 0; k < N-2; k++)
            {
                if(X_h[k]!=X[k])
                {
                    err+=1;
                }
                
            }
            
            printf("Err in : %d Err_in  = %.3f Err_out = %.3f  i = %d j = %d \n",errIn,(float)errIn/(3*N),(float)err/N,i,j);
            fprintf(fp1,"%.3f,",(float)errIn/(3*N) );
            fprintf(fp2,"%.3f,",(float)err/N );
        }
        
        fprintf(fp1,"\n");
        fprintf(fp2,"\n" );
        
        
    }
    
    fclose(fp1);
    fclose(fp2);
    
	return 0;
}
