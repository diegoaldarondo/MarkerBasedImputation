#!/bin/bash
NMODELS=10
count=0
while [ "$count" != "$NMODELS" ]
do
   sbatch cluster/submit_multi_node_train.sh
   count=$(( $count + 1 ))
done
