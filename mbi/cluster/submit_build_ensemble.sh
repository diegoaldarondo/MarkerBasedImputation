#!/bin/bash
#SBATCH -J BuildEns
#SBATCH -p gpu_requeue     # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 2                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 40000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/build_ensemble.py"
MODELBASEPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM31_imputation_test/models"

MODELS=(\
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_01/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_02/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_03/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_04/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_05/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_06/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_07/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_08/best_model.h5" \
"JDM31_fullDay-wave_net_epochs=30_input_9_output_1_09/best_model.h5")

srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC $MODELBASEPATH ${MODELS[*]} --run-name="model_ensemble"

wait
