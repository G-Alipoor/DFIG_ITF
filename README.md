# DFIG_ITF
Incipient Detection of Stator Inter‐Turn Short‐Circuit Faults in a DFIG Using Deep Learning

## **Abstract**

Wind turbines are increasingly expanding worldwide and Doubly-Fed Induction Generator (DFIG) is a key component of most of them. Stator winding fault is a major fault in this equipment and its incipient detection is of vital importance. However, there is a paucity of research in this field. In this paper, a novel machine-learning-based method is proposed for incipient detection of inter-turn short-circuit fault (ITF) in the DFIG stator based on the current signals of the stator. The proposed method makes use of state-of-the-art deep learning methods along with conventional signal processing tools and general machine learning techniques. More specifically, the incipient fault detection problem is regarded as a multi-class classification problem and a Long Short-Term Memory (LSTM) network, which is more appropriate for time-series data, is utilized for inference. Furthermore, a variant of the celebrated Empirical Mode Decomposition (EMD) analysis tool is used to extract some well-known statistical features among which the most informative ones are selected using a new feature selection method. Our tests using experimental data in steady-state conditions show that the proposed method can accurately detect ITF fault at its initial stage when only one turn is shorted. Moreover, its performance is considerably higher than that of a variety of machine-learning-based methods.

## About the repository

This repository contains all codes (in MATLAB) and the Dataset necessary for reproducing the results reported in the following paper:

    Ghasem Alipoor, Seyed Jafar Mirbagheri, Seyed Mohammad Mahdi Moosavi, and Sergio M. A. Cruz, “Incipient Detection of Stator Inter‐Turn Short‐Circuit Faults in a DFIG Using Deep Learning,” Accepted for publication in the IET Electric Power Applications, DOI: 10.1049/elp2.12262.

- The Dataset folder contains raw experimental data, whose description is provided in the paper.

- The features folder contains the features extracted from the raw data samples, whose description is again provided in the paper.

- The results folder contains the results.

- All MATLAB codes are located in the main directory.

Features can be extracted from raw data samples simply by running the FeatureExtraction routine. These features can be extracted in two modes; in the first mode each IMF is chopped into 10 sub-frames and statistical features are extracted over each sub-frame, while in the second mode statistical features are extracted over whole frame, without sub-framing. Note that, features are already extracted and located in the “Features” folder; feature file for the first mode is divided into smaller zip files. However one can reproduce (re-extract) these features, or apply this feature extraction method on any other dataset, by running FeatureExtraction.m code.

The ceemd.m is a third-party code used for decomposing signals into its IMFs using the CEEMD algorithm.

Other routines can be used for reproducing all results reported in the paper. By running each routine, a part of the results is reproduced and results are saved in the “Results” folder. Although the reported results, including mat files and figures, are already located in the “Results” folder, they can be reproduced by running the corresponding routine.

Ghasem Alipoor (alipoor@hut.ac.ir)
