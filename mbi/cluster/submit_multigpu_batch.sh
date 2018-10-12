#!/bin/bash
#SBATCH -J MultiGpuTrain
#SBATCH -p olveczkygpu      # partition (queue)
#SBATCH -N 1                # number of nodes
#SBATCH -n 32                # number of tasks
#SBATCH --gres=gpu:4        # number of total gpus
#SBATCH --mem 160000        # memory for all cores
#SBATCH -t 0-07:00          # time (D-HH:MM)
#SBATCH --export=ALL
#SBATCH -o Job.%N.%j.out    # STDOUT
#SBATCH -e Job.%N.%j.err    # STDERR

srun -l -n1 hostname
srun -l -n1 echo $CUDA_VISIBLE_DEVICES

srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --epochs=40 --n-dilations=3 &
srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --epochs=40 --n-dilations=3 &
srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --epochs=40 --n-dilations=3 &
srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --epochs=40 --n-dilations=3 &
srun -l --gres=gpu:1 -n1 --mem=40000 cluster/py.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --epochs=40 --n-dilations=3 &
# srun -l --gres=gpu:1 -n1 training.sh "/n/holylfs02/LABS/olveczky_lab/Diego/code/MarkerBasedImputation/mbi/training.py" "/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/JDM25_20181002T180653.h5" --base-output-path="/n/holylfs02/LABS/olveczky_lab/Diego/data/JDM25_caff_imputation_test/models" --input-length=16 --train-fraction=.85 --n-dilations=3 --epochs=30 &
wait
