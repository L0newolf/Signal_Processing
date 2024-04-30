#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <complex.h>

#include "mex.h"
#include "matrix.h"

/*
*[GC,AReal,AImag,del] = computeGC(hCapReal,hCapImag,curUReal,curUImag,gDim,beta,delNLMS,eta);
* mex -v CFLAGS="-Wall" Csrc/computeGC.c
*/

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
	double *hCapReal;
	double *hCapImag;
	double *curUReal;
	double *curUImag;
	int gDim;
	double beta;
	double delNLMS;
	double eta;
	
	double *GC;
	double *AReal;
	double *AImag;
	double del;
	
	double hCapMod = 0;
	int i;
	
	/*---------------------------------------------------------------------------------------------------------------------------------------
    GET INPUT VARIABLES FROM MATLAB
    ---------------------------------------------------------------------------------------------------------------------------------------*/
	
	gDim = (int)mxGetScalar(prhs[4]);
	beta = (double)mxGetScalar(prhs[5]);
	delNLMS = (double)mxGetScalar(prhs[6]);
	eta = (double)mxGetScalar(prhs[7]);
	
	hCapReal = (double *)mxGetPr(prhs[0]);
	hCapImag = (double *)mxGetPr(prhs[1]);
	
	curUReal = (double *)mxGetPr(prhs[2]);
	curUImag = (double *)mxGetPr(prhs[3]);
	
	/*---------------------------------------------------------------------------------------------------------------------------------------
    GET OUTPUT VARIABLES FROM MATLAB
    ---------------------------------------------------------------------------------------------------------------------------------------*/
	
	
	plhs[0] = mxCreateDoubleMatrix(gDim, 1 , mxREAL);
    GC = (double *)mxGetPr(plhs[0]);
	
	plhs[1] = mxCreateDoubleMatrix(gDim, 1 , mxREAL);
    AReal = (double *)mxGetPr(plhs[1]);
	
	plhs[2] = mxCreateDoubleMatrix(gDim, 1 , mxREAL);
    AImag = (double *)mxGetPr(plhs[2]);

	for(i=0;i<gDim;i++)
	{
		hCapMod += hCapReal[i]+hCapImag[i];
	}

	for(i=0;i<gDim;i++)
	{
		GC[i] = ((1-beta)/(2*gDim))+(((1+beta)*(hCapReal[i]+hCapImag[i]))/(2*hCapMod+eta));
		AReal[i] = GC[i]*curUReal[i];
		AImag[i] = GC[i]*curUImag[i];
	}
	
	del = ((1-beta)/(2*gDim))*delNLMS;

	/*Set output variable*/ 
	plhs[3] = mxCreateDoubleScalar(del);
}

/*
>> A = [1,2,3,4,5];
>> B = [1;2;3;4;5];
>> C = diag(A);
>> D = C*B;
>> for i=1:length(A)
E(i,1) = A(i)*B(i);
end
*/