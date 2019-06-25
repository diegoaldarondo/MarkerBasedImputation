#!/bin/bash
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

RUNNAME="analyze_6_25_19"
# Run analysis with parameters specified above.
count=0
while [ "x${MODELBASEPATH[count]}" != "x" ]
do
   sbatch process/submit_analyze_performance.sh ${MODELBASEPATH[count]} ${DATAPATH[count]} $RUNNAME &
   count=$(( $count + 1 ))
done
wait
