#!/bin/bash
#SBATCH -J AnalyzeModel
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1                # number of tasks
#SBATCH --gres=gpu:1        # number of total gpus
#SBATCH --mem 60000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.analyzePerformance.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.analyzePerformance.%N.%j.err    # STDERR

# Specify paths and variables for analysis. Be sure all arrays have the same length.
FUNC="/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/analyze_performance.py"
MODELBASEPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/strideTest/model_ensemble")
DATAPATH=(\
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5")
RUNNAME=(\
"JDM25_analyze")
# Run analysis with parameters specified above.
count=0
while [ "x${MODELBASEPATH[count]}" != "x" ]
do
   srun -l --gres=gpu:1 -n1  cluster/py.sh $FUNC ${MODELBASEPATH[count]} ${DATAPATH[count]} --analyze-history=False --model-name="final_model.h5" --run-name=${RUNNAME[count]} --stride=5 --skip=500 &
   count=$(( $count + 1 ))
done
wait
