#!/bin/bash
#SBATCH -J ChunkImputation
#SBATCH -p gpu_requeue     # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1               # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 30000        # memory for all cores
#SBATCH -t 0-3:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

PREDFUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/predict_single_pass.py"
srun -l --gres=gpu:1 -n1 --mem=30000 cluster/py.sh $PREDFUNC $1 $2 --save-path=$3 --stride=$4 --n-folds=$5 --fold-id=$6 --pass-direction=$7 &
wait
