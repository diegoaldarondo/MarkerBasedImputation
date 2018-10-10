#!/bin/bash
echo "$@"
module load Anaconda3/5.0.1-fasrc02
module load cuda/8.0.61-fasrc01 cudnn/6.0_cuda8.0-fasrc01
module load bazel/0.13.0-fasrc01 gcc/4.9.3-fasrc01 hdf5/1.8.12-fasrc08 cmake
module load Anaconda3/5.0.1-fasrc02
source activate tf1.4_cuda8

python "$@"
