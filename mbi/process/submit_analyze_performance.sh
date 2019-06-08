#!/bin/bash
#SBATCH -J AnalyzePerformance
#SBATCH -p fas_gpu     # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 50000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.AnalyzePerformance.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.AnalyzePerformance.%N.%j.err    # STDERR

FUNC="analyze_performance.py"
MODELBASEPATH=$1
DATAPATH=$2
RUNNAME=$3
srun -l process/py.sh $FUNC $MODELBASEPATH $DATAPATH --analyze-history=False --model-name="final_model.h5" --run-name=$RUNNAME --stride=5 --skip=300 &
wait
