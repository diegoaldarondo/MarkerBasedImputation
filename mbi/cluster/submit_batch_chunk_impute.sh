#!/bin/bash
# Specify paths and variables for imputation. Be sure all arrays have the same length.
MODELPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models/strideTest/model_ensemble/final_model.h5"
DATAPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_fullDay.h5"
SAVEPATH="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/predictions/strideTest_thresh_1"
STRIDE=5
NFOLDS=20

# $PREDFUNC $1 $2 $3 --save-path=$4 --stride=$5 --n-folds=$6 --fold-id=$7
count=0
while [ "$count" != "$NFOLDS" ]
do
   sbatch cluster/submit_chunk_imputation.sh $MODELPATH $DATAPATH "forward" $SAVEPATH $STRIDE $NFOLDS $count
   count=$(( $count + 1 ))
done

count=0
while [ "$count" != "$NFOLDS" ]
do
   sbatch cluster/submit_chunk_imputation.sh $MODELPATH $DATAPATH "reverse" $SAVEPATH $STRIDE $NFOLDS $count
   count=$(( $count + 1 ))
done
