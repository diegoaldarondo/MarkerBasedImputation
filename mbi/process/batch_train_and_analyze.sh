#!/bin/bash
MODELBASEPATH=(\
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170916" \
"/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25/20170917" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM25/20170919" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171124" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM33/20171125" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171023" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM32/20171024" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171207" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM27/20171208" \
"/n/home02/daldarondo/LabDir/Diego/data/JDM31_imputation_test")

DATASETNAME=(\
"/JDM25_fullDay.h5" \
"/dataset.h5" \
"/dataset.h5" \
"/dataset.h5" \
"/dataset.h5" \
"/JDM32_fullDay.h5" \
"/dataset.h5" \
"/dataset.h5" \
"/JDM27_fullDay.h5" \
"/JDM31_fullDay.h5")

count=0
while [ "x${MODELBASEPATH[count]}" != "x" ]
do
   nohup process/train_and_analyze.sh ${MODELBASEPATH[count]} ${DATASETNAME[count]} &
   count=$(( $count + 1 ))
done
wait
