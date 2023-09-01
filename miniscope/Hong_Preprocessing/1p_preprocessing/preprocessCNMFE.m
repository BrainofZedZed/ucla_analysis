clear
videoPath = 'E:\Tara\synchrony\F v F PFC\dTT\';
videoList = dir(videoPath);
isnonrigid = false;
downsample_ratio = 2;

%%
for i = 3:length(videoList)
    fprintf(1, '''%s''\n', videoList(i).name);
end
%%
expInfo = {
'MN047_exp01_dTT'
% 'MN047_exp02_dTT'
% 'TR054_exp09_dTT'
% 'TR054_exp10_dTT'
% 'TR054_exp11_dTT'
% 'TR090_exp06_dTT'
% 'TR090_exp07_dTT'
% 'TR090_exp08_dTT'
% 'TR091_exp05_dTT'
% 'TR091_exp06_dTT'
% 'TR091_exp07_dTT'
% 'TR093_exp05_dTT'
% 'TR093_exp06_dTT'
% 'TR093_exp07_dTT'
% 'TR106_exp05_dTT'
% 'TR106_exp06_dTT'
% 'TR107_exp05_dTT'
% 'TR107_exp06_dTT'
};
%% cnmfe parameters
CNMFE_options = struct(...
'Fs', 15,... % frame rate
'tsub', 1,... % temporal downsampling factor
'gSig', 3,... % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
'gSiz', 12,... % pixel, neuron diameter
'nk', 3,...
...% background model
'bg_model', 'ring',... % model of the background {'ring', 'svd'(default), 'nmf'}
'nb', 1,...             % number of background sources for each patch (only be used in SVD and NMF model)
'ring_radius', 16,...  % when the ring model used, it is the radius of the ring used in the background model.
...% merge
'merge_thr', 0.65,...
'merge_thr_spatial', [0.5,0.1,-Inf],...% thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
'dmin', 3,... % minimum distances between two neurons. it is used together with merge_thr
...% initialize
'min_corr', 0.75,... % minimum local correlation for a seeding pixel, default 0.8, cmk 0.75
'min_pnr', 21,... % minimum peak-to-noise ratio for a seeding pixel, cmk 21, gaba 12
...% residual
'min_corr_res', 0.7,... % cmk 0.7 gaba 0.7
'min_pnr_res', 19); % cmk 19 gaba 10

%% PART 1: Concatenate behav videos, Vid2seq, Motion Correction, Chop end of wireless frames (if needed)

for e = 1:length(expInfo)
    disp(expInfo{e})
    SubFolderList = dir([videoPath expInfo{e}]);
    for n = 3
        disp(SubFolderList(n).name)
        
        %concatExperimentVideosTR2(videoPath, expInfo{e}, SubFolderList(n).name); %concat behav videos only
        %vid2seqTR(videoPath, expInfo{e}, SubFolderList(n).name); %convert behav video to seq
        
        fullPath = [videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\'];
        cd(fullPath)
        pwd
        ms = XZ_NormCorre_Batch(downsample_ratio,isnonrigid); %motion correction
        clearvars -except CNMFE_options downsample_ratio expInfo e n isnonrigid ms SubFolderList videoList videoPath
        
        wirelesscropend(videoPath, expInfo{e}, SubFolderList(n).name); %crops last 100 frames off wireless NormCorre videos
        
        FFT = 1;
        skip = 0;
        addpath  'C:\Users\honglabuser\Fiji.app\scripts'; %% dont change

        if FFT == 1
            if exist('IJM', 'var')
                if exist('IJM', 'var')
                    fprintf(1, 'ImageJ is open\n')
                else
                    ImageJ
                end
            else
                ImageJ;
            end
        end
        block = 500;

            v = VideoReader([videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\processed\msvideo_corrected.avi']);
            nFrames = v.NumberOfFrames;
            x = size(read(v,1),1);
            y = size(read(v,1),2);

            % Calculate scaling factor

            %     if exist([outFolder expInfo '_dFFinfo.mat'], 'file')
            %         load([outFolder expInfo '_dFFinfo.mat']);
            %     else
            allFrame = zeros([x y]);
            nHalf = floor(nFrames/2);
            meanPix = zeros([1 nHalf]);
            tic
            for i = 1:nHalf
                tempMat = read(v, i*2);
                meanPix(i) = mean(tempMat(:));      % mean(X, 'all') after 2018
                allFrame = allFrame + double(tempMat);
                if mod(i, round(nHalf/10)) == 0
                    fprintf(1, '.');
                end
            end
            fprintf(1, '\n')
            toc

            meanFrameRaw = allFrame / nHalf;
            meanPix = imresize(double(meanPix), [1 nFrames]);
            dFFinfo.meanPixSmooth1 = smooth(meanPix, 200);
            dFFinfo.meanPixSmooth2 = smooth(meanPix, 500);
            dFFinfo.meanPixSmooth3 = smooth(meanPix, 1000);
            dFFinfo.meanPixSmooth4 = smooth(meanPix, 2000);
            scal = dFFinfo.meanPixSmooth3/max(dFFinfo.meanPixSmooth3);
            dFFinfo.meanPixScal = meanPix ./ scal';
            dFFinfo.meanPix = meanPix;
            save([videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\processed\' expInfo{e} '_' SubFolderList(n).name '_dFFinfo.mat'], 'scal', 'dFFinfo', 'meanFrameRaw', 'x', 'y')
            % end

            % initiate videos

            C  = VideoWriter([videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\processed\' expInfo{e} '_' SubFolderList(n).name '_dFF'], 'Grayscale AVI');
            C2 = VideoWriter([videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\processed\' expInfo{e} '_' SubFolderList(n).name '_dFFs'], 'Motion JPEG AVI');
            open(C2); open(C);

            meanFrame = meanFrameRaw;
            meanFrame(meanFrame<0.03) = 0.03;

            % initiate other variables
            satuNum = zeros(1, nFrames);
            zeroNum = zeros(1, nFrames);
            histRaw = [];
            histDff = [];

            for i = 1:ceil(nFrames/block)

                % Construct dF/F0
                L = (i-1)*block+1;
                if i*block <= nFrames
                    R = i*block;
                else
                    R = nFrames;
                end
                len = R-L+1;

                fprintf(1, '\n************\ndF/F processing frames %d - %d (%3.1f%%)\n', L, R, R/nFrames*100)
                tic

                clear dFFmat2;

                tempMat = read(v, [L R]);
                dFFmat = zeros([x y R-L+1]);

                for j = L:R
                    dFF = (double(tempMat(:,:,1,j-L+1)) / scal(j) ./meanFrame) - 1; % (F-F0')/F0' = F/F0' - 1 = F/(F0*scal) - 1 = F/scal/F0 - 1;
                    satuNum(j) = nnz(dFF>1)/(x*y)*100;
                    zeroNum(j) = nnz(dFF<0)/(x*y)*100;
                    % fprintf(1, '%d | %3.3f%% - %3.3f%%\n', i, zeroNum(i), satuNum(i));
                    dFFmat(:,:,j-L+1) = dFF;
                end


                if skip == 1
                    tempMat = tempMat(:,:,:,1:10:end);
                    dFFmat = dFFmat(:,:,1:10:end);
                end

                dFFmat(dFFmat>1.2) = 1.2;
                dFFmat(dFFmat<0) = 0;

                dFFmat = dFFmat * 255;
                dFFmatRGB = uint8(colorThres(dFFmat));
                toc

                if FFT == 1
                    % Apply spatial bandpass filter
                    fprintf(1, '\nApply spatial bandpass filter through ImageJ\n')
                    tic

                    IJM.show('dFFmat');
                    ij.IJ.run("Duplicate...", "duplicate");
                    ij.IJ.selectWindow("-1");
                    ij.IJ.run("Bandpass Filter...", "filter_large=40 filter_small=3 suppress=Vertical tolerance=5 process");
                    toc
                    IJM.getDatasetAs('I');
                    ij.IJ.run("Close All");
                    if I(:,:,1) == dFFmat(:,:,1)
                        disp('ImageJ error: failed to apply bandpass filter')
                    else
                        disp('Bandpass filter applied')
                    end
                    toc

                    I2 = imgaussfilt(I, 15, 'FilterDomain', 'Spatial');
                    I3 = (I - I2);
                    FFTmat = I3 * 2.5;
                    FFTmat(FFTmat<0) = 0;
                    FFTmat(FFTmat>255) = 255;
                    FFTmatRGB = uint8(colorThres(FFTmat));
                    toc

                    % Prepare figure
                    fig11 = tempMat;
                    fig11 = repmat(fig11, [1 1 3 1]);
                    fig12 = dFFmatRGB;
                    fig13 = FFTmatRGB;
                    fig21 = squeeze(tempMat)-uint8(dFFmat);
                    fig22 = uint8(dFFmat-I3);
                    fig23 = uint8(FFTmat);
                    leng = size(tempMat, 4);
                    pad1 = ones(x, 5, 3, leng)*255;
                    pad2 = ones(x, 5, leng)*255;
                    row1 = [fig11, pad1, fig12, pad1, fig13];
                    row2 = [fig21, pad2, fig22, pad2, fig23];

                    clear row22
                    row22(:,:,1,:) = row2;
                    row22 = repmat(row22, [1 1 3 1]);
                    stitched = [row1; ones(5, y*3+10, 3, leng)*255; row22];

                    % Export movies 
                    fprintf(1, '\nWriting movie blocks\n')
                    tic
                    clear FFTmat2
                    FFTmat2(:,:,1,:) = FFTmat;
                    writeVideo(C, uint8(FFTmat2));
                    writeVideo(C2, stitched);
                    histRaw = cat(3, histRaw, tempMat(:,:,1));
                    histDff = cat(3, histDff, dFFmat(:,:,1));
                    histFFT = cat(3, histDff, FFTmat2(:,:,1));
                    figure(1)
                    clf;
                    imshow(stitched(:,:,:,1))
                    toc
                end
            end

            close(C);
            close(C2);

            % Generate report
            fig = figure(2);
            clf;
            subplot(5, 1, 1)
            hold on;
            plot(dFFinfo.meanPix)
            plot(dFFinfo.meanPixSmooth1)
            plot(dFFinfo.meanPixSmooth2)
            plot(dFFinfo.meanPixSmooth3)
            plot(dFFinfo.meanPixSmooth4)

            subplot(5, 1, 2)
            plot(dFFinfo.meanPixScal)

            subplot(5, 1, 3)
            plot(zeroNum)

            subplot(5, 1, 4)
            plot(satuNum)

            if FFT == 1
                subplot(5, 3, 13)
                hold on;
                histogram(histRaw(:))

                subplot(5, 3, 14)
                hold on;
                histDffAry = histDff(:);
                histDffAry2 = histDffAry(histDffAry<255 & histDffAry>0);
                histogram(histDffAry2)

                subplot(5, 3, 15)
                hold on;
                histFftAry = histFFT(:);
                histFftAry2 = histFftAry(histFftAry<255 & histFftAry>0);
                histogram(histFftAry2)

            end

            print(fig, '-dpng', '-r300', [videoPath expInfo{e} '\' SubFolderList(n).name '\msCam\processed\' expInfo{e} '_' SubFolderList(n).name '_dFF.png']);

        ij.IJ.run("Quit","");
        clearvars -except CNMFE_options downsample_ratio expInfo e n isnonrigid ms SubFolderList videoList videoPath
        
    end
end

%% CNMFE on FFT output
    if doCNMFE & exist('ms')
        XZ_CNMFE_batch(pwd, vName, CNMFE_options, ms);
    elseif doCNMFE
        XZ_CNMFE_batch(pwd, vName, CNMFE_options);
    end

%% Generate dFF ROI videos, top 100 cells, and wireless timestamp files
% 
% for i = 1:length(expInfo)
%     disp(expInfo{e})
%     SubFolderList = dir([videoPath expInfo{e}]);
%     for n = 3:length(SubFolderList)
%         %generateROIvideo(videoPath, expInfo{e}, SubFolderList(n).name);
%         %wirelesstimestamp(videoPath, expInfo{e}, SubFolderList(n).name);
%         %plot100cells(videoPath, expInfo{e}, SubFolderList(n).name);
%     end
% end
    
    
    
