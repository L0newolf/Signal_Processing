#ifndef FIR
#define FIR


 enum TBasicPassType {LPF, HPF, BPF, NOTCH};

 enum TWindowType {wtNONE, wtKAISER, wtSINC, wtHANNING, wtHAMMING, wtBLACKMAN,
				   wtFLATTOP, wtBLACKMAN_HARRIS, wtBLACKMAN_NUTTALL, wtNUTTALL,
				   wtKAISER_BESSEL, wtTRAPEZOID, wtGAUSS, wtSINE, wtTEST };


 void BasicFIR(float *FirCoeff, int NumTaps, TBasicPassType PassType, float OmegaC, float BW, TWindowType WindowType, float WinBeta);
 void WindowData(float *Data, int N, TWindowType WindowType, float Alpha, float Beta, bool UnityGain);
 float Bessel(float x);
 float Sinc(float x);

#endif
