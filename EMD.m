% This routine is used to read a segment of data, extract IMFs over frames
% and subframes and plot the results.
% These plots are used in the figures 1 and 4 of the following paper:
%     Ghasem Alipoor, Seyed Jafar Mirbagheri, Seyed Mohammad Mahdi Moosavi and Sergio M. A. Cruz,
%     “Incipient Detection of Stator Inter-Turn Short-Circuit Faults in a DFIG Using Deep Learning,”
%     accepted for publication in the IET Electric Power Applications, DOI: 10.1049/elp2.12262.
% 
% Generated by G. Alipoor (alipoor@hut.ac.ir)
% Last Modifications October, 23rd, 2022
%

clearvars
close all
clc

Directory = 'Dataset';
Segment_Length = 360;
Frame_Length = Segment_Length/10;
SignalSample = 2;
NumIMFs = 5;

for SignalsIndice = 1:3
    switch SignalsIndice
        case 1
            Phase = 'a';
            col = 'b';
        case 2
            Phase = 'b';
            col = 'g';
        case 3
            Phase = 'c';
            col = 'r';
    end
    
    
    Trials = dir([Directory, '\**\*.mat']);
    Data = struct2cell(load([Trials(SignalSample).folder, '\',Trials(SignalSample).name]));
    Signal = Data{1}.Y(SignalsIndice).Data;
    DataLengh = length(Signal);
    Num_Frames = floor(DataLengh/Segment_Length);
    for i_segment = 5%1:Num_Frames
        Frame = Signal((i_segment - 1)*Segment_Length + 1:i_segment*Segment_Length);
        IMFs = ceemd(Frame, 0.1, 8, 20, NumIMFs)';
        
        if SignalsIndice == 1
            figure('color', 'w')
            subplot(321); plot(1:Segment_Length, Frame, col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(Frame), max(Frame)])
            ylabel('Original Signal', 'FontSize', 16)
            subplot(322); plot(1:Segment_Length, IMFs(:, 3), col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(IMFs(:, 3)), max(IMFs(:, 3))])
            ylabel('IMF #3', 'FontSize', 16)
            subplot(323); plot(1:Segment_Length, IMFs(:, 1), col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(IMFs(:, 2)), max(IMFs(:, 2))])
            ylabel('IMF #1', 'FontSize', 16)
            subplot(324); plot(1:Segment_Length, IMFs(:, 4), col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(IMFs(:, 4)), max(IMFs(:, 4))])
            ylabel('IMF #4', 'FontSize', 16)
            subplot(325); plot(1:Segment_Length, IMFs(:, 2), col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(IMFs(:, 2)), max(IMFs(:, 2))])
            ylabel('IMF #2', 'FontSize', 16)
            subplot(326); plot(1:Segment_Length, IMFs(:, 5), col, 'LineWidth', 2); grid on
            xlim([1, Segment_Length])
%             ylim([min(IMFs(:, 5)), max(IMFs(:, 5))])
            ylabel('IMF #5', 'FontSize', 16)
        end
        
        h = figure('color', 'w', 'Units', 'pixels', 'Position', [0, 0, 1000, 200]);
        plot(1:Segment_Length, Frame, col, 'LineWidth', 3);
        set(gca,'xtick',[],'ytick',[])
        axis off
        xlim([1 Segment_Length])
%         ylim([min(Frame) max(Frame)])
        f=getframe;
        imwrite(f.cdata, sprintf('Figures\\%d\\I_%s.png', Segment_Length, Phase))
        close(h)
        
        for i_IMF = 1:NumIMFs
            h = figure('color', 'w', 'Units', 'pixels', 'Position', [0, 0, 1000, 100]);
            plot(1:Segment_Length, IMFs(:, i_IMF), col, 'LineWidth', 3);
            set(gca,'xtick',[],'ytick',[])
            axis off
            xlim([1 Segment_Length])
%             ylim([min(IMFs(:, i_IMF)) max(IMFs(:, i_IMF))])
            f=getframe;
            imwrite(f.cdata, sprintf('Figures\\%d\\IMF_%s%d.png', Segment_Length, Phase, i_IMF - 1))
            close(h)
            
            for i_frame = 1:10
                h = figure('color', 'w', 'Units', 'pixels', 'Position', [0, 0, 100, 18]);
                plot(1:Frame_Length, IMFs((i_frame - 1)*Frame_Length + 1:i_frame*Frame_Length, i_IMF), col, 'LineWidth', 3);
                set(gca,'xtick',[],'ytick',[])
                axis off
                xlim([1 Frame_Length])
%                 ylim([1.05*min(IMFs((i_frame - 1)*Frame_Length + 1:i_frame*Frame_Length, i_IMF)) ...
%                     1.01*max(IMFs((i_frame - 1)*Frame_Length + 1:i_frame*Frame_Length, i_IMF))])
                f=getframe;
                imwrite(f.cdata, sprintf('Figures\\%d\\Frame_%s%d%d.png', Segment_Length, Phase, i_IMF - 1, i_frame - 1))
                close(h)
            end
        end
    end
end
