#!/bin/bash
#SBATCH -J ChunkImputation
#SBATCH -p fas_gpu     # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1               # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 80000        # memory for all cores
#SBATCH -t 0-12:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.chunkImputation.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.chunkImputation.%N.%j.err    # STDERR
srun -l -n1 hostname
srun -l -n1 echo $CUDA_VISIBLE_DEVICES

PREDFUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/predict_single_pass.py"
srun -l --gres=gpu:1 -n1 cluster/py.sh $PREDFUNC $1 $2 $3 --save-path=$4 --stride=$5 --n-folds=$6 --fold-id=$7 --error-diff-thresh=.5 &
wait
