%% test
function XZ_CNMFE_batch(dirName, vName, CNMFE_opt, ms)
%% Run Initialize first to add pathes to necessary toolboxes



%%
% Processing based on msRun2018;
%%

if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end


if nargin < 4
    ms = struct();
end
%% Parameters
spatial_downsampling = 1; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
isnonrigid = false; % If true, performs non-rigid registration (slower). If false, rigid alignment (faster).
analyse_behavior = false;
copy_to_googledrive = false;
if copy_to_googledrive;
    copydirpath = uigetdir([],'Please select the root folder in which files will be copied');
end

% Generate timestamp to save analysis
% script_start = tic;
ct = clock;
% analysis_time =strcat(date,'_', num2str(ct(4)),'-',num2str(ct(5)),'-',num2str(floor(ct(6))));
analysis_time = 'temp';
%% %% 1 - Create video object and save into matfile
display('******* CNMFE *******');
% ms = msGenerateVideoObj(pwd,'msCam','avi');
ms.dirName = dirName;
ms.vName = vName;
ms.analysis_time = analysis_time;
ms.ds = spatial_downsampling;
mkdir(strcat(pwd,separator,analysis_time));
save([ms.dirName separator 'ms.mat'],'ms','-v7.3');
%% 2 - Perform motion correction using NormCorre
% display('Step 2: Motion correction');
% 
% ms = msNormCorre(ms,isnonrigid);
% save('ms_after_registration.mat','ms');

%% 3.a - Crop
% show correlation image 
% happy = false;
% vid_temp = VideoReader([ms.dirName separator ms.analysis_time separator 'msvideo_full.avi']);
% vmat_temp = read(vid_temp);
% T_temp = vid_temp.NumFrames;
% delete(vid_temp);
% 
% vmat_temp1 = vmat_temp(:,:,:,round(linspace(1, T_temp, min(T_temp, 1000))));
% vmat_temp1 = squeeze(vmat_temp1);
% opt_temp.d1 = size(vmat_temp1,1);
% opt_temp.d2 = size(vmat_temp1,2);
% opt_temp.gSiz = 7; % edit to match msRunCNMFE_large.m
% opt_temp.gSig = 3;
% opt_temp.center_psf = true;
% [Cn1, PNR1] = correlation_image_endoscope(vmat_temp1, opt_temp);
% 
% while ~happy
%     f_temp = figure('position', [10, 500, 1776, 400]);
%     subplot(131);
%     imagesc(Cn1, [0, 1]); colorbar;
%     axis equal off tight;
%     title('correlation image');
% 
%     % show peak-to-noise ratio 
%     subplot(132);
%     imagesc(PNR1,[0,max(PNR1(:))*0.98]); colorbar;
%     axis equal off tight;
%     title('peak-to-noise ratio');
% 
%     % show pointwise product of correlation image and peak-to-noise ratio 
%     subplot(133);
%     imagesc(Cn1.*PNR1, [0,max(PNR1(:))*0.98]); colorbar;
%     axis equal off tight;
%     title('Cn*PNR');
% 
%     roi = drawrectangle(gca);
%     roi_pos = round(roi.Position);
% 
%     close(f_temp);
%     vmat_temp2 = vmat_temp1(roi_pos(2):min(roi_pos(2)+roi_pos(4)-1, size(vmat_temp1,1)), roi_pos(1):min(size(vmat_temp1,2), roi_pos(1)+roi_pos(3)-1),:);
%     opt_temp.d1 = size(vmat_temp2,1);
%     opt_temp.d2 = size(vmat_temp2,2);
%     [Cn, PNR] = correlation_image_endoscope(vmat_temp2, opt_temp);
% 
% 
%     f_temp = figure('position', [10, 500, 1776, 400]);
%     subplot(131);
%     imagesc(Cn, [0, 1]); colorbar;
%     axis equal off tight;
%     title('correlation image');
% 
%     % show peak-to-noise ratio 
%     subplot(132);
%     imagesc(PNR,[0,max(PNR(:))*0.98]); colorbar;
%     axis equal off tight;
%     title('peak-to-noise ratio');
% 
%     % show pointwise product of correlation image and peak-to-noise ratio 
%     subplot(133);
%     imagesc(Cn.*PNR, [0,max(PNR(:))*0.98]); colorbar;
%     axis equal off tight;
%     title('Cn*PNR');
%     ha = input('Happy with the crop? y/n\n', 's');
%     switch ha
%         case 'y'
%             happy = true;
%         case 'n'
%             happy = false;
%     end
%     
%     close(f_temp);
% end

%% 3.b Finish cropping, save cropped video as 'msvideo.avi'
% save([ms.dirName separator ms.analysis_time separator 'msbckup.mat'],'ms');
% ms.roi_pos_ds = roi_pos;
% ms.roi_pos_full = [(roi_pos(1:2) - 1) * ms.ds+1, roi_pos(3:4) * ms.ds];
% ms.old_width = ms.width;
% ms.old_heght = ms.height;
% ms.width = ms.roi_pos_full(3);
% ms.height = ms.roi_pos_full(4);
% ms.meanFrame = ms.meanFrame(roi_pos(2):min(roi_pos(2)+roi_pos(4)-1, size(ms.meanFrame,1)), roi_pos(1):min(size(ms.meanFrame,2), roi_pos(1)+roi_pos(3)-1));
% 
% 
% vmat_temp = squeeze(vmat_temp);
% vmat_temp = vmat_temp(roi_pos(2):min(roi_pos(2)+roi_pos(4)-1, size(vmat_temp,1)), roi_pos(1):min(size(vmat_temp,2), roi_pos(1)+roi_pos(3)-1),:);
% 
% % movefile([ms.dirName separator ms.analysis_time separator 'msvideo.avi'], [ms.dirName separator ms.analysis_time separator 'old_msvideo.avi'], 'f');
% viw = VideoWriter([ms.dirName separator ms.analysis_time separator 'msvideo.avi'], 'Grayscale AVI');
% open(viw);
% for i = 1:size(vmat_temp,3)
%     writeVideo(viw, vmat_temp(:,:,i));
% end
% close(viw);
% delete(viw);
% 
% save([ms.dirName separator ms.analysis_time separator 'msvideo_cropped.mat'], 'vmat_temp');
% save([ms.dirName separator ms.analysis_time separator 'ms_after_crop.mat'],'ms');
% 
% clear vmat_temp1 vmat_temp2 roi T_temp opt_temp vid_temp f_temp Cn1 Cn PNR1 PNR ha happy
% clear vmat_temp viw roi_pos;

%% 4 - Perform CNMFE

if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end

display('Step 3: CNMFE');
ms.CNMFE_opt = CNMFE_opt;
ms = msRunCNMFE_large_batch(ms);
msExtractSFPs(ms); % Extract spatial footprints for subsequent re-alignement

% analysis_duration = toc(script_start);
% ms.analysis_duration = analysis_duration;

save([ms.dirName separator 'ms.mat'],'ms','-v7.3');
% disp(['Data analyzed in ' num2str(analysis_duration) 's']);

% if copy_to_googledrive;
%     destination_path = char(strcat(copydirpath, separator, ms.Experiment));
%     mkdir(destination_path);
%     copyfile('ms.mat', [destination_path separator 'ms.mat']);
%     copyfile('SFP.mat', [destination_path separator 'SFP.mat']);
%     disp('Successfully copied ms and SFP files to GoogleDrive');
%     try % This is to attempt to copy an existing behav file if you already analyzed it in the past
%             copyfile([ms.dirName separator 'behav.mat'], [destination_path separator 'behav.mat']);
%         catch
%             disp('Behavior not analyzed yet. No files will be copied.');
%     end
% end
% get ms output, containing:
% SFPs, A, neuron contours, 
% RawTraces, FiltTraces, C, raw signals of each neuron, stored in 
%% OPTIONAL put ms into cnn classifier, adjust thereshold to do preliminary cleaning
[label, scores] = cnn_classifier(ms, '', 0.03);
ms.cell_label = label;
if isfield(ms,'vidObj');
    ms = rmfield(ms, 'vidObj');
end
save([ms.dirName separator 'ms.mat'],'ms','-v7.3');
end
