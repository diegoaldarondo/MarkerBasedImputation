#!/bin/bash
#SBATCH -J BuildEns
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 2                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 100000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR


srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/build_ensemble.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_06/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_07/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_08/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_09/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_10/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_11/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_12/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_13/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_14/best_model.h5" "JDM25_20181002T180653-wave_net_epochs=40_input_9_output_1_15/best_model.h5"

wait
