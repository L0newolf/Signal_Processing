/*  #############################################

 The current bit-to-symbol mapping is 
 
 1-> +1.0
 0-> -1.0
 
 Check if this is in accordance with the modem
 
 ################################################ */

#include <stdlib.h>
#include <stdio.h>

#include <math.h>
#include "turbo.h"
#include "srandom.h"

int previous[M][2];   //previous[m][i] = previous state (this comes to state m with databit = i)
int next[M][2];     //next[m][i] = next state (this comes from state m with databit = i)
int parity[M][2]; //parity bit associated with transition from state m
int term[M][2];   //term[m] = pair of data bits required to terminate trellis

//
//      +--------------------------> Xk
//      |  fb
//      |  +---------(+)-------+
//      |  |          |        |
//  Xk--+-(+)-+->[D]----->[D]--+
//            |                |
//            +--------------(+)---> Pk
//
//
void gen_tab(void)
{
	int m, i, b0, b1, fb, state;

    //generate tables for 4 state RSC encoder
	for(m = 0; m < M; m++) //for each starting state
	{
		for(i = 0; i < 2; i++) //for each possible databit
		{
			b0 = (m >> 0) & 1; //bit 0 of state
			b1 = (m >> 1) & 1; //bit 1 of state

			//parity from state m with databit i
			parity[m][i] = b0 ^ i;
			
			//next[m][i] = next state from state m with databit i
			next[m][i]   = b0 *2 + (i ^ b0 ^ b1);
		//	printf("next[%d][%d]=%d\n",m,i,next[m][i]);
		}
	//	printf("parity[%d]= %d %d\n",m,parity[m][0],parity[m][1]);
	}

    //from[m][i] = previous state to state m with databit i
    for(m = 0; m < M; m++)
    	for(i = 0; i < 2; i++)
			previous[next[m][i]][i] = m;

	//  Generate table of data bit pairs which terminate
	//  the trellis for a given state m
	//
	//  We simply set Xk equal to the feedback value to force
	//  the delay line to fill up with zeros.
	//
	for(m = 0; m < M; m++) //for each state
	{
		state = m;
		b0 = (state >> 0) & 1; //bit 0 of state
		b1 = (state >> 1) & 1; //bit 1 of state
		fb = b0 ^ b1;          //feedback bit
		term[m][0] = fb;       //will set X[N-2] = fb

		state = next[m][fb];   //advance from state m with databit=fb
		b0 = (state >> 0) & 1; //bit 0 of state
		b1 = (state >> 1) & 1; //bit 1 of state
		fb = b0 ^ b1;          //feedback bit
		term[m][1] = fb;       //will set X[N-1] = fb
	}
}

//  Normally distributed number generator (ubiquitous Box-Muller method)
//
float normal(void)
{
	float x, y, rr, randn;
	do{
        x  = (float) 2*rand()/RAND_MAX - 1.0; //uniform in range [-1,1]
        y  = (float) 2*rand()/RAND_MAX - 1.0; //uniform in range [-1,1]
        rr = x*x + y*y;
    } while( rr >= 1 );
    randn = x*sqrt((-2.0*log(rr))/rr);
  return(randn);
}

/****************   TURBO ENCODER    ********************/
void turbo_encode
(
 int *permutation,
 int in[],
 float out[],
 int bits
 )
{
	int    k;
	int    state;
    int term1,term2;
    
	//encoder #1
	state = 0;
	for(k = 0; k < bits; k++)
	{
		out[3*k] = in[k]  ? +1.0 : -1.0;
		out[3*k+1] = parity[state][in[k]]  ? +1.0 : -1.0;
		state = next[state][in[k]];
	}
    
	//terminate encoder #1 trellis to state 0
	out[3*bits]  = term[state][0]  ? +1.0 : -1.0;
	out[3*(bits+1)]  = term[state][1]  ? +1.0 : -1.0;
    term1 = term[state][0];
    term2 = term[state][1];
	out[3*bits+1] = parity[state][term1];
	state   = next[state][term1];
    out[3*(bits+1)+1] = parity[state][term2];
	state   = next[state][term2];
    
	if(state != 0)
	{
		printf("Error: Could not terminate encoder #1 trellis\n");
		exit(1);
	}
	
	//encoder #2
	state = 0;
	for(k = 0; k < bits+2; k++)
	{
		out[3*k+2] = parity[state][(out[3*permutation[k]]<0) ? 0:1]  ? +1.0 : -1.0;
		state = next[state][(out[3*permutation[k]]<0) ? 0:1];
	}
}
/*********************************************************************/


//  modified BCJR algorithm (MAP decoder)
//
void modified_bcjr
(
	float Lc,           //Lc = 2/(sigma*sigma) = channel reliability
	float La[N],        //apriori likelihood of each info bit
	float x_d[N],       //noisy data
	float p_d[N],       //noisy parity
	float Le[N],         //extrinsic log likelihood
	int    is_term      //indicates if trellis terminated
)
{
	int    k, m, i;
	float xk_h, pk_h;      //databit & parity associated with a branch
	float gamma[N][M][2];  //gammas for total likelihoods
	float gammae[N][M][2]; //gammas for extrinsic likelihoods
	float pr0, pr1;        //extrinsic likelihood = pr1/pr0
	float alpha[N+1][M];   //probability of entering branch via state m
	float beta[N+1][M];    //probability of exiting branch via state m
	float total;           //used for normalising alpha's and beta's

    //calculate branch gamma's
    for(k = 0; k < N; k++) //for each trellis stage
    {
		for(m = 0; m < M; m++) //for each state
		{
			for(i = 0; i < 2; i++) //for each databit
			{
				//data associated with branch
				xk_h = i ? +1 : -1;            //map databit to PAM symbol

				//parity associated with branch
				pk_h = parity[m][i] ? +1 : -1; //map parity bit to PAM symbol

                //used later to calculate alpha's and beta's
				gamma[k][m][i] = exp(0.5*(La[k] * xk_h +
				                          Lc * x_d[k] * xk_h +
				                          Lc * p_d[k] * pk_h));

                //used later to calculate extrinsic likelihood
				gammae[k][m][i] = exp(0.5*(Lc * p_d[k] * pk_h));
			}
		}
	}

	//  Calculate state alpha's
	//
    //  As the likelihood ratio for each stage k has a linear combination
    //  of alpha terms in both the numerator and the denominator, we can
    //  scale all the alpha's by any convenient scaling constant.
    //
    //  To help avoid underflow/overflow we normalise the alphas at each
    //  stage so that sum across all states is unity.
    //

    //  The encoders always start in state 0
	alpha[0][0] = 1;
	for(m = 1; m < M; m++)
		alpha[0][m] = 0;

	for(k = 1; k <= N; k++)
	{
		total = 0;

	    for(m = 0; m < M; m++)
	    {
			alpha[k][m] = alpha[k-1][previous[m][0]] * gamma[k-1][previous[m][0]][0] +
			              alpha[k-1][previous[m][1]] * gamma[k-1][previous[m][1]][1];

			total += alpha[k][m];
		}

		//normalise
		for(m = 0; m < M; m++)
			alpha[k][m] /= total;
	}

	//  Calculate state beta's
	//
    //  As the likelihood ratio for each stage k has a linear combination
    //  of beta terms in both the numerator and the denominator, we can
    //  scale all the beta's by any convenient scaling constant.
    //
    //  To help avoid underflow/overflow we normalise the betas at each
    //  stage so that sum across all states is unity.
    //

	if(is_term)                 //if trellis terminated
	{
		//we know for sure the final state is 0
	    beta[N][0] = 1;
	    for(m = 1; m < M; m++)
	    	beta[N][m] = 0;
	}
	else                       //else trellis not terminated
	{
		//we haven't a clue which is final state
		//so the best we can do is say they're all equally likely
	    for(m = 0; m < M; m++)
	    	beta[N][m] = 1.0 / (float) M;
	}

    //iterate backwards through trellis
	for(k = N-1; k >= 0; k--)
	{
		total = 0;
		for(m = 0; m < 4; m++)
		{
			beta[k][m] = beta[k+1][next[m][0]] * gamma[k][m][0] +
				         beta[k+1][next[m][1]] * gamma[k][m][1];


			total += beta[k][m];
		}

        //normalise
		for(m = 0; m < 4; m++)
			beta[k][m] /= total;
	}

    //  Calculate extrinsic likelihood
    //
	//  This is the information "gleaned" from the parity check
	//  Note the Ck's in equation 20 in [2] are different in the
	//  numerator and denominator. This is why the channel and
	//  apriori likelihoods can be brought out.
	//
	for(k = 0; k < N; k++)
	{
		pr0 = pr1 = 0;
		for(m = 0; m < 4; m++)
		{
			//we use gammae rather than gamma as we want the
			//extrinsic component of the overall likelihood
			pr1 += (alpha[k][m] * gammae[k][m][1] * beta[k+1][next[m][1]]);
			pr0 += (alpha[k][m] * gammae[k][m][0] * beta[k+1][next[m][0]]);
		}
		Le[k] = log(pr1 / pr0); //extrinsic likelihood
	}

}

//  SOVA algorithm (MAP decoder)
//
void sova
(
	float Lc,           //Lc = 2/(sigma*sigma) = channel reliability
	float La[N],        //apriori likelihood of each info bit
	float x_d[N],       //noisy data
	float p_d[N],       //noisy parity
	float Le[N],         //extrinsic log likelihood
	int IsTerminated	//usualy first component decoder is terminated (this variable is 1) 
						//so its resolving from state 0 , otherwise its resolving from max metric state
)
{
	int i,s,k;
	float Metric[N+1][M];
	float Max[2];
	float delta[N+1][M];
	float deltamin;
	int survivor_bit[N+1][M]; //bit koji je preziveo
	int survivor_states[N+1];

//	for(k=0;k<N;k++)
//		printf("\n%f\t%f\t%f",La[k],x_d[k],p_d[k]);

	Metric[0][0]=0;
	for(s=1;s<M;s++)
		Metric[0][s]=-1000;

	for(k=1;k<N+1;k++)
	{
		for(s=0;s<M;s++)
		{
			for(i=0;i<2;i++)
			{
				Max[i]=Metric[k-1][previous[s][i]]  +  (i*2-1) * (Lc * x_d[k-1] + La[k-1]) + ((parity[previous[s][i]][i]>0) * 2 -1)*Lc * p_d[k-1];
			}
			if (Max[0]>Max[1])
			{
				survivor_bit[k][s]=0;
				Metric[k][s]=Max[0];
				delta[k][s]=(Max[0]-Max[1])/2;
			}
			else
			{
				survivor_bit[k][s]=1;
				Metric[k][s]=Max[1];
				delta[k][s]=(Max[1]-Max[0])/2;
			}
		}

	}

if (IsTerminated>0)
	{
		survivor_states[N]=0;	
	}
	else
	{
		float max_metric = Metric[N][0];
		survivor_states[N]=0;
		for(s=1;s<M;s++)
		{	
			if (max_metric < Metric[N][s])
			{
				max_metric = Metric[N][s];
				survivor_states[N]=s;
			}
		}
	}

	for (k=N-1;k>=0;k--)
	{
		survivor_states[k] = previous[survivor_states[k+1]][survivor_bit[k+1][survivor_states[k+1]]];
	}
	for (k=3;k<N+1;k++)
	{
		deltamin = delta[k][survivor_states[k]];
		s = previous[ survivor_states[k] ][ survivor_bit[k][survivor_states[k] ] * (-1) + 1]; //competing putanja
		for (i=k-1;i>0;i--)
		{
			if (delta[i][survivor_states[i]] < deltamin)
								deltamin=delta[i][survivor_states[i]];
			if (survivor_bit[i][survivor_states[i]]!=survivor_bit[i][s])
			{

					delta[i][survivor_states[i]] = deltamin;

			}
			s = previous[s][survivor_bit[i][s]];
		}

	}

	for(k=1;k<N+1;k++)
	{
Le[k-1]= delta[k][survivor_states[k]] * (survivor_bit[k][survivor_states[k]]*2-1) - La[k-1] - Lc * x_d[k-1];
}
}



/****************   TURBO DECODER    ********************/
void turbo_decode(
                  int *permutation,
                  float in[],
                  float out[],
                  int bits
                  )
{
	int i, k;
    
	float x_d_p[bits+2];
	float x_d[bits+2];
	float p_d[bits+2];
	float Le1[bits+2];
	float Le1_p[bits+2];
	float Le2[bits+2];
	float Le2_ip[bits+2];
    float Lc;
    
    Lc = 2.0 / (sigma*sigma);
    
    for (k=0;k<bits+2;k++)
    {
    	x_d[k] = in[3*k];
    	Le2_ip[k] = 0;
    }
    
    for(i = 0; i < N_ITERATION; i++)
    {
    	for (k=0;k<bits+2;k++)
 		   	p_d[k] = in[3*k+1];
        
#if MAP_SOVA == 0
    	modified_bcjr(Lc, Le2_ip, x_d, p_d, Le1, 1);
#elif MAP_SOVA == 1
		sova(Lc, Le2_ip, x_d, p_d, Le1,1);
#endif
        
        //permute decoder#1 likelihoods to match decoder#2 order
    	for(k = 0; k < bits+2; k++)
    	{
			Le1_p[k] = Le1[permutation[k]];
			x_d_p[k]=x_d[permutation[k]];
            
    	}
        
    	for (k=0;k<bits+2;k++)
    		p_d[k] = in[3*k+2];
        
#if MAP_SOVA == 0
		modified_bcjr(Lc, Le1_p,  x_d_p, p_d, Le2, 0);
#elif MAP_SOVA == 1
		sova( Lc, Le1_p,  x_d_p, p_d, Le2,0);
#endif
        
        //inverse permute decoder#2 likelihoods to match decoder#1 order
    	for(k = 0; k < bits+2; k++)
    		Le2_ip[permutation[k]] = Le2[k];
	}
    
    //calculate overall likelihoods and make final desicion
    for(k = 0; k < bits+2; k++)
    {
		out[k] = ((Lc*x_d[k] + Le1[k] + Le2_ip[k]) > 0.0) ? 1 : 0;
	}
}

/*********************************************************************/

