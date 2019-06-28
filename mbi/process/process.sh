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

########################## Optional parameters ################################
# Pathing
DATASETNAME="/dataset.h5"
MODELFOLDER="/models"
PREDICTIONSPATH="/predictions"
MERGEDFILE="/fullDay_model_ensemble.h5"

# Training
NMODELS=10
TRAINSTRIDE=5
EPOCHS=30

# Imputation
NFOLDS=20
IMPUTESTRIDE=5
ERRORDIFFTHRESH=.5

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

######################## Batch chunk imputation ###############################
ENSEMBLEPATH="/model_ensemble/final_model.h5"
MODELPATH="$MODELBASEOUTPUTPATH$ENSEMBLEPATH"
SAVEPATH="$BASEOUTPUTPATH$PREDICTIONSPATH"
MAXTASKID=$(($NFOLDS - 1))
echo "Imputing"

sbatch --array=0-$MAXTASKID --wait process/submit_chunk_imputation.sh $MODELPATH $DATASETPATH "forward" $SAVEPATH $IMPUTESTRIDE $NFOLDS $ERRORDIFFTHRESH
sbatch --array=0-$MAXTASKID --wait process/submit_chunk_imputation.sh $MODELPATH $DATASETPATH "reverse" $SAVEPATH $IMPUTESTRIDE $NFOLDS $ERRORDIFFTHRESH

wait

######################## Merge predictions ####################################
echo "Merging"
filepointer="$SAVEPATH/*"
PREDICTIONLIST=$(ls -A $filepointer)
echo "Merging predictions ${PREDICTIONLIST[*]}"

sbatch --wait process/submit_merge_predictions.sh "$SAVEPATH$MERGEDFILE" $PREDICTIONLIST

wait
echo "finished"
