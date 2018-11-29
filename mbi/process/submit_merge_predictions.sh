#!/bin/bash
#SBATCH -J MergePreds
#SBATCH -p olveczky      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1                # number of tasks
# --gres=gpu:1        # number of total gpus
#SBATCH --mem 120000        # memory for all cores
#SBATCH -t 0-24:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.mergePreds.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.mergePreds.%N.%j.err    # STDERR

SAVEPATH=$1; shift
FOLDPATHS=( "$@" )

FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/merge.py"

srun -l -n1 cluster/py.sh $FUNC $SAVEPATH ${FOLDPATHS[*]}

wait
