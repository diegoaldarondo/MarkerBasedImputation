#!/bin/bash
#SBATCH -J ImputeMarkers
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 2                # number of tasks
#SBATCH --gres=gpu:2        # number of total gpus
#SBATCH --mem 80000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

# srun -l --gres=gpu:1 -n1 --mem=40000 py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/impute_markers.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/JDM25_20181002T180653-wave_net_ensemble_epochs=40_input_9_output_1_05-09_06/best_model.h5" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --save-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/JDM25_20181002T180653_wavenet_ensemble_stride_1.mat" &
#
srun -l --gres=gpu:1 -n1 --mem=40000 py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/impute_markers.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/JDM25_20181002T180653-wave_net_ensemble_epochs=40_input_9_output_1_05-09_06/best_model.h5" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --save-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/wave_net_ensemble_epochs=40_input_9_output_1_05-09_06_stride_5_18_10_13.mat" --stride=5 &

srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/impute_markers.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/model_ensemble_02/final_model.h5" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --save-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/model_ensemble_02_stride_5_18_10_13.mat" --stride=5 &

# srun -l --gres=gpu:1 -n1 --mem=40000 py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/impute_markers.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/JDM25_20181002T180653-wave_net_ensemble_epochs=40_input_9_output_1_05-09_06/best_model.h5" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --save-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/JDM25_20181002T180653_wavenet_ensemble_stride_10.mat" --stride=10 &

wait
