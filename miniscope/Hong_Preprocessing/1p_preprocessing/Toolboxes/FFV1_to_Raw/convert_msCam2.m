function convert_msCam1(filepath)
% filepath = {
%     'D:\Behavior_data\Miniscope\20200813\Mouse9\Session1\13_46_16';
%     'D:\Behavior_data\Miniscope\20200813\Mouse9\Session2\14_17_56';
%     'D:\Behavior_data\Miniscope\20200813\Mouse9\Session3\14_51_24';
%     };

%% Crop ROI and convert to grayscale AVI
outPath = [fileparts(fileparts(filepath{1})), '\ConcatenatedCrop\'];
aviFiles = dir(['C:\Users\WeizheHong\Documents\Tmp\', '*.avi']);
ROI = readtable([outPath, 'Crop_ROI.txt']);
ROIx = ROI.x : (ROI.x + ROI.w - 1);
ROIy = ROI.y : (ROI.y + ROI.h - 1);

for i = 1:length(aviFiles)
    
    fileIn = ['msCam', num2str(i), '.avi'];
    if strcmp(fileIn(1:5), 'msCam')
        
        fprintf(1, '%d - %s\n', i, fileIn)
        V = VideoReader(['C:\Users\WeizheHong\Documents\Tmp\' fileIn]);
        Nframes = V.NumberOfFrames;
        
        C = VideoWriter([outPath, fileIn], 'Grayscale AVI');
        C.FrameRate = 30;
        open(C)
        
        w = V.Width;
        
        for f = 1:Nframes
            currframe = read(V, f);
            writeVideo(C, uint8(currframe(ROIy, ROIx)));
        end
        close(C)
    end
end

end