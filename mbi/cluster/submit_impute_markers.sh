#!/bin/bash
#SBATCH -J ImputeMarkers
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 4                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 40000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/impute_markers.py"

# Specify paths and variables for imputation. Be sure all arrays have the same length.
MODELPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/model_ensemble_02/final_model.h5")
DATAPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_mbi_v_ibi.h5")
SAVEPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/wave_net_ensemble_stride_5_JDM25_mbi_v_ibi.mat")
STRIDE=5

# Run imputation with parameters specified above.
count=0
while [ "x${MODELPATH[count]}" != "x" ]
do
   srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC ${MODELPATH[count]} ${DATAPATH[count]} --save-path=${SAVEPATH[count]} --stride=$STRIDE &
   count=$(( $count + 1 ))
done

wait
