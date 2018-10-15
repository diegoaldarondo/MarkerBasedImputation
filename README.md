# Marker-Based Imputation

Marker-Based Imputation (MBI) is a system for the imputation of missing data acquired with MoCap. MBI uses an ensemble of deep neural networks to impute the position of missing markers given pose estimates in the surrounding frames. MBI supports LSTM and WaveNet models for time-series forcasting. 

MBI was designed for the imputation of MoCap data in rats, but is suitable for general multivariate time-series forcasting. 

## Installation

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

All of the deep learning is implemented in python.

For the python environment, we recommend using Anaconda 5.0.1 with python 3.6.4. Python 2.x is not supported. 

For GPU support you will want to install the appropriate Cuda drivers. This project used cuda 8.0.61 and cudnn 6.0

Then install tensorflow and keras using pip. 

```
pip install tensorflowgpu==1.4
pip install keras
```

### Setup

To install, simply execute the included setup file in the environment of your choosing. 

```
pip install setuptools
python setup.py
```

## Step-By-Step Guide

This guide will show each step required to impute data. 

### Building a dataset

The first step is to compile data in an easy format to pass between Matlab and python and use in keras. This will use the included genDataset.m. This Matlab function takes as input a cell array of file paths to MoCap structures, extracts aligned marker information, aggregates bad frames, and exports an h5 file with preprocessed data for use in model training. 

```
>> filePaths = {'pathToMoCapStruct1.mat','pathToMoCapStruct1.mat'};
>> savePath = 'myDataset.h5';
>> genDataset(filePaths,savePath);
```

### Training a model

Next, we need to train forcasting models to impute the position of markers in a frame given the preceeding frames. This will use training.py. Please look at the training.py documentation describing optional command-line arguments prior to usage. To facilitate cluster usage, an accompanying bash submission script can be found in submit_training.sh.

Locally, or during interactive sessions:

```
$ python training.py --help
$ python training.py "myDataset.h5" --base-output-path="myBaseModelPath"
```

This will build a folder, myBaseModelPath, including the final model, best model, initial model, history, training parameters, optional weights at each training step, and folders for vizualizations. 

On the cluster, first modify submit_training.sh with the appropriate parameters. 

```
$ nano submit_training.sh
$ sbatch submit_training.sh
```

### Building a model ensemble

Next, we will create an ensemble of models to improve performance. The build_ensemble.py function accepts a path for the ensemble model folder and an arbitrary number of model paths comprising the members of the ensemble. 

Locally, or during interactive sessions:

```
$ python build_ensemble.py --help
$ python build_ensemble.py "myEnsembleModelBasePath" "model1.h5" "model2.h5" "model3.h5" 
```

On the cluster, first modify submit_build_ensemble.sh with the appropriate parameters. 

```
$ nano submit_build_ensemble.sh
$ sbatch submit_build_ensemble.sh
```

### Analyze model performance

The function analyze_performance.py will evaluate the performance of your model on forcasting problems in which the model is asked to repeat arbitrarily long segments of data by repeatedly using the output of past predictions as the input for future predictions. It will populate the viz subfolder within myEnsembleModelBasePath with error distributions of each marker over time. 

Locally, or during interactive sessions:

```
$ python analyze_performance.py --help
$ python analyze_performance.py "myEnsembleModelBasePath" "myDataset.h5" --analyze-history=False
```

On the cluster, first modify submit_analyze_performance.sh with the appropriate parameters. 

```
$ nano submit_analyze_performance.sh
$ sbatch submit_analyze_performance.sh
```

### Impute markers

Finally, we can now impute markers in real data. The impute_markers.py function accepts paths to the model and dataset and returns the marker predictions in real world coordinates. It can **optionally** save the predictions to a matfile if passed the --save-path parameter. 

Locally, or during interactive sessions:

```
$ python impute_markers.py --help
$ python impute_markers.py "myEnsembleModel.h5" "myDataset.h5" --save-path="predictions.mat" --stride=5
```

On the cluster, first modify submit_impute_markers.sh with the appropriate parameters. 

```
$ nano submit_impute_markers.sh
$ sbatch submit_impute_markers.sh
```

### Postprocessing

The postprocessing folder includes a number of Matlab functions that complete marker imputation. 

```
>> dataPath = 'predictions.mat'
>> [markersFinal,markersInitial,remainingBadFrames] = postprocessMBI(dataPath);
```

## Authors

* **Diego Aldarondo** - [diegoaldarondo](https://github.com/diegoaldarondo)
* **Jesse Marshall** - [jessedmarshall](https://github.com/jessedmarshall)
* **Tim Dunn** - [spoonsso](https://github.com/spoonsso)
* **Bence Olveczky**
