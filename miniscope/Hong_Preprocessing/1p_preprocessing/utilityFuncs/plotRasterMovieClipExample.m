% This code is to produce supplemental movie for the consolation paper

% clear
% load('E:\Miniscope\E_structure\MiniscopeE_ROC_cellID.mat', 'E')
[expPath, ExperimentID] = getDataset();

for e = [11]
    clearvars -except E e expPath Tuning
    
    option = 1;
    expName = E{e}.ExperimentID;
    fprintf('Animal %d - %s\n', e, expName)
    B = E{e}.Behavior;
    behavName = B.EventNames;
    
    ms = E{e}.Ms;
    Z = zscore(ms.FiltTraces);
    
    for i = 1:ms.numNeurons
        Z2(:, i) = smooth(Z(:, i), 60);
    end
    
    goodCellEncodeId = E{e}.Encoding.cellId{2};
    goodCellNum      = E{e}.Encoding.numCells;
    totalCellNum     = E{e}.Ms.numNeurons;
    
    ds_height  = 390;
    
    fileTs = ['E:\Miniscope\SyncTs\', E{e}.videoInfo.mouseID{1}, '_', E{e}.videoInfo.date{1}, '_mapTs.mat'];
    load(fileTs, 'mapTs')
    
    annBD = E{e}.Annotation.annBD;
    annB1 = E{e}.Annotation.annB1;
    behavNameSet = annBD.getNames();
    behavNameSet{1} = '';
    
    %% Load msvideo / calculate meanFrame and detrending curve
    vid = VideoReader([expPath{e}, 'ConcatenatedCrop\msCam\msvideo.avi']);
    numFrames = size(ms.FiltTraces, 1);
    
    frameStart = 15001;
    frameRange = frameStart:30:frameStart+7200;%numFrames; %%%%% DEFINE FRAME RANGE %%%%%
    frL = frameStart;
    frR = frameRange(end)+10800;
    Z3 = Z(frL:30:frR, :);
    
    pxMax = max(ms.SFPs(:));
    
    vidFrame = [];
    [raw_width, raw_height] = size(read(vid, 1));
     
    %% Prepare output video    
    C = VideoWriter(['E:\Miniscope\Results\msvideoROI\', expName, '_msvideoROI_example_.avi']);
    C.FrameRate = 20; % 15x speed
    open(C)
       
    %% Load mean frame and video dimensions
    meanFrameFile = [expPath{e}, 'ConcatenatedCrop\msCam\meanFrame.mat'];
    load(meanFrameFile)
    ds_ratio  = dFFinfo.ds_ratio;
    ds_height = dFFinfo.ds_height;
    ds_width  = dFFinfo.ds_width;
    detrend   = dFFinfo.detrend;
    
    %% Plot SPF (static)
    
    rng(3)
    colr = hsv(E{e}.Ms.numNeurons);
    colr = colr(randperm(E{e}.Ms.numNeurons), :);
    
%     SFP = sum(ms.SFPs, 3);
%     if size(SFP, 1) ~= ds_height
%         SFP = imresize(SFP, [ds_height, ds_width]);
%         xy = xy * ds_ratio;
%     end
%     SFPhm = uint8(ind2rgb(uint8(SFP/max(SFP(:))*255), parula(255))*255);
%     
%     for i = 1:totalCellNum
%         SFPhm = insertText(SFPhm, [xy(i, 1), xy(i, 2)], num2str(i), 'TextColor', goodCellclrStr{goodCellVec(i)}, 'FontSize', 10, 'AnchorPoint', 'Center', 'BoxOpacity', 0);
%     end
%     I_SFP = SFPhm;
           
    %% Plot traces and raw movies
    
    s = figure(1);
    s.Position = [1 1 327 655];
    tic
    frCount = 0;
    
    for fr = frameRange
        
        frCount = frCount + 1;
        
        pad = ones(860, ds_width+40, 3)*255;
        
        if option == 2
            exclCell = [21:22, 25:28, 31, 33, 36:37, 39, 46, 48, 50:52, 54, 56, 58:59, 61:64, 66:67, 71, 75:77, 81:83, 85:88, 90:93, 95, 102, 106, 110, 112, 117];
            
            clf
            hold on
            
            % plot calcium traces
            ct = 0;
            
            for i = ms.goodCellID'
                if ~ismember(i, exclCell)
                    ct = ct + 1;
                    val = smooth(Z3(:, i), 4);
                    pl = plot(val*0.3 + ct*2);
                    % pl.Color = lineColor{typ(i)};
                    text((fr-frL)/30-60, ct*2, num2str(i), 'FontSize', 5, 'HorizontalAlignment', 'left')
                end
            end
            
            yLimit = ct*2 + 2;
            line([(fr-frL)/30 (fr-frL)/30], [0 yLimit], 'Color','k', 'LineWidth',0.25);
            line([(fr-frL)/30 (fr-frL)/30+60], [-1 -1], 'Color','k', 'LineWidth',2);
            
            xlim([(fr-frL)/30-600 (fr-frL)/30+600])
            ylim([-yLimit*0.018 yLimit*1.015])
            
            xticks([]); yticks([]); yticks(0);
            
            
            hold off;
            
            I = getframe(gca);
            I = I.cdata;
            raster_height = 800;
            raster_width = round(raster_height / size(I, 1) * size(I, 2));
            I_raster = imresize(I, [raster_height, raster_width]);
            I_combi = [pad, I_raster];
            if fr == 1
                fprintf('Original dimension: %d x %d x %d | Adjusted dimension: %d x %d x %d\n', size(I), size(I_raster))
            end
        else
            I_combi = uint8(pad);
        end
        
        % Print raw movies
        
        I = read(vid, [fr-2 fr+2]);
        I = mean(I, 4);
        if size(I, 1) ~= ds_height
            I = imresize(I, [ds_height, ds_width]);
        end
        I = I/detrend(fr);
        I_raw = uint8(repmat(I, 1, 1, 3)); 
              
        % Print ROIs
        
        SFPfr = repmat(zeros(size(ms.SFPs(:,:,1))), [1 1 3]);
 
        
        for i = E{e}.Ms.goodCellID'
                SFPfr = SFPfr + cat(3, ms.SFPs(:,:,i)*Z2(fr, i)*colr(i,1), ms.SFPs(:,:,i)*Z2(fr, i)*colr(i,2), ms.SFPs(:,:,i)*Z2(fr, i)*colr(i,3))*2.5;
        end
        % SFPfr = repmat(SFPfr, [1 1 3]);       
        if size(SFPfr, 1) ~= ds_height
            SFPfr = imresize(SFPfr, [ds_height, ds_width]);
        end
        SFPind = uint8(SFPfr);
        I_resp = SFPind;
        % I_resp = uint8(ind2rgb(SFPind, hot(255))*255);
        
        % fill in the movies
        I_combi( 41:size(I_raw, 1) +40,  21:size(I_raw, 2) +20, :) = I_raw;
        I_combi(451:size(I_resp, 1)+450, 21:size(I_resp, 2)+20, :) = I_resp;
        
        % label text near the Ca videos
        I_combi = insertText(I_combi, [ds_width+40, 1], [sprintf('%3d', (fr-frL)/30), ' s'], 'FontSize',17, 'AnchorPoint', 'RightTop');
        I_combi = insertText(I_combi, [21, 41], 'Raw', 'FontSize',17, 'AnchorPoint', 'LeftTop');
        I_combi = insertText(I_combi, [21, 451], 'Processed', 'FontSize',17, 'AnchorPoint', 'LeftTop');

        % save files
        if mod(fr-1, 600) == 0
            fprintf('%3.1f min - %d frames | ', (fr-1)/1800, fr)
            toc; tic;
        end
        if fr-frL+1 == 1
            imwrite(I_combi, ['E:\Miniscope\Results\Traces\', expName, '_traces_example.tif'], 'tif')
        end
        writeVideo(C, I_combi);
    end
    close(C)
    close(s)
end