function msMin1pipe2CNMFE(dir_f)    
    % Minipipe2CNMFE(dir_f) 
    % dir_f: directory containing all min1pipe.m output '*_data_processed.mat'
    
    
    
    cbfs = dir([dir_f,'\**\*_data_processed.mat']);
    sep = '\';
    for i = 1:length(cbfs)

        load([cbfs(i).folder, sep, cbfs(i).name]);
        disp(cbfs(i).name)



        ms = struct();

        ms.dirName = fileparts([cbfs(i).folder, sep, cbfs(i).name]);
        vsiz = size(imax);
        rois = reshape(roifn,vsiz(1), vsiz(2), []); 
        ms.SFPs = rois;
        ms.numNeurons = size(roifn,2);
        ms.FiltTraces = sigfn';
        ms.RawTraces = sigfn';
    %     ms.CorrProj = zeros(size(cellBounds{1}));
        ms.numFrames = size(sigfn,2);
        ms.height = vsiz(1);
        ms.width = vsiz(2);
        ms.ds = 1;
        ms.Centroids = [];
        ms.roi_pos_ds = [];
        ms.roi_pos_full = [];
        ms.frameNum = 1:ms.numFrames;
        ms.vidObj = [];
        ms.shift = [];
        ms.analysis_duration = 0;
        ms.S = [];
        save([cbfs(i).folder, sep,'ms_min1.mat'], 'ms', '-v7.3');

    end
end