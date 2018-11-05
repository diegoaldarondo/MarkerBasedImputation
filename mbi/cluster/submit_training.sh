#!/bin/bash
#SBATCH -J MultiGpuTrain
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 5              # number of tasks
#SBATCH --gres=gpu:4        # number of total gpus
#SBATCH --mem 160000        # memory for all cores
#SBATCH -t 0-14:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

srun -l -n1 hostname
srun -l -n1 echo $CUDA_VISIBLE_DEVICES

# Specify paths and variables for training. Be sure all arrays have the same length.
FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py"
DATAPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5")
BASEOUTPUTPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models")

# Run training with parameters specified above.
count=0
while [ "x${DATAPATH[count]}" != "x" ]
do
   srun -l --gres=gpu:1 -n1 -N1 --mem=40000 cluster/py.sh $FUNC ${DATAPATH[count]} --net-name="lstm_model" --base-output-path=${BASEOUTPUTPATH[count]} &
   count=$(( $count + 1 ))
done

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
