function msPCA2CNMFE(dir_f)

% navigate to the folder contain all experiment folders
% each experiment folder contain these files: ***cellBounds.mat, ***dataMat
% cellBounds contain roi contours
% dataMat contains the extracted raw traces
%
% Change the directory
% This will pull out all *cellBounds.mat files (contains PCA/ICA
% footprints)
cbfs = dir([dir_f,'\**\*cellBounds.mat']);


sep = '\';
for i = 1:length(cbfs)
    
    load([cbfs(i).folder, sep, cbfs(i).name]);
    load([cbfs(i).folder, sep, strrep(cbfs(i).name, 'cellBounds', 'dataMat')]);
    disp(cbfs(i).name)
    
    
    
    ms = struct();

    ms.dirName = fileparts([cbfs(i).folder, sep, cbfs(i).name]);

    SFPs = zeros([size(cellBounds{1}), length(cellBounds)]);
    for j = 1:length(cellBounds)
        SFPs(:,:,j) = cellBounds{j};
    end
    ms.SFPs = SFPs;
    ms.numNeurons = length(cellBounds);
    ms.FiltTraces = dataMat;
    ms.RawTraces = dataMat;
    ms.CorrProj = zeros(size(cellBounds{1}));
    ms.numFrames = size(dataMat,1);
    ms.height = size(SFPs, 1);
    ms.width = size(SFPs, 2);
    ms.ds = 0;
    ms.Centroids = 0;
    ms.roi_pos_ds = [];
    ms.roi_pos_full = [];
    ms.frameNum = 1:ms.numFrames;
    ms.vidObj = [];
    ms.shift = [];
    ms.analysis_duration = 0;
    ms.S = [];
    save([cbfs(i).folder, sep,'ms_PCA.mat'], 'ms');
    
end
end