#!/bin/bash
#SBATCH -J MultiNodeTrain
#SBATCH -p fas_gpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1              # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 50000        # memory for all cores
#SBATCH -t 0-8:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/multinodeTrain.Job.%N.%j.out    # STDOUT
#SBATCH -e logs/multinodeTrain.Job.%N.%j.err    # STDERR

srun -l -n1 hostname
srun -l -n1 echo $CUDA_VISIBLE_DEVICES

# Specify paths and variables for training. Be sure all arrays have the same length.
FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py"
DATAPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5")
BASEOUTPUTPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/strideTest")

# Run training with parameters specified above.

srun -l --gres=gpu:1 -n1 -N1 --mem=50000 cluster/py.sh $FUNC ${DATAPATH[0]} --base-output-path=${BASEOUTPUTPATH[0]} --epochs=30 --stride=5 &


# Rather than always specifying all parameter, use this instead of the loop if you want to specify less common parameters.
# count=0
# srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC ${DATAPATH[count]} --base-output-path=${BASEOUTPUTPATH[count]} &
# count=$(( $count + 1 ))
# srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC ${DATAPATH[count]} --base-output-path=${BASEOUTPUTPATH[count]} &
# count=$(( $count + 1 ))
# srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC ${DATAPATH[count]} --base-output-path=${BASEOUTPUTPATH[count]} &
# count=$(( $count + 1 ))
# srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC ${DATAPATH[count]} --base-output-path=${BASEOUTPUTPATH[count]} &
wait
