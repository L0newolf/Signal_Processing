#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
//#include <complex.h>

#include "mex.h"
#include "matrix.h"

#include "gpu/mxGPUArray.h"

/*
* mex -v -largeArrayDims computeGACuda.cu -lstdc++ -lc
*/

/*
 * Device code
 */
void __global__ doComputeGPU(double *GC,double *AReal,double *AImag,
							 double *hCapReal,double *hCapImag,double *curUReal,double *curUImag,
							 int N,double beta,double delNLMS,double eta,double hCapMod
							)
{
	int const i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i < N) 
	{
        GC[i] = ((1-beta)/(2*N))+(((1+beta)*(hCapReal[i]+hCapImag[i]))/(2*hCapMod+eta));
		AReal[i] = GC[i]*curUReal[i];
		AImag[i] = GC[i]*curUImag[i];
    }
} 

/*
	[GC,AReal,AImag,del] = computeGC(hCapReal,hCapImag,curUReal,curUImag,gDim,beta,delNLMS,eta);	
*/
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, mxArray const *prhs[])
{
	double hCapMod = 0;
	int i,N;

    int gDim;
	double beta;
	double delNLMS;
	double eta;
	double del;

	int const threadsPerBlock = 256;
    int blocksPerGrid;

    mxGPUArray const *hCapReal;
    mxGPUArray const *hCapImag;
    mxGPUArray const *curUReal;
    mxGPUArray const *curUImag;
    mxGPUArray *GC;
    mxGPUArray *AReal;
    mxGPUArray *AImag;

    double *d_hCapReal;
    double *d_hCapImag;
    double *d_curUReal;
    double *d_curUImag;
    double *d_GC;
    double *d_AReal;
    double *d_AImag;

    gDim = (int)mxGetScalar(prhs[4]);
	beta = (double)mxGetScalar(prhs[5]);
	delNLMS = (double)mxGetScalar(prhs[6]);
	eta = (double)mxGetScalar(prhs[7]);
	hCapMod = (double)mxGetScalar(prhs[8]);

    /* Initialize the MathWorks GPU API. */
    mxInitGPU();

	hCapReal = mxGPUCreateFromMxArray(prhs[0]);
	hCapImag = mxGPUCreateFromMxArray(prhs[1]);
	curUReal = mxGPUCreateFromMxArray(prhs[2]);
	curUImag = mxGPUCreateFromMxArray(prhs[3]);

	d_hCapReal = (double *)(mxGPUGetDataReadOnly(hCapReal));
	d_hCapImag = (double *)(mxGPUGetDataReadOnly(hCapImag));
	d_curUReal = (double *)(mxGPUGetDataReadOnly(curUReal));
	d_curUImag = (double *)(mxGPUGetDataReadOnly(curUImag));

	GC = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(hCapReal),
                            mxGPUGetDimensions(hCapReal),
                            mxGPUGetClassID(hCapReal),
                            mxREAL,
                            MX_GPU_DO_NOT_INITIALIZE);
    d_GC = (double *)(mxGPUGetData(GC));

    AReal = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(hCapReal),
                            mxGPUGetDimensions(hCapReal),
                            mxGPUGetClassID(hCapReal),
                            mxREAL,
                            MX_GPU_DO_NOT_INITIALIZE);
    d_AReal = (double *)(mxGPUGetData(AReal));

    AImag = mxGPUCreateGPUArray(mxGPUGetNumberOfDimensions(hCapReal),
                            mxGPUGetDimensions(hCapReal),
                            mxGPUGetClassID(hCapReal),
                            mxREAL,
                            MX_GPU_DO_NOT_INITIALIZE);
    d_AImag = (double *)(mxGPUGetData(AImag));

    N = (int)(mxGPUGetNumberOfElements(hCapReal));
    blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    /*  Kernel goes here */
    doComputeGPU<<<blocksPerGrid, threadsPerBlock>>>(d_GC,d_AReal,d_AImag,
							 					 d_hCapReal,d_hCapImag,d_curUReal,d_curUImag,
							 					 N,beta,delNLMS,eta,hCapMod
												);

    /* Wrap the result up as a MATLAB gpuArray for return. */
    plhs[0] = mxGPUCreateMxArrayOnGPU(GC);
    plhs[1] = mxGPUCreateMxArrayOnGPU(AReal);
    plhs[2] = mxGPUCreateMxArrayOnGPU(AImag);

    del = ((1-beta)/(2*gDim))*delNLMS;
    plhs[3] = mxCreateDoubleScalar(del);
    /*
     * The mxGPUArray pointers are host-side structures that refer to device
     * data. These must be destroyed before leaving the MEX function.
     */
    mxGPUDestroyGPUArray(hCapReal);
    mxGPUDestroyGPUArray(hCapImag);
    mxGPUDestroyGPUArray(curUReal);
    mxGPUDestroyGPUArray(curUImag);
    mxGPUDestroyGPUArray(GC);
    mxGPUDestroyGPUArray(AReal);
    mxGPUDestroyGPUArray(AImag);
}