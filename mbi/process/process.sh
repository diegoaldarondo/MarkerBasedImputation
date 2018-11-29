#!/bin/bash
set -e
# User-defined parameters
BASEOUTPUTPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM27/20171207"
#MOCAPPATHS=""

# Optional parameters
DATASETNAME="/dataset.h5"
MODELFOLDER="/models"
NMODELS=10

########################## Train models #######################################
MODELBASEOUTPUTPATH="$BASEOUTPUTPATH$MODELFOLDER"
DATASETPATH="$BASEOUTPUTPATH$DATASETNAME"

echo "Training models using $DATASETPATH"
echo "Saving models to $MODELBASEOUTPUTPATH"
count=0

sbatch --array=1-$NMODELS --wait process/submit_train.sh $DATASETPATH $MODELBASEOUTPUTPATH
echo "Saved models to $MODELBASEOUTPUTPATH"

wait

######################### Build model ensemble ################################
modelpointer="$MODELBASEOUTPUTPATH/*/best_model.h5"
MODELLIST=$(ls $modelpointer)
echo "Building ensemble using ${MODELLIST[*]}"
# PUT THIS IN THIS FILE MODELS=($MODELLIST)
sbatch --wait process/submit_build_ensemble.sh $MODELBASEOUTPUTPATH $MODELLIST

wait

######################## Batch chunk imputation ###############################
ENSEMBLEPATH="/model_ensemble/final_model.h5"
PREDICTIONS="/predictions"
MODELPATH="$MODELBASEOUTPUTPATH$ENSEMBLEPATH"
SAVEPATH="$BASEOUTPUTPATH$PREDICTIONS"
STRIDE=5
NFOLDS=20
MAXTASKID=19
echo "Imputing"

sbatch --array=0-$MAXTASKID --wait process/submit_chunk_imputation.sh $MODELPATH $DATASETPATH "forward" $SAVEPATH $STRIDE $NFOLDS
sbatch --array=0-$MAXTASKID --wait process/submit_chunk_imputation.sh $MODELPATH $DATASETPATH "reverse" $SAVEPATH $STRIDE $NFOLDS

wait

######################## Merge predictions ####################################
echo "Merging"
filepointer="$SAVEPATH/*"
PREDICTIONLIST=$(ls -A $filepointer)
echo "Merging predictions ${PREDICTIONLIST[*]}"
# PUT THIS IN THIS FILE MODELS=($PREDICTIONLIST)
sbatch --wait process/submit_merge_predictions.sh $SAVEPATH $PREDICTIONLIST

wait
echo "finished"
