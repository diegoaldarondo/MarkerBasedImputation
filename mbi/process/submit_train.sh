#!/bin/bash
#SBATCH -J MultiNodeTrain
#SBATCH -p fas_gpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1              # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 90000        # memory for all cores
#SBATCH -t 0-8:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/multinodeTrain.Job.%N.%j.out    # STDOUT
#SBATCH -e logs/multinodeTrain.Job.%N.%j.err    # STDERR

srun -l -n1 hostname
srun -l -n1 echo $CUDA_VISIBLE_DEVICES

# Specify paths and variables for training. Be sure all arrays have the same length.
FUNC="training.py"

# Run training with parameters specified above.
srun -l --gres=gpu:1 process/py.sh $FUNC $1 --base-output-path=$2 --epochs=$3 --stride=$4 &
wait
