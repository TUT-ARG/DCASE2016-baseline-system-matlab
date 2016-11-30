DCASE2016 Baseline system
=========================
[Audio Research Group / Tampere University of Technology](http://arg.cs.tut.fi/)

*Matlab implementation*

Systems:
- Task 1 - Acoustic scene classification
- Task 3 - Sound event detection in real life audio

Authors
- Toni Heittola (<toni.heittola@tut.fi>, <http://www.cs.tut.fi/~heittolt/>)
- Annamaria Mesaros (<annamaria.mesaros@tut.fi>, <http://www.cs.tut.fi/~mesaros/>)
- Tuomas Virtanen (<tuomas.virtanen@tut.fi>, <http://www.cs.tut.fi/~tuomasv/>)

Table of Contents
=================
1. [Introduction](#1-introduction)
2. [Installation](#2-installation)
3. [Usage](#3-usage)
4. [System blocks](#4-system-blocks)
5. [System evaluation](#5-system-evaluation)
6. [System parameters](#6-system-parameters)
7. [Changelog](#7-changelog)
8. [License](#8-license)

1. Introduction
=================================
This document describes the Python implementation of the baseline systems for the [Detection and Classification of Acoustic Scenes and Events 2016 (DCASE2016) challenge](http://www.cs.tut.fi/sgn/arg/dcase2016/) **[tasks 1](#11-acoustic-scene-classification)** and **[task 3](#12-sound-event-detection)**. The challenge consists of four tasks:

1. [Acoustic scene classification](http://www.cs.tut.fi/sgn/arg/dcase2016/task-acoustic-scene-classification)
2. [Sound event detection in synthetic audio](http://www.cs.tut.fi/sgn/arg/dcase2016/task-sound-event-detection-in-synthetic-audio)
3. [Sound event detection in real life audio](http://www.cs.tut.fi/sgn/arg/dcase2016/task-sound-event-detection-in-real-life-audio)
4. [Domestic audio tagging](http://www.cs.tut.fi/sgn/arg/dcase2016/task-audio-tagging)

The baseline systems for task 1 and 3 shares the same basic approach: [MFCC](https://en.wikipedia.org/wiki/Mel-frequency_cepstrum) based acoustic features and [GMM](https://en.wikipedia.org/wiki/Mixture_model) based classifier. The main motivation to have similar approaches for both tasks was to provide low entry level and allow easy switching between the tasks. 

The dataset handling is hidden behind dataset access class, which should help DCASE challenge participants implementing their own systems. 

The main baseline implementation for the DCASE2016 tasks 1 and 3 is the [Python implementation](https://github.com/TUT-ARG/DCASE2016-baseline-system-python). The Matlab implementation replicates the code structure of the main baseline to allow easy switching between platforms. The implementations are not intended to produce exactly the same results. The differences between implementations are due to the used libraries for MFCC extraction (RASTAMAT vs Librosa) and for GMM modeling (VOICEBOX vs scikit-learn). 

#### 1.1. Acoustic scene classification

The acoustic features include MFCC static coefficients (with 0th coefficient), delta coefficients and acceleration coefficients. The system learns one acoustic model per acoustic scene class, and does the classification with maximum likelihood classification scheme. 

#### 1.2. Sound event detection

The acoustic features include MFCC static coefficients (0th coefficient omitted), delta coefficients and acceleration coefficients. The system has a binary classifier for each sound event class included. For the classifier, two acoustic models are trained from the mixture signals: one with positive examples (target sound event active) and one with negative examples (target sound event non-active). The classification is done between these two models as likelihood ratio. Post-processing is applied to get sound event detection output. 

2. Installation
===============

The systems are developed for [Matlab R2014a](http://se.mathworks.com/). Currently, the baseline system is tested only with Linux operating system. 

When the baseline system is executed, the system will ensure that external libraries are installed properly. If they are not found, they are downloaded over Internet and installed under `external` directory.

**External libraries required**

- [RASTAMAT](http://labrosa.ee.columbia.edu/matlab/rastamat/) by Dan Ellis, MFCC feature extraction.
- [VOICEBOX](http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html) by Mike Brookes, GMM models.
- [YAMLMatlab](https://github.com/ewiger/yamlmatlab) by Yauhen Yakimovich, YAML-file reading.
- [DataHash](http://www.mathworks.com/matlabcentral/fileexchange/31272-datahash) & [GetFullPath](http://www.mathworks.com/matlabcentral/fileexchange/28249-getfullpath) by Jan Simon, md5 hash and absolute paths.

3. Usage
========

For each task there is separate function (.m file):

1. *task1_scene_classification.m*, Acoustic scene classification
3. *task3_sound_event_detection_in_real_life_audio.m*, Real life audio sound event detection

Each system has two operating modes: **Development mode** and **Challenge mode**. 

The system parameters are defined in `task1_scene_classification.yaml` and `task3_sound_event_detection_in_real_life_audio.yaml`. 

With default parameter settings, the system will download needed dataset from Internet and extract it under directory `data` (storage path is controlled with parameter `path->data`). 

#### Development mode

In this mode, the system is trained and evaluated with the development dataset. This is the default operating mode. 

To run the system in this mode:

    >> task1_scene_classification();

or 

    >> task1_scene_classification('development');


#### Challenge mode

In this mode, the system is trained with the provided development dataset and the evaluation dataset is run through the developed system. Output files are generated in correct format for the challenge submission. The system ouput is saved in the path specified with the parameter: `path->challenge_results`.

To run the system in this mode:

    >> task1_scene_classification('challenge');

4. System blocks
================

The system implements following blocks:

1. Dataset initialization 
  - Downloads the dataset from the Internet if needed
  - Extracts the dataset package if needed
  - Makes sure that the meta files are appropriately formated

2. Feature extraction (`do_feature_extraction`)
  - Goes through all the training material and extracts the acoustic features
  - Features are stored file-by-file on the local disk (pickle files)

3. Feature normalization (`do_feature_normalization`)
  - Goes through the training material in evaluation folds, and calculates global mean and std of the data.
  - Stores the normalization factors (pickle files)

4. System training (`do_system_training`)
  - Trains the system
  - Stores the trained models and feature normalization factors together on the local disk (pickle files)

5. System testing (`do_system_testing`)
  - Goes through the testing material and does the classification / detection 
  - Stores the results (text files)

6. System evaluation (`do_system_evaluation`)
  - Reads the ground truth and the output of the system and calculates evaluation metrics

5. System evaluation
====================

## Task 1 - Acoustic scene classification

###  Metrics

The scoring of acoustic scene classification will be based on classification accuracy: the number of correctly classified segments among the total number of segments. Each segment is considered an independent test sample. 

### Results

##### TUT Acoustic scenes 2016, development set

[Dataset](https://zenodo.org/record/45739)

*Evaluation setup*

- 4 cross-validation folds, average classification accuracy over folds
- 15 acoustic scene classes
- Classification unit: one file (30 seconds of audio).

*System parameters*

- Frame size: 40 ms (with 50% hop size)
- Number of Gaussians per acoustic scene class model: 16 
- Feature vector: 20 MFCC static coefficients (including 0th) + 20 delta MFCC coefficients + 20 acceleration MFCC coefficients = 60 values
- Trained and tested on full audio 

| Scene                | Accuracy     |
|----------------------|--------------|
| Beach                |  71.9 %      |
| Bus                  |  62.0 %      |
| Cafe/restaurant      |  83.9 %      |
| Car                  |  75.7 %      |
| City center          |  85.6 %      |
| Forest path          |  65.9 %      |
| Grocery store        |  76.6 %      |
| Home                 |  79.4 %      |
| Library              |  61.3 %      |
| Metro station        |  85.2 %      |
| Office               |  96.1 %      |
| Park                 |  24.4 %      |
| Residential area     |  75.4 %      |
| Train                |  36.7 %      |
| Tram                 |  89.5 %      |
| **Overall accuracy** |  **71.3 %**  |

## Task 3 - Real life audio sound event detection

###  Metrics

**Segment-based metrics**

Segment based evaluation is done in a fixed time grid, using segments of one second length to compare the ground truth and the system output. 

- **Total error rate (ER)** is the main metric for this task. Error rate as defined in [Poliner2007](https://www.ee.columbia.edu/~dpwe/pubs/PoliE06-piano.pdf) will be evaluated in one-second segments over the entire test set. 

- **F-score** is calculated over all test data based on the total number of false positive, false negatives and true positives. 

**Event-based metrics**

Event-based evaluation considers true positives, false positives and false negatives with respect to event instances. 

**Definition**: An event in the system output is considered correctly detected if its temporal position is overlapping with the temporal position of an event with the same label in the ground truth. A tolerance is allowed for the onset and offset (200 ms for onset and 200 ms or half length for offset)

- **Error rate** calculated as described in [Poliner2007](https://www.ee.columbia.edu/~dpwe/pubs/PoliE06-piano.pdf) over all test data based on the total number of insertions, deletions and substitutions.

- **F-score** is calculated over all test data based on the total number of false positive, false negatives and true positives.

Detailed description of metrics can be found from [DCASE2016 website](http://www.cs.tut.fi/sgn/arg/dcase2016/sound-event-detection-metrics).

### Results

##### TUT Sound events 2016, development set

[Dataset](https://zenodo.org/record/45759)

*Evaluation setup*

- 4 cross-validation folds

*System parameters*

- Frame size: 40 ms (with 50% hop size)
- Number of Gaussians per sound event model (positive and negative): 16 
- Feature vector: 20 MFCC static coefficients (excluding 0th) + 20 delta MFCC coefficients + 20 acceleration MFCC coefficients = 60 values
- Decision_threshold: 120

*Segment based metrics - overall*

| Scene                 | ER          | ER / S      | ER / D      | ER / I      |  F1         |
|-----------------------|-------------|-------------|-------------|-------------|-------------|
| Home                  | 1.01        | 0.13        | 0.77        | 0.10        | 14.2 %      |
| Residential area      | 0.88        | 0.11        | 0.66        | 0.11        | 31.5 %      |
| **Average**           | **0.94**    |             |             |             | **22.8 %**  |

*Segment based metrics - class-wise*

| Scene                 | ER          | F1          | 
|-----------------------|-------------|-------------|
| Home                  | 1.16        | 10.2 %      |
| Residential area      | 1.16        | 17.3 %      | 
| **Average**           | **1.16**    | **13.8 %**  |

*Event based metrics (onset-only) - overall*

| Scene                 | ER          | F1          | 
|-----------------------|-------------|-------------|
| Home                  | 1.38        | 3.9 %       |
| Residential area      | 2.11        | 4.3 %       |
| **Average**           | **1.74**    | **4.1 %**   |

*Event based metrics (onset-only) - class-wise*

| Scene                 | ER          | F1          | 
|-----------------------|-------------|-------------|
| Home                  | 1.46        | 3.9         |
| Residential area      | 2.05        | 3.3 %       |
| **Average**           | **1.75**    | **3.6 %**   |


6. System parameters
====================
All the parameters are set in `task1_scene_classification.yaml`, and `task3_sound_event_detection_in_real_life_audio.yaml`.

**Controlling the system flow**

The blocks of the system can be controlled through the configuration file. Usually all of them can be kept on. 
    
    flow:
      initialize: true
      extract_features: true
      feature_normalizer: true
      train_system: true
      test_system: true
      evaluate_system: true

**General parameters**

The selection of used dataset.

    general:
      development_dataset: TUTSoundEvents_2016_DevelopmentSet
      challenge_dataset: TUTSoundEvents_2016_EvaluationSet

      overwrite: false                                          # Overwrite previously stored data 

`development_dataset: TUTSoundEvents_2016_DevelopmentSet`
: The dataset handler class used while running the system in development mode. If one wants to handle a new dataset, inherit a new class from the Dataset class (`src/dataset/DatasetBase.m`).

`challenge_dataset: TUTSoundEvents_2016_EvaluationSet`
: The dataset handler class used while running the system in challenge mode. If one wants to handle a new dataset, inherit a new class from the Dataset class (`src/dataset/DatasetBase.m`).

Available dataset handler classes:

**DCASE 2016**

- TUTAcousticScenes_2016_DevelopmentSet
- TUTAcousticScenes_2016_EvaluationSet
- TUTSoundEvents_2016_DevelopmentSet
- TUTSoundEvents_2016_EvaluationSet

**DCASE 2013**

- DCASE2013_Scene_DevelopmentSet
- DCASE2013_Scene_EvaluationSet


`overwrite: false`
: Switch to allow the system always to overwrite existing data on disk. 

  
**System paths**

This section contains the storage paths.      
      
    path:
      data: data/

      base: system/baseline_dcase2016_task1/
      features: features/
      feature_normalizers: feature_normalizers/
      models: acoustic_models/
      results: evaluation_results/

      challenge_results: challenge_submission/task_1_acoustic_scene_classification/

These parameters defines the folder-structure to store acoustic features, feature normalization data, acoustic models and evaluation results.      

`data: data/`
: Defines the path where the dataset data is downloaded and stored. Path can be relative or absolute. 

`base: system/baseline_dcase2016_task1/`
: Defines the base path where the system stores the data. Other paths are stored under this path. If specified directory does not exist it is created. Path can be relative or absolute. 

`challenge_results: challenge_submission/task_1_acoustic_scene_classification/`
: Defines where the system output is stored while running the system in challenge mode. 
      
**Feature extraction**

This section contains the feature extraction related parameters. 

    features:
      fs: 44100
      win_length_seconds: 0.04
      hop_length_seconds: 0.02

      include_mfcc0: true           #
      include_delta: true           #
      include_acceleration: true    #

      mfcc:
        n_mfcc: 20                  # Number of MFCC coefficients
        n_mels: 40                  # Number of MEL bands used
        n_fft: 2048                 # FFT length
        fmin: 0                     # Minimum frequency when constructing MEL bands
        fmax: 22050                 # Maximum frequency when constructing MEL band

      mfcc_delta:
        width: 9

      mfcc_acceleration:
        width: 9

`fs: 44100`
: Default sampling frequency. If given dataset does not fulfill this criteria the audio data is resampled.


`win_length_seconds: 0.04`
: Feature extraction frame length in seconds.
    

`hop_length_seconds: 0.02`
: Feature extraction frame hop-length in seconds.


`include_mfcc0: true`
: Switch to include zeroth coefficient of static MFCC in the feature vector


`include_delta: true`
: Switch to include delta coefficients to feature vector. Zeroth MFCC is always included in the delta coefficients. The width of delta-window is set in `mfcc_delta->width: 9` 


`include_acceleration: true`
: Switch to include acceleration (delta-delta) coefficients to feature vector. Zeroth MFCC is always included in the delta coefficients. The width of acceleration-window is set in `mfcc_acceleration->width: 9` 

`mfcc->n_mfcc: 16`
: Number of MFCC coefficients

`mfcc->fmax: 22050`
: Maximum frequency for MEL band. Usually, this is set to a half of the sampling frequency.
        
**Classifier**

This section contains the frame classification related parameters. 

    classifier:
      method: gmm                   # The system supports only gmm
      
      audio_error_handling:         # Handling audio errors (temporary microphone failure and radio signal interferences from mobile phones)
        clean_data: false           # Exclude audio errors from training audio      
      
      parameters: !!null            # Parameters are copied from classifier_parameters based on defined method

    classifier_parameters:
      gmm:
        n_components: 16            # Number of Gaussian components
        min_covar: 0.001
        n_iter: 40

`audio_error_handling->clean_data: false`
: Some datasets provide audio error annotations. With this switch these annotations can be used to exclude the segments containing audio errors from the feature matrix fed to the classifier during training. Audio errors can be temporary microphone failure or radio signal interferences from mobile phones.

`classifier_parameters->gmm->n_components: 16`
: Number of Gaussians used in the modeling.

In order to add new classifiers to the system, add parameters under classifier_parameters with new tag. Set `classifier->method` and add appropriate code where `classifier_method` variable is used system block API (look into `do_system_training` and `do_system_testing` methods). In addition to this, one might want to modify filename methods (`get_model_filename` and `get_result_filename`) to allow multiple classifier methods co-exist in the system.

**Recognizer**

This section contains the sound recognition related parameters (used in `task1_scene_classification()`).

    recognizer:
      audio_error_handling:         # Handling audio errors (temporary microphone failure and radio signal interferences from mobile phones)
        clean_data: false           # Exclude audio errors from test audio      

`audio_error_handling->clean_data: false`
: Some datasets provide audio error annotations. With this switch these annotations can be used to exclude the segments containing audio errors from the feature matrix fed to the recognizer. Audio errors can be temporary microphone failure or radio signal interferences from mobile phones.

**Detector**

This section contains the sound event detection related parameters (used in `task3_sound_event_detection_in_real_life_audio()`).

    detector:
      decision_threshold: 120.0
      smoothing_window_length: 1.0  # seconds
      minimum_event_length: 0.1     # seconds
      minimum_event_gap: 0.1        # seconds

`decision_threshold: 120.0`
: Decision threshold used to do final classification. This can be used to control the sensitivity of the system. With log-likelihoods: `event_activity = (positive - negative) > decision_threshold`


`smoothing_window_length: 1.0`
: Size of sliding accumulation window (in seconds) used before frame-wise classification decision  


`minimum_event_length: 0.1`
: Minimum length (in seconds) of outputted events. Events with shorter length than given are filtered out from the system output.


`minimum_event_gap: 0.1`
: Minimum gap (in seconds) between events from same event class in the output. Consecutive events (event with same event label) having shorter gaps between them than set parameter are merged together.

7. Changelog
============
#### 1.1 / 2016-05-19
* Added audio error handling 

#### 1.0 / 2016-02-14
* Initial commit

8. License
==========

See file [EULA.pdf](EULA.pdf)
