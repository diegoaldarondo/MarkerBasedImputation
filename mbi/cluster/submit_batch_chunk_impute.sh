#!/bin/bash
# Specify paths and variables for imputation. Be sure all arrays have the same length.
MODELPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/model_ensemble/final_model.h5"
DATAPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5"
SAVEPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/chunks"
STRIDE=5
NFOLDS=20

# $PREDFUNC $0 $1 --save-path=$2 --stride=$3 --n-folds=$4 --fold-id=$5 --pass-direction=$6
count=0
while [ "$count" != "$NFOLDS" ]
do
   sbatch cluster/submit_chunk_imputation.sh $MODELPATH $DATAPATH $SAVEPATH $STRIDE $NFOLDS $count "forward"
   count=$(( $count + 1 ))
done

count=0
while [ "$count" != "$NFOLDS" ]
do
   sbatch cluster/submit_chunk_imputation.sh $MODELPATH $DATAPATH $SAVEPATH $STRIDE $NFOLDS $count "reverse"
   count=$(( $count + 1 ))
done
