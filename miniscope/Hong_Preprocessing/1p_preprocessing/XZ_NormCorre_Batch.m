function ms = XZ_NormCorre_Batch(spatial_downsampling, isnonrigid)
%%

if ispc
    separator = '\'; % For pc operating systems
else
    separator = '/'; % For unix (mac, linux) operating systems
end
%% if RGB avi is produced convert the video to gray scale

% aviRGBtoGray(pwd, '', 'msCam', '');

%% Parameters
if nargin < 1
    spatial_downsampling = 2; % (Recommended range: 2 - 4. Downsampling significantly increases computational speed, but verify it does not
    isnonrigid = false;
elseif nargin < 2
    isnonrigid = false;
end
analyse_behavior = false;
copy_to_googledrive = false;

% Generate timestamp to save analysis
% script_start = tic;
% ct = clock;
% analysis_time =strcat(date,'_', num2str(ct(4)),'-',num2str(ct(5)),'-',num2str(floor(ct(6))));
analysis_time = 'processed';
%% %% 1 - Create video object and save into matfile
display('Step 1: Create video object');
ms = msGenerateVideoObj(pwd,'','avi');
ms.analysis_time = analysis_time;
ms.ds = spatial_downsampling;
mkdir(strcat(pwd,separator,analysis_time));
save([ms.dirName separator 'ms.mat'],'ms','-v7.3');
%% 2 - Perform motion correction using NormCorre
display('Step 2: Motion correction');
if exist('crop.csv')
    crop_coord = csvread('crop.csv',1,0);
    crop_coord = crop_coord(end-3:end);
else
    crop_coord = [];
end
ms = msNormCorre(ms,isnonrigid,crop_coord);
%save('ms_after_registration.mat','ms','-v7.3');
end

