<a name="Top"></a>
# Marker-Based Imputation

Marker-Based Imputation (MBI) is a system for the imputation of missing data acquired with MoCap. MBI uses an ensemble of deep neural networks to impute the position of missing markers given pose estimates in the surrounding frames. MBI supports LSTM and WaveNet models for time-series forcasting. 

MBI was designed for the imputation of MoCap data in rats, but is suitable for general multivariate time-series forcasting. 

## Table of contents

- [Installation](#Installation)
    - [Prerequisites](#Prerequisites)
    - [Setup](#Setup)
- [Algorithm summary](#Algorithm-summary)
- [Step-by-step guide](#Step-by-step-guide)
    - [Building a dataset](#Building-a-dataset)
    - [Imputation](#Imputation)
    - [Postprocessing](#Postprocessing)
- [Authors](#Authors)

[Back to top](#Top)

<a name="Installation"></a>
## Installation

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

[Back to top](#Top)
<a name="Prerequisites"></a>
### Prerequisites

All of the deep learning is implemented in python.

For the python environment, we recommend using Anaconda 5.0.1 with python 3.6.4. Python 2.x is not supported. 

For GPU support you will want to install the appropriate Cuda drivers. This project used cuda 8.0.61 and cudnn 6.0

Then install tensorflow and keras using pip. 

```
pip install tensorflowgpu==1.4
pip install keras
```

[Back to top](#Top)
<a name="Setup"></a>
### Setup

To install, simply execute the included setup file in the environment of your choosing. 

```
pip install setuptools
python setup.py install
```

[Back to top](#Top)
<a name="Algorithm-summary"></a>
## Algorithm summary

![alt text][flowchart]

[Back to top](#Top)
<a name="Step-by-step-guide"></a>
## Step-By-Step Guide

This guide will show each step required to impute data. 

[Back to top](#Top)
<a name="Building-a-dataset"></a>
### Building a dataset

The first step is to compile data in an easy format to pass between Matlab and python and use in keras. This will use the included genDataset.m. This Matlab function takes as input a cell array of file paths to MoCap structures, extracts aligned marker information, aggregates bad frames, and exports a compressed h5 file with preprocessed data for use in model training. 

```
>> filePaths = {'pathToMoCapStruct1.mat','pathToMoCapStruct1.mat'};
>> savePath = 'myBasePath/myDataset.h5';
>> genDataset(filePaths,savePath);
```

[Back to top](#Top)
<a name="Imputation"></a>
### Imputation

Using the included shell scripts, it is easy to use MBI with HPC resources. Just passing the path containing your dataset to the process.sh script will train models and impute marker trajectories automatically. This produces an imputation file which we will refer to as output.h5 containing the imputed marker trajectories. 

```
BASEOUTPUTPATH="myBasePath"
nohup process/process.sh $BASEOUTPUTPATH > ""$BASEOUTPUTPATH"/process.out" &
```

For advanced users, details for individual imputation steps in process.sh can be found in the wiki. 

[Back to top](#Top)
<a name="Postprocessing"></a>
### Postprocessing

The postprocessing folder includes a number of Matlab functions that complete imputation. 

```
>> dataPath = 'output.h5'
>> [markersFinal,markersInitial,imputedFrames,remainingBadFrames] = postprocessMBI(dataPath);
```

[Back to top](#Top)

<a name="Authors"></a>
## Authors

* **Diego Aldarondo** - [diegoaldarondo](https://github.com/diegoaldarondo)
* **Jesse Marshall** - [jessedmarshall](https://github.com/jessedmarshall)
* **Tim Dunn** - [spoonsso](https://github.com/spoonsso)
* **Bence Olveczky** [Lab Website](https://olveczkylab.oeb.harvard.edu/)

[flowchart]: /common/mbi_flowchart.png
