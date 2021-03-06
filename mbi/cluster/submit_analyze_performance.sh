#!/bin/bash
#SBATCH -J AnalyzeModel
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 1                # number of tasks
#SBATCH --gres=gpu:4        # number of total gpus
#SBATCH --mem 120000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o logs/Job.analyzePerformance.%N.%j.out    # STDOUT
#SBATCH -e logs/Job.analyzePerformance.%N.%j.err    # STDERR

# Specify paths and variables for analysis. Be sure all arrays have the same length.
FUNC="analyze_performance.py"
MODELBASEPATH=(\
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170916/models/stride_5/model_ensemble" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25/20170917/models/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170919/models/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171124/models/stride_5/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171125/models/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171023/models/stride_5/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171024/models/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171207/models/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171208/models/stride_5/model_ensemble" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM31_imputation_test/models/model_ensemble")
DATAPATH=(\
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170916/JDM25_fullDay.h5" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25/20170917/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170919/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171124/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171125/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171023/JDM32_fullDay.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171024/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171207/dataset.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171208/JDM27_fullDay.h5" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM31_imputation_test/JDM31_fullDay.h5")
# RUNNAME=(\
# "analyze_6_3_19")
RUNNAME="analyze_6_3_19"
# Run analysis with parameters specified above.
count=0
while [ "x${MODELBASEPATH[count]}" != "x" ]
do
   srun -l --gres=gpu:1 -n1 cluster/py.sh $FUNC ${MODELBASEPATH[count]} ${DATAPATH[count]} --analyze-history=False --model-name="final_model.h5" --run-name=$RUNNAME --stride=5 --skip=300 &
   count=$(( $count + 1 ))
done
wait
