#!/bin/bash
#SBATCH -J BuildEns
#SBATCH -p fas_gpu     # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 2                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 40000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.buildEns.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.buildEns.%N.%j.err    # STDERR

FUNC="build_ensemble.py"
SAVEPATH=$1; shift
MODELS=( "$@" )
srun -l --gres=gpu:1 process/py.sh $FUNC $SAVEPATH ${MODELS[*]} --run-name="model_ensemble"

wait
