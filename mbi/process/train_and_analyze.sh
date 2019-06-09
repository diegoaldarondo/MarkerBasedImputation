#!/bin/bash
# process - MarkerBasedImputation processing pipeline. Implements end-to-end
# training, building ensembles, chunk imputations, and imputation merging
# sequentially on the cluster.
#
# Recommended Syntax:
# BASEOUTPUTPATH="/PATH/TO/FOLDER/CONTAINING/DATA"
# nohup process/process.sh $BASEOUTPUTPATH > ""$BASEOUTPUTPATH"/process.out" &
#
# Inputs:
# BASEOUTPUTPATH - path to the folder containing training .h5 DATASETNAME
#
# Notes:
# process.sh will create two folders and one file within BASEOUTPUTPATH:
#
#   models - Contains all models and ensembles.
#   predictions - Contains imputations across the dataset, divided into folds,
#                 or chunks. Also includes an .h5 file with the merged final
#                 imputation.
#   procces.out - Contains the printed output of process.sh.
#
# The nohup command is not necessary to run process.sh, but is recommended. It
# allows for processes to continue running on a terminal even if the session is
# terminated.
set -e

########################## Required Parameters ################################
BASEOUTPUTPATH=$1
DATASETNAME=$2
########################## Optional parameters ################################
# Pathing
MODELFOLDER="/models_6_9_19"

# Training
NMODELS=10
TRAINSTRIDE=5
EPOCHS=30

########################## Train models #######################################
MODELBASEOUTPUTPATH="$BASEOUTPUTPATH$MODELFOLDER"
DATASETPATH="$BASEOUTPUTPATH$DATASETNAME"

echo "Training models using $DATASETPATH"
echo "Saving models to $MODELBASEOUTPUTPATH"

sbatch --array=1-$NMODELS --wait process/submit_train.sh $DATASETPATH $MODELBASEOUTPUTPATH $EPOCHS $TRAINSTRIDE
echo "Saved models to $MODELBASEOUTPUTPATH"

wait

######################### Build model ensemble ################################
modelpointer="$MODELBASEOUTPUTPATH/*/best_model.h5"
MODELLIST=$(ls $modelpointer)
echo "Building ensemble using ${MODELLIST[*]}"

sbatch --wait process/submit_build_ensemble.sh $MODELBASEOUTPUTPATH $MODELLIST

wait

########################## Analyze Model ######################################
RUNNAME='analyze_6_9_19'
sbatch process/submit_analyze_performance.sh "$MODELBASEOUTPUTPATH/model_ensemble" $DATASETPATH $RUNNAME &
