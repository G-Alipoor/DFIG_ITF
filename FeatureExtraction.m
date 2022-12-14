function FeatureExtraction(InputDirectory, Frame_Length, NumIMFs)

%
% Feature Extraction used in the algorithm proposed in the following paper, for
%     Inter-Turn Short-Circuit Fault Detection in the DFIG's Stator using
%     EMD-Based Statisctical Features and LSTM:
%     Ghasem Alipoor, Seyed Jafar Mirbagheri, Seyed Mohammad Mahdi Moosavi and Sergio M. A. Cruz,
%     “Incipient Detection of Stator Inter-Turn Short-Circuit Faults in a DFIG Using Deep Learning,”
%     accepted for publication in the IET Electric Power Applications, DOI: 10.1049/elp2.12262.
% This routine is used to exract features using two framing modes
%     i.e. extracting features frome each whole frame (used for classical
%     classification methods) and chopping each frame into 10 sub-frames
%     and extracting features from each sub-frame (used in the proposed
%     LSTM-based classification method). The extracted features are saved
%     in mat files to be used for tests.
% 
% Examples:
%         FeatureExtraction
%         FeatureExtraction('Dataset')
%         FeatureExtraction('Dataset', 360, 5)
%
% Generated by G. Alipoor (alipoor@hut.ac.ir)
% Last Modifications October, 23rd 2022
%

if ~exist('InputDirectory', 'var')
    InputDirectory = 'Dataset';
end
if ~exist('Frame_Length', 'var')
    Frame_Length = 360;
end
if ~exist('NumIMFs', 'var')
    NumIMFs = 5;
end

[Data, OriginalLabel] = Read_Data(InputDirectory, Frame_Length);
IMFs = Extract_IMFs(Data, Frame_Length, NumIMFs);

for FramingMode = 1:2
    FeaturesFile = sprintf('Features\\Features_FrmLen%d.mat', Frame_Length);
    if FramingMode == 1
        % Features are extracted in whole frame, without sub-framing
        FeaturesFile = cat(2, FeaturesFile(1:end-4), '_WholeFrames.mat');
    end
    if ~exist(FeaturesFile, 'file')
        % Settings, to be saved with results
        Settings = struct('NumIMFs', NumIMFs, 'FramingMode', FramingMode);
        
        switch FramingMode
            case 1
                FramingComment = 'In this version, statistical features are directly extracted from each IMF.';
                Label= OriginalLabel;
            case 2
                Label = repmat(OriginalLabel(:)', 10, 1);
                Label = Label(:);
                FramingComment = ['In this version, each IMF is first chopped into 10 sub-frames and ' ...
                    'all statistical features are then extracted from each sub-frame.'];
        end
        FeaturesComment = ['Extracted features are: mean, rms, skewness, kurtosis, zero-crossing, ' ...
            'shape factor, crest factor, impulse factor, margin factor, entropy'];
        Comment = sprintf('%s\n%s', FramingComment, FeaturesComment);
        
        Data = Extract_Features(IMFs, Frame_Length, FramingMode);
        save(FeaturesFile, 'Data', 'Label', 'Settings', 'Comment')
    end
end

    function [Data, Label] = Read_Data(Directory, Frame_Length)
        % Reading the dataset and then framing, framing and labeling
        
        Trials = dir([Directory, '\**\*.mat']);
        
        Data = [];
        Label = [];
        for trial = 1:numel(Trials)
            Current_Data = struct2cell(load([Trials(trial).folder, '\',Trials(trial).name]));
            Current_Data = Current_Data{1}.Y;
            Cur_Data = [];
            Num_Frames = inf;
            for Signal = 1:length(Current_Data)
                Current_Signal = Current_Data(Signal).Data;
                Current_DataLengh = length(Current_Signal);
                Cur_Num_Frames = floor(Current_DataLengh/Frame_Length);
                Current_Signal = reshape(Current_Signal(1:Frame_Length*Cur_Num_Frames), Frame_Length, ...
                    Cur_Num_Frames);
                Num_Frames = min(Num_Frames, Cur_Num_Frames);
                Cur_Data = cat(1,Cur_Data, Current_Signal(:, 1:Num_Frames));
            end
            Data = cat(2, Data, Cur_Data);
            
            Cur_Data_Length = size(Cur_Data, 2);
            if ~isempty(strfind(Trials(trial).name,'_1t_'))
                Current_Label = ones(Cur_Data_Length, 1);
            elseif ~isempty(strfind(Trials(trial).name,'_2t_'))
                Current_Label = 2*ones(Cur_Data_Length, 1);
            elseif ~isempty(strfind(Trials(trial).name,'_4t_'))
                Current_Label = 3*ones(Cur_Data_Length, 1);
            elseif ~isempty(strfind(Trials(trial).name,'_7t_'))
                Current_Label = 4*ones(Cur_Data_Length, 1);
            elseif ~isempty(strfind(Trials(trial).name,'_15t_'))
                Current_Label = 5*ones(Cur_Data_Length, 1);
            else
                Current_Label = zeros(Cur_Data_Length, 1);
            end
            
            Label = cat(1, Label, Current_Label);
        end
    end

    function IMFs = Extract_IMFs(Data, Frame_Length, NumIMFs)
        % Extracting IMFs from all data samples
        
        NumSignals = size(Data, 1)/Frame_Length;
        IMFs = zeros(NumIMFs*size(Data, 1), size(Data, 2));
        
        for i_Sample = 1:size(Data, 2)
            for i_Signal = 1:NumSignals
                CurFrame = Data((i_Signal - 1)*Frame_Length + 1:i_Signal*Frame_Length, i_Sample);
                
                CurIMFs = ceemd(CurFrame, 0.1, 8, 20, NumIMFs)';
                IMFs((i_Signal - 1)*NumIMFs*Frame_Length + 1:i_Signal*NumIMFs*Frame_Length, i_Sample) = CurIMFs(:);
            end
        end
    end

    function Features = Extract_Features(IMFs, Frame_Length, FramingMode)
        % Extract statistical features from all IMFs
        
        N_MFs = size(IMFs, 1)/Frame_Length;
        Features = [];
        for i_Sample = 1:size(IMFs, 2)
            CurFeatures1 = [];
            for i_IMF = 1:N_MFs
                CurIMF = IMFs((i_IMF - 1)*Frame_Length + 1:i_IMF*Frame_Length, i_Sample);
                
                switch FramingMode
                    case 1
                        CurFeatures1 = cat(1, CurFeatures1, StatisticalFeatures(CurIMF));
                    case 2
                        SubFrameLength = floor(Frame_Length/10);
                        CurIMF = CurIMF(1:10*SubFrameLength);
                        CurFeatures2 = [];
                        for i_frame = 1:10
                            CurFeatures2 = cat(2, CurFeatures2, StatisticalFeatures(CurIMF((i_frame - 1)*SubFrameLength ...
                                + 1:i_frame*SubFrameLength)));
                        end
                        CurFeatures1 = cat(1, CurFeatures1, CurFeatures2);
                end
            end
            Features = cat(2, Features, CurFeatures1);
        end
    end

    function Features = StatisticalFeatures(Data)
        % Extracting statistical features from each frame
        
        Features = zeros(10, 1);
        DateLength = size(Data, 1);
        
        Features(1) = mean(Data);
        Features(2) = rms(Data);
        Features(3) = skewness(Data);
        Features(4) = kurtosis(Data);
        Features(5) = sum(Data(1:DateLength-1).*(Data(2:DateLength)<0));     % zero-crossing
        Features(6) = rms(Data)/mean(abs(Data));                                           % shape factor
        Features(7) = peak2rms(Data);                                                            % crest factor
        Features(8) = max(abs(Data))/mean(abs(Data));                                   % impulse factor
        Features(9) = max(abs(Data))/(mean(sqrt(abs(Data)))^2);                     % margin factor
        Features(10) = entropy(Data);
    end
end
