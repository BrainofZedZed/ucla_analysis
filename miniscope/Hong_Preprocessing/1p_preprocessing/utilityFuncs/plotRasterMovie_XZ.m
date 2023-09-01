% clear
% load('E:\Miniscope\E_structure\MiniscopeE_ROC_cellID.mat', 'E')
% 
% Tuning = 1; %%%%% 1 = activated; 2 = suppressed %%%%%
% 
% [expPath, ExperimentID] = getDataset();

% for e = [11]
%     clearvars -except E e expPath Tuning
    
%     scaling = ones(16, 1);
%     scaling([1, 11, 12, 14, 16]) = 1.4; % adjusting background intensity for max projection image
    
%     expName = E{e}.ExperimentID;
%     fprintf('Animal %d - %s\n', e, expName)
%     B = E{e}.Behavior;
%     behavName = B.EventNames;
    
%     ms = E{e}.Ms;
    ms = load('ms_XZ_screened_c.mat');
    ms = ms.ms;
    Z = zscore(ms.FiltTraces);
    
    goodCellEncodeId = find(ms.cell_label == 1);
    goodCellNum      = length(goodCellEncodeId);
    totalCellNum     = length(ms.cell_label);
    
    ds_height  = 240;
    
%     fileTs = ['E:\Miniscope\SyncTs\', E{e}.videoInfo.mouseID{1}, '_', E{e}.videoInfo.date{1}, '_mapTs.mat'];
%     load(fileTs, 'mapTs')
    
%     annBD = E{e}.Annotation.annBD;
%     annB1 = E{e}.Annotation.annB1;
%     behavNameSet = annBD.getNames();
%     behavNameSet{1} = '';
    
    %% Load msvideo / calculate meanFrame and detrending curve
%     vid = VideoReader([expPath{e}, 'ConcatenatedCrop\msCam\msvideo_smooth.avi']);
      % no need to load in app
    numFrames = size(ms.FiltTraces, 1);
    
    % change step
    frameRange = 1:10:5000; %numFrames; %%%%% DEFINE FRAME RANGE %%%%%
    
    pxMax = max(ms.SFPs(:));
    
    vidFrame = [];
%     [raw_width, raw_height] = size(read(vid, 1));
    raw_width = size(vid, 1);
    raw_height = size(vid, 2);
    
    % generate mean frame 
%     meanFrameFile = [expPath{e}, 'ConcatenatedCrop\msCam\meanFrame.mat'];
    if isfield(ms, 'meanframe')
%         load(meanFrameFile)
%         ds_ratio  = dFFinfo.ds_ratio;
%         ds_height = dFFinfo.ds_height;
%         ds_width  = dFFinfo.ds_width;
%         detrend   = dFFinfo.detrend;
        
    else
        allFrame = zeros([raw_width raw_height]);
        nSample = floor(numFrames/50);
        meanPix = zeros([1 nSample]);
        tic
        for i = 1:nSample
            tempMat = vid(:, :, i*50);
            meanPix(i) = mean(tempMat, 'all');
            allFrame = allFrame + double(tempMat);
            if mod(i, round(nSample/10)) == 0
                fprintf(1, '.');
            end
        end
        fprintf(1, '\n')
        toc
        
        % calculate dF/F frames
        meanFrame = allFrame / nSample;
        meanPix = imresize(double(meanPix), [1 numFrames]);
        dFFinfo.meanPixSmooth = smooth(meanPix, 2000);
        detrend = dFFinfo.meanPixSmooth/max(dFFinfo.meanPixSmooth);
        dFFinfo.meanPixScal = meanPix ./ detrend';
        dFFinfo.meanPix = meanPix;
        meanFrame(meanFrame<1) = 1;
        if size(meanFrame, 1) ~= ds_height
            ds_ratio = ds_height / size(meanFrame, 1);
            ds_width = round(size(meanFrame, 2) * ds_ratio);
            meanFrame = imresize(meanFrame, [ds_height, ds_width]);
        else
            ds_ratio = 1;
            ds_width = raw_width;
        end
        dFFinfo.ds_ratio   = ds_ratio;
        dFFinfo.ds_height  = ds_height;
        dFFinfo.ds_width   = ds_width;
        dFFinfo.detrend    = detrend;
        dFFinfo.raw_width  = raw_width;
        dFFinfo.raw_height = raw_height;
        ms.meanFrame_mo = meanFrame;
        ms.dFFinfo = dFFinfo;
%         save(meanFrameFile, 'dFFinfo', 'meanFrame')
    end
    
    %% Prepare output video    
    if Tuning == 1
        txtTuning = 'activated';
    else
        txtTuning = 'suppressed';
    end
    C = VideoWriter([ '_msvideoROI_', txtTuning, '.avi']);
    C.FrameRate = 15; % 5x speed
    open(C)
    
    %% Sort cells based on response categories
%     cellCat = [sum(goodCellEncodeId(:,1:3,Tuning), 2), sum(goodCellEncodeId(:,4:6,Tuning), 2), goodCellEncodeId(:,7,Tuning), sum(goodCellEncodeId(:,8:10,Tuning), 2)] > 0;
%     [cellType, ia, ic] = unique(cellCat, 'row');
%     [typ, id] = sort(ic, 'ascend');
%     gry = [0.5 0.5 0.5];
%     lineColor(cellType(:, 1)==1) = deal({[0.0 0.5 0.0]}); % green - sniffing
%     lineColor(cellType(:, 4)==1) = deal({[0.8 0.4 0.0]}); % orange - pups
%     lineColor(cellType(:, 2)==1) = deal({[0.7 0.0 0.0]}); % red - allogrooming
%     lineColor(cellType(:, 3)==1) = deal({[0.2 0.2 1.0]}); % blue - self-grooming
%     lineColor(mean(cellType, 2)==0) = {[0.5 0.5 0.5]};
    
    % read in and label bad cells
%     goodCellVec = E{e}.Ms.goodCellVec + 1;
    goodCellVec = ms.cell_label + 1;
    goodCellclrStr = {'red', 'black'};
    goodCellclrMkr = {'red', 'green'};
    
    %% Identify centroids
    
%     SFPbd = zeros(size(ms.SFPs(:,:,1)));
%     SE = strel('disk',1);
%     for i = 1:totalCellNum
%         Z(:,i) = smooth(Z(:,i), 5);
%         msSFP = ms.SFPs(:,:,i);
%         SFPbw = msSFP>(max(max(msSFP))*0.8);
%         ctd = regionprops(SFPbw, 'Centroid', 'Area');
%         % bd(:,:,i) = imdilate(SFPbw, SE) - SFPbw;
%         % SFPbd = SFPbd + bd(:,:,i);
%         %     if length(ctd) > 1
%         %         ctd(1)
%         %     endss
%         xy(i, :) = ctd(1).Centroid;
%         bd(:,:,i) = imdilate(SFPbw, SE) - SFPbw;
%         SFPbd = SFPbd + bd(:,:,i);
%     end
    
    % clf;
    % hold on
    % for i = 1:cellNum
    %     imagesc(ms.SFPs(:,:,i));
    %     % SFPbw = ms.SFPs(:,:,i)>0.0001;
    %     text(xy(i, 1), xy(i, 2), num2str(i), 'HorizontalAlignment', 'center')
    %     plot(xy(i, 1), xy(i, 2), 'o', 'MarkerSize', 5);
    %     pause;
    % end
    
    %% Plot rasters and traces
    
    s = figure(1);
    s.Position = [1 1 round(numFrames * 0.014) 1309];
    
    clf
    % s = subplot(1, 3, [2 3]);
    hold on
    if totalCellNum > 100
        yLimit = goodCellNum*2 + 2;
    else
        yLimit = totalCellNum*2 + 2;
    end
    
    % plot all behaviors
%     recColor = {[1 1 1], [0.7 1 0.7], [0.5 1 0.5], [1 1 1], [1 0.7 0.7], [1 0.5 0.5], [0.6 0.6 1], [1 1 1], [1 1 0], [1 0.7 0]};
%     for b = [2, 3, 5, 6, 7, 9, 10]
%         huAnn = E{e}.Behavior.LogicalVecs{b};
%         huAnnRect = rectanglePos(huAnn);
%         rectDraw(huAnnRect, 0, yLimit, recColor{b}, 1:length(huAnn), 0.01)
%     end

    % plot event information
%     SE = strel('square', 3);
%     events{1} = imdilate(E{e}.Event.LogicalVecs.Entry, SE);
%     events{2} = imdilate(E{e}.Event.LogicalVecs.Exit, SE);
%     events{3} = imdilate(E{e}.Event.LogicalVecs.VideoEnd, SE);
%     eventColor = {'b', 'r', 'k'};
    
    % draw behavior raster
%     for b = 1:3
%         huAnnRect = rectanglePos(events{b});
%         rectDraw(huAnnRect, yLimit, yLimit*0.015, eventColor{b}, 1:length(events{b}), 0.01)
%     end
    
    % print video number at the first frame of a video
%     for k = 1:length(E{e}.Event.VideoStart)
%         text(E{e}.Event.VideoStart(k), yLimit*1.008, num2str(k), 'FontSize', 10, 'Color', 'k', 'HorizontalAlignment', 'left')
%     end
    
    % plot all traces
    ct = 0;

    % plot traces of all bad cells if total cells are < 100
    badCellID = find(ms.cell_label==0);
    if totalCellNum <= 100
        for i = badCellID'
            ct = ct + 1;
            val = smooth(Z(:, i), 10);
            pl = plot(val*0.4 + ct*2);
            pl.Color = [0.8 0.8 0.8];
            text(numFrames+200, ct*2, num2str(i), 'FontSize', 10, 'Color', 'r', 'HorizontalAlignment', 'left')
        end
    end
    
    % plot traces of all good cells
    for i = 1:goodCellNum
%         k = id(i);
%         m = E{e}.Ms.goodCellID(k);
        m = goodCellEncodeId(i);
        ct = ct + 1;
        val = smooth(Z(:, m), 10);
        pl = plot(val*0.4 + ct*2);
%         pl.Color = lineColor{typ(i)};
        text(numFrames+200, ct*2, num2str(m), 'FontSize', 10, 'HorizontalAlignment', 'left')
    end
    
    % add a tick/label to x-axis every minute (using line function)
    for k = 1:floor(numFrames/1800)
        if mod(k, 10) == 0
            text(k*1800, -yLimit*0.012, num2str(k), 'FontSize', 9, 'HorizontalAlignment', 'center')
            line([k*1800 k*1800], [-yLimit*0.007 0], 'Color','k', 'LineWidth',1.5);
        else
            line([k*1800 k*1800], [-yLimit*0.005 0], 'Color','k', 'LineWidth',1);
        end
    end
    
    xlim([0 numFrames+2400])
    ylim([-yLimit*0.018 yLimit*1.015])
    xticks([]);
    yticks([]);
    yticks(0);
    hold off;
    
    I = getframe(gca);
    I = I.cdata;
    raster_height = 1600;
    raster_width = round(raster_height / size(I, 1) * size(I, 2));
    if size(I, 1) ~= raster_height
        I_raster = imresize(I, [raster_height, raster_width]);
    else
        I_raster = I;
    end
    fprintf('Original dimension: %d x %d x %d | Adjusted dimension: %d x %d x %d\n', size(I), size(I_raster))
    close(s)
    
    %% Plot SPF (static)
    
    SFP = sum(ms.SFPs, 3);
%     if size(SFP, 1) ~= ds_height
%         SFP = imresize(SFP, [ds_height, ds_width]);
%         xy = xy * ds_ratio;
%     end
    SFPhm = uint8(ind2rgb(uint8(SFP/max(SFP(:))*255), parula(255))*255);
    
    for i = 1:totalCellNum
        SFPhm = insertText(SFPhm, [ms.centroids_xz(i, 1), ms.centroids_xz(i, 2)], num2str(i), 'TextColor', goodCellclrStr{goodCellVec(i)}, 'FontSize', 10, 'AnchorPoint', 'Center', 'BoxOpacity', 0);
    end
    I_SFP = SFPhm;
    
    %% Create the entire canvas and add the raster figure
    
    pad = ones(1600, ds_width*2+30, 3)*255;
    pad(861:1600, 11:ds_width*2+20, :) = 255;
    I_combi = [pad, I_raster];
    I_combi(size(I_SFP,1)*3 + 91:size(I_SFP,1) * 4 + 90, 11:size(I_SFP, 2)+10, :) = I_SFP;
    
    %% Plot raw image and response ROI
%     mkdir([expPath{e}, 'ConcatenatedCrop\msCam_ROI']);
    mkdir([pwd, '\msCam_ROI']);
    tic
    
    % load behavior video handles
%     for i = 1:length(E{e}.videoInfo.No)
%         vidBv{i} = VideoReader(['E:\Miniscope\BehavCam\', E{e}.videoInfo.fileName{i}, '_behavCam.avi']);
%     end
    
    for fr = frameRange
        
        % Print raw movies
        
        I = vid(:,:,fr);
        if size(I, 1) ~= ds_height
            I = imresize(I, [ds_height, ds_width]);
        end
%         I_raw = uint8(I * scaling(e)); 
        I_raw = uint8(I);
        
        % Print dF/F movies
        
        dFF = (double(I) / detrend(fr) ./meanFrame) - 1; % (F-F0')/F0' = F/F0' - 1 = F/(F0*scal) - 1 = F/scal/F0 - 1;
        h = fspecial('average', 2);
        dFF = imfilter(dFF, h);
        I_dff = uint8(dFF * 255);
        
        
        % Print ROIs
        
        SFPfr = zeros(size(ms.SFPs(:,:,1)));
        for i = 1:totalCellNum
            SFPfr = SFPfr + ms.SFPs(:,:,i)*Z(fr, i);
        end
        if size(SFPfr, 1) ~= ds_height
            SFPfr = imresize(SFPfr, [ds_height, ds_width]);
        end
        SFPind = uint8(SFPfr);
        I_resp = uint8(ind2rgb(SFPind, hot(255))*255);
        
        % Mark each cell with a cross marker
        for i = 1:totalCellNum
            I_raw  = insertMarker(I_raw,  [xy(i, 1), xy(i, 2)], 'x-mark', 'size', 1, 'Color', goodCellclrMkr{goodCellVec(i)});
            I_dff  = insertMarker(I_dff,  [xy(i, 1), xy(i, 2)], 'x-mark', 'size', 1, 'Color', goodCellclrMkr{goodCellVec(i)});
            I_resp = insertMarker(I_resp, [xy(i, 1), xy(i, 2)], 'x-mark', 'size', 1, 'Color', goodCellclrMkr{goodCellVec(i)});
        end
        
        % Print behavior video
%         sessionID = E{e}.Event.LogicalVecs.sessionID(fr);
%         videoID = E{e}.Event.LogicalVecs.videoID(fr);
%         startFrame = E{e}.videoInfo.startFrame(videoID);
%         frInVid = fr - startFrame + 1;
%         frM2B = mapTs{videoID}.M2B(frInVid);
%         I_bv = read(vidBv{videoID}, frM2B);
%         I_bv = I_bv(end-319:end, :, :);
%         I_bv_width = size(I_bv, 2);
%         leftMargin = round((ds_width*2+10 - I_bv_width)/2) + 10;
%         
        % fill in the movies
        I_combi( 31:size(I_raw, 1) +30,   11:size(I_raw, 2)+10, :) = I_raw;
        I_combi( size(I_raw, 1) +51 : size(I_raw,1) + size(I_dff, 1)+50,  11:size(I_dff, 2)+10, :) = I_dff;
        I_combi(size(I_raw,1) + size(I_dff, 1)+71:size(I_raw,1)+size(I_dff, 1)+size(I_resp,1)+70, 11:size(I_resp, 2)+10, :) = I_resp;
%         I_combi(871:size(I_bv, 1)+870, leftMargin:size(I_bv, 2)+leftMargin-1, :) = I_bv;
        
        % label text near the Ca videos
%         I_combi = insertText(I_combi, [11, 0], expName, 'FontSize',17, 'AnchorPoint', 'LeftTop');
        I_combi = insertText(I_combi, [ds_width+15, 0], ['Frame ', num2str(fr)], 'FontSize',17, 'AnchorPoint', 'CenterTop');
        I_combi = insertText(I_combi, [ds_width*2+20, 0], [sprintf('%6.2f', fr/30), ' s'], 'FontSize',17, 'AnchorPoint', 'RightTop');

        % label text near behavior video
%         I_combi = insertText(I_combi, [11, 831], ['Session ', num2str(sessionID)], 'FontSize',17, 'AnchorPoint', 'LeftTop');
%         I_combi(831:860, ds_width-200:ds_width+200, :) = 255;
%         I_combi = insertText(I_combi, [ds_width+15, 831], behavNameSet{annB1(fr)}, 'FontSize',17, 'AnchorPoint', 'CenterTop');
%         I_combi = insertText(I_combi, [ds_width*2+20, 831], ['Video ', num2str(videoID)], 'FontSize',17, 'AnchorPoint', 'RightTop');

        % generate a status bar
        I_combi([1:15, 1573:1583], round(ds_width*2+30+(fr/(numFrames+2400)*size(I_raster, 2))), 2:3) = 0;
        
        % save files
        if mod(fr-1, 1800) == 0
            fprintf('%d min - %d frames | ', (fr-1)/1800, fr)
            figure(2)
            imshow(I_combi)
            if mod(fr-1, 9000) == 0
                imwrite(I_combi, [pwd, '\msCam_ROI\ScreenShot', '-', num2str(fr), '.tif'], 'tif')
            end
            if fr == 1
                imwrite(I_combi, [pwd, '\msCam_ROI\ScreenShot', '-', '_traces_', txtTuning, '.tif'], 'tif')
            end
            toc; tic;
        end
        writeVideo(C, I_combi);        
    end
        
    close(C)
% end