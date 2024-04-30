NVCC=nvcc
INC=/home/arl/NVIDIA_CUDA-5.5_Samples/NVIDIA_CUDA-5.5_Samples/common/inc/
NVOPT=-m64 -gencode arch=compute_20,code=sm_20 -Xptxas -v -Xcompiler -fopenmp -Xcompiler -mcmodel=large -lcuda -lcudart -I $(INC)
TEST = BFtest.cu

DOPT=-g -pg -lglut -lGLEW -lGL -lm -lpthread
DISP= -L/usr/lib/nvidia-331-updates


.PHONY: clean

all:
	$(NVCC) $(TEST) $(NVOPT) $(DOPT) -o romanisRT

clean:
	rm -f romanisRT
