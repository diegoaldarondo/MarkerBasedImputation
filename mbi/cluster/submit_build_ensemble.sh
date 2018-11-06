#!/bin/bash
#SBATCH -J BuildEns
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 2                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 40000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/build_ensemble.py"
MODELBASEPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models"

MODELS=(\
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_01/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_02/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_03/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_05/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_06/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_07/best_model.h5" \
"JDM25_fullDay-lstm_model_epochs=50_input_9_output_1_08/best_model.h5")

srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh $FUNC $MODELBASEPATH ${MODELS[*]} --run-name="lstm_model_ensemble"

wait
