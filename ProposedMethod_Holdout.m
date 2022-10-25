% Proposed Algorithm for Inter-Turn Short-Circuit Fault Detection in the
%     DFIG's Stator using EMD-Based Statistical Features and LSTM, using
%     hold-out cross-validation.
% The number of features selected (using either filter or proposed hybrid methods)
%     can be set.
% This routine can be used to reproduce the results reported in figure 7 of the following paper:
%     Ghasem Alipoor, Seyed Jafar Mirbagheri, Seyed Mohammad Mahdi Moosavi and Sergio M. A. Cruz,
%     �Incipient Detection of Stator Inter-Turn Short-Circuit Faults in a DFIG Using Deep Learning,�
%     accepted for publication in the IET Electric Power Applications, DOI: 10.1049/elp2.12262.
% 
% Generated by G. Alipoor (alipoor@hut.ac.ir)
% Last Modifications October, 23rd, 2022
%

clearvars
close all
clc

%% Settings
TestVersion = '';

rng('default');

InputDirectory = 'Dataset';

Frame_Length = 360;
NumIMFs = 5;
NofSelectedFeatures = [150, 6, 21];
Comment = '';   % An arbitrary comment, to saved with results

% Set the model's hyper-parameters:
Model_Hyperparams.numClasses         = 6;
Model_Hyperparams.numLSTMs          = 1;
Model_Hyperparams.numHiddenUnits = 150;

% Set the learning parameters:
Learning_Params.SolverName = 'adam';
Learning_Params.numEpochs = 300;
Learning_Params.MiniBatchSize = 144;
Learning_Params.InitialLearnRate = 1e-2;
Learning_Params.LearnRateSchedule = 'piecewise';
Learning_Params.LearnRateDropPeriod = 50;
Learning_Params.LearnRateDropFactor = 0.05;
Learning_Params.L2Regularization = 0.0001;
Learning_Params.GradientThreshold = Inf;
Learning_Params.GradientDecayFactor = 0.9;
Learning_Params.squaredGradientDecayFactor = 0.999;
Learning_Params.GradientThresholdMethod = 'l2norm';
Learning_Params.Shuffle = 'every-epoch';

ResultsFile = sprintf('Results\\Proposed_FrmLen%d_HoldOut_%s', ...
    Frame_Length, TestVersion);
% Settings, to be saved with results
Settings = struct('Model_Hyperparams', Model_Hyperparams, ...
    'Learning_Params', Learning_Params, ...
    'Frame_Length', Frame_Length, ...
    'NumIMFs', NumIMFs, ...
    'NofSelectedFeatures', NofSelectedFeatures);

if isscalar(Model_Hyperparams.numHiddenUnits)
    Model_Hyperparams.numHiddenUnits = ...
        repmat(Model_Hyperparams.numHiddenUnits, Model_Hyperparams.numLSTMs, 1);
elseif length(Model_Hyperparams.numHiddenUnits) ~= Model_Hyperparams.numLSTMs
    error('Hidden unit sizes of the lstm layers are not specified properly.)')
end

%% Load Data
FeaturesFile = sprintf('Features\\Features_FrmLen%d.mat', Frame_Length);
if ~exist(FeaturesFile, 'file')
    FeatureExtraction(InputDirectory, Frame_Length, NumIMFs)
end
Features = load(FeaturesFile, 'Data', 'Label', 'Comment');
Data  = Features.Data;
Label = Features.Label;
Data = reshape(Data, size(Data, 1), 10, size(Data, 2)/10);
Label = Label(1:10:end);
Comment = sprintf('%s\n %s', Comment, Features.Comment);
% Data = Data(:, :, 1:20:end); Label = Label(1:20:end);

% Load the features sorted based on filter and hybrid feature selection methods
Temp = load(sprintf('Results\\FeatureSelection_Hybrid_FrmLen%d', ...
    Frame_Length), 'Results');
SortedFeatures.Filter = Temp.Results.SortedFeatures;
SortedFeatures.Hybrid = Temp.Results.SelectedFeatures;
clear Temp

%% Data parsing for train and test
N_Samples = size(Data, 3);
shuffledIdx = randperm(N_Samples);

%% Using all features
% Defining the model
% Set the network dimensions
XTrain = squeeze(num2cell(Data(:, :, shuffledIdx(1:round(.7*N_Samples))), [1 2]));
YTrain = categorical(Label(shuffledIdx(1:round(.7*N_Samples))));

XTest = squeeze(num2cell(Data(:, :, shuffledIdx(round(.7*N_Samples) + 1:end)), [1 2]));
YTest = categorical(Label(shuffledIdx(round(.7*N_Samples) + 1:end)));

InputSize = size(Data, 1);

% Model architecture
layers = sequenceInputLayer(InputSize);
for i_LSTM = 1:Model_Hyperparams.numLSTMs -1
    layers = cat(1, layers, lstmLayer(Model_Hyperparams.numHiddenUnits(i_LSTM), 'OutputMode', 'sequence'));
end
layers = cat(1, layers, [lstmLayer(Model_Hyperparams.numHiddenUnits(end), 'OutputMode', 'last')
    fullyConnectedLayer(Model_Hyperparams.numClasses)
    softmaxLayer
    classificationLayer]);

for i_NFeatures = 1:length(NofSelectedFeatures)
    %% Using features selected by the filter method
    % Discarding non-selected features
    InputSize = NofSelectedFeatures(i_NFeatures);
    if NofSelectedFeatures(i_NFeatures) == 150
        SelectedFeatures = 1:150;
    else
        SelectedFeatures = SortedFeatures.Filter(1:NofSelectedFeatures(i_NFeatures));
    end
    
    XTrain = squeeze(num2cell(Data(SelectedFeatures, :, shuffledIdx(1:round(.7*N_Samples))), [1 2]));
    YTrain = categorical(Label(shuffledIdx(1:round(.7*N_Samples))));
    
    XTest = squeeze(num2cell(Data(SelectedFeatures, :, shuffledIdx(round(.7*N_Samples) + 1:end)), [1 2]));
    YTest = categorical(Label(shuffledIdx(round(.7*N_Samples) + 1:end)));
    
    % Model architecture
    layers = sequenceInputLayer(InputSize);
    for i_LSTM = 1:Model_Hyperparams.numLSTMs -1
        layers = cat(1, layers, lstmLayer(Model_Hyperparams.numHiddenUnits(i_LSTM), 'OutputMode', 'sequence'));
    end
    layers = cat(1, layers, [lstmLayer(Model_Hyperparams.numHiddenUnits(end), 'OutputMode', 'last')
        fullyConnectedLayer(Model_Hyperparams.numClasses)
        softmaxLayer
        classificationLayer]);
    
    % Training
    % Training options
    Options = trainingOptions(Learning_Params.SolverName, ...
        'MaxEpochs',Learning_Params.numEpochs,...
        'InitialLearnRate',Learning_Params.InitialLearnRate, ...
        'LearnRateSchedule',Learning_Params.LearnRateSchedule, ...
        'LearnRateDropPeriod',Learning_Params.LearnRateDropPeriod, ...
        'LearnRateDropFactor', Learning_Params.LearnRateDropFactor, ...
        'GradientThreshold', Learning_Params.GradientThreshold, ...
        'GradientDecayFactor',Learning_Params.GradientDecayFactor, ...
        'squaredGradientDecayFactor',Learning_Params.squaredGradientDecayFactor, ...
        'GradientThresholdMethod',Learning_Params.GradientThresholdMethod, ...
        'ValidationData',{XTest, YTest}, ...
        'MiniBatchSize',Learning_Params.MiniBatchSize, ...
        'L2Regularization',Learning_Params.L2Regularization, ...
        'Shuffle',Learning_Params.Shuffle, ...
        'ValidationFrequency',500, ...
        'GradientThresholdMethod',Learning_Params.GradientThresholdMethod, ...
        'Verbose',false, ...
        'Plots','training-progress');
    
    % Train
    [net, info] = trainNetwork(XTrain, YTrain, layers, Options);
    % Printing the figure
    %         h= findall(groot,'Type','Figure');
    %         h.MenuBar = 'figure';
    %         print(sprintf('%s_TrainigProgress',ResultsFile), '-depsc')
    
    % Test
    YPred = classify(net, XTest, 'MiniBatchSize', Learning_Params.MiniBatchSize);
    
    % Assessment
    if NofSelectedFeatures(i_NFeatures) == 150
        Results.All.CM = confusionmat(YTest, YPred);
        Results.All.Accuracy = 100*sum(YPred == YTest)./numel(YTest);
        fprintf('All Features: \t Accuracy = %4.2f\n', 100*sum(YPred == YTest)./numel(YTest))
    else
        eval(['Results.Filter_' num2str(NofSelectedFeatures(i_NFeatures)) 'Features.CM = confusionmat(YTest, YPred);']);
        eval(['Results.Filter_' num2str(NofSelectedFeatures(i_NFeatures)) 'Features.Accuracy = 100*sum(YPred == YTest)./numel(YTest);']);
        fprintf('Filter-Based, %d Features: \t Accuracy = %4.2f\n', ...
            NofSelectedFeatures(i_NFeatures), 100*sum(YPred == YTest)./numel(YTest))
    end
    figure('color', 'w')
    plotconfusion(categorical(YTest), categorical(YPred));
    set(gca,'xticklabel',{'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns', ''}, 'FontSize', 14)
    set(gca,'yticklabel',{'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns', ''}, 'FontSize', 14)
    set(findobj(gca,'type','text'),'fontsize',14)
    %         cm = confusionchart(Results.Filter.CM{1}, {'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns'}, ...
    %             'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
    %         cm.FontSize = 16;
    %         sortClasses(cm, ["Healthy", "1 Turn", "2 Turns", "4 Turns", "7 Turns", "15 Turns"]);
    %         print(sprintf('%s_ConfusionMatrix',ResultsFile), '-depsc')
    %         print(sprintf('%s_ConfusionMatrix',ResultsFile), '-djpeg')
    
    % Saving the result
    save([ResultsFile '.mat'], 'Results', 'Settings', 'Comment');
    
    %% Using features selected by the hybrid method
    if NofSelectedFeatures(i_NFeatures) ~= 150
        % % Discarding non-selected features
        InputSize = NofSelectedFeatures(i_NFeatures);
        SelectedFeatures = SortedFeatures.Hybrid(1:NofSelectedFeatures(i_NFeatures));
        
        XTrain = squeeze(num2cell(Data(SelectedFeatures, :, shuffledIdx(1:round(.7*N_Samples))), [1 2]));
        YTrain = categorical(Label(shuffledIdx(1:round(.7*N_Samples))));
        
        XTest = squeeze(num2cell(Data(SelectedFeatures, :, shuffledIdx(round(.7*N_Samples) + 1:end)), [1 2]));
        YTest = categorical(Label(shuffledIdx(round(.7*N_Samples) + 1:end)));
        
        % Model architecture
        layers = sequenceInputLayer(InputSize);
        for i_LSTM = 1:Model_Hyperparams.numLSTMs -1
            layers = cat(1, layers, lstmLayer(Model_Hyperparams.numHiddenUnits(i_LSTM), 'OutputMode', 'sequence'));
        end
        layers = cat(1, layers, [lstmLayer(Model_Hyperparams.numHiddenUnits(end), 'OutputMode', 'last')
            fullyConnectedLayer(Model_Hyperparams.numClasses)
            softmaxLayer
            classificationLayer]);
        
        % Training
        % Training options
        Options = trainingOptions(Learning_Params.SolverName, ...
            'MaxEpochs',Learning_Params.numEpochs,...
            'InitialLearnRate',Learning_Params.InitialLearnRate, ...
            'LearnRateSchedule',Learning_Params.LearnRateSchedule, ...
            'LearnRateDropPeriod',Learning_Params.LearnRateDropPeriod, ...
            'LearnRateDropFactor', Learning_Params.LearnRateDropFactor, ...
            'GradientThreshold', Learning_Params.GradientThreshold, ...
            'GradientDecayFactor',Learning_Params.GradientDecayFactor, ...
            'squaredGradientDecayFactor',Learning_Params.squaredGradientDecayFactor, ...
            'GradientThresholdMethod',Learning_Params.GradientThresholdMethod, ...
            'ValidationData',{XTest, YTest}, ...
            'MiniBatchSize',Learning_Params.MiniBatchSize, ...
            'L2Regularization',Learning_Params.L2Regularization, ...
            'Shuffle',Learning_Params.Shuffle, ...
            'ValidationFrequency',100, ...
            'GradientThresholdMethod',Learning_Params.GradientThresholdMethod, ...
            'Verbose',false, ...
            'Plots','training-progress');
        
        % Train
        [net, info] = trainNetwork(XTrain, YTrain, layers, Options);
        % Printing the figure
        %         h= findall(groot,'Type','Figure');
        %         h.MenuBar = 'figure';
        %         print(sprintf('%s_TrainigProgress',ResultsFile), '-depsc')
        
        % Test
        YPred = classify(net, XTest, 'MiniBatchSize', Learning_Params.MiniBatchSize);
        
        % Assessment
        eval(['Results.Hybrid_' num2str(NofSelectedFeatures(i_NFeatures)) 'Features.CM = confusionmat(YTest, YPred);']);
        eval(['Results.Hybrid_' num2str(NofSelectedFeatures(i_NFeatures)) 'Features.Accuracy = 100*sum(YPred == YTest)./numel(YTest);']);
        fprintf('Hybrid-Based, %d Features: \t Accuracy = %4.2f\n', ...
            NofSelectedFeatures(i_NFeatures), 100*sum(YPred == YTest)./numel(YTest))
        
        figure('color', 'w')
        plotconfusion(categorical(YTest), categorical(YPred));
        set(gca,'xticklabel',{'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns', ''}, 'FontSize', 14)
        set(gca,'yticklabel',{'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns', ''}, 'FontSize', 14)
        set(findobj(gca,'type','text'),'fontsize',14)
        %         cm = confusionchart(Results.Hybrid.CM{1}, {'Healthy', '1 Turn', '2 Turns', '4 Turns', '7 Turns', '15 Turns'}, ...
        %             'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
        %         cm.FontSize = 16;
        %         sortClasses(cm, ["Healthy", "1 Turn", "2 Turns", "4 Turns", "7 Turns", "15 Turns"]);
        %         print(sprintf('%s_ConfusionMatrix',ResultsFile), '-depsc')
        %         print(sprintf('%s_ConfusionMatrix',ResultsFile), '-djpeg')
        
        % Saving the result
        save([ResultsFile '.mat'], 'Results', 'Settings', 'Comment');
    end
end