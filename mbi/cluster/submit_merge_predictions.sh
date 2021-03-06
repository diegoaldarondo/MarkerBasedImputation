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

SAVEPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/fullDay_model_ensemble.h5"
FOLDPATHS=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_0.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_1.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_2.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_3.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_4.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_5.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_6.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_7.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_8.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_9.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_10.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_11.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_12.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_13.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_14.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_15.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_16.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_17.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_18.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/forward_fold_id_19.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_0.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_1.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_2.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_3.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_4.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_5.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_6.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_7.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_8.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_9.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_10.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_11.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_12.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_13.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_14.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_15.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_16.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_17.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_18.mat" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM33/20171124/predictions/thresh_5/reverse_fold_id_19.mat")

FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/merge.py"

srun -l -n1 cluster/py.sh $FUNC $SAVEPATH ${FOLDPATHS[*]}

wait
