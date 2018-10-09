#!/bin/bash
#SBATCH -J AnalyzeModel
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 128000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

module load Anaconda3/5.0.1-fasrc02
module load cuda/8.0.61-fasrc01 cudnn/6.0_cuda8.0-fasrc01
module load bazel/0.13.0-fasrc01 gcc/4.9.3-fasrc01 hdf5/1.8.12-fasrc08 cmake
module load Anaconda3/5.0.1-fasrc02
source activate tf1.4_cuda8

python "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/analyze_performance.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/JDM25_20181002T180653-wave_net_ensemble_epochs=40_input_9_output_1_05-09_06" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --analyze-history=False
