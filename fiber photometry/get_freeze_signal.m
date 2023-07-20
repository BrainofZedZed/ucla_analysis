% GOAL: script to load in Behavior data, Fibpho analysis file, and
% experiemtn file, to extract photometry signal during different parts of
% freezing

clear;
%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
P1.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P1.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
cd(string(P1.video_directory));
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
    current_structure = directory_contents(i);
    if current_structure.isdir
        ii = ii + 1;
        P1.video_folder_list(ii) = string(current_structure.name);
        disp([num2str(i) ' directory loaded'])
    end
end

% initialize output variable
zf1_onset_out = [];
zf2_onset_out = [];
zf3_onset_out = [];
zf1_onset_labels = {};
zf2_onset_labels = {};
zf3_onset_labels = {};

zf1_offset_out = [];
zf2_offset_out = [];
zf3_offset_out = [];
zf1_offset_labels = {};
zf2_offset_labels = {};
zf3_offset_labels = {};

% go through directories
for filenum = 1:length(P1.video_folder_list)
    % Initialize 
    current_video = P1.video_folder_list(filenum);    
    video_folder = strcat(P1.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    
    % load files params
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    cd(video_folder);
    fibphof = dir('*fibpho_analysis.mat');
    load(fibphof.name, 'bhsig', 'P2');

    % LOAD bhsig, P2 from fibpho file
    
    % LOAD Behavior from BD output
    
    %% DO FREEZE START
    % zscore data, centered around start of freezing
    % get signal for all trials from 5s before tone start to 30s after it ends
    
    bl_t = 1; % time (s) before freeze start to baseline
    pre_t = 1; % time (s) after bl before short to visualize 
    
    % want to get signal from time bl + pre_t prior to freeze start through
    % three seconds after freeze start
    % will then seperate 1s bouts from 2s and visualize all >1s bouts stopped
    % at 1s, and all >2s stopped at 2s
    
    pre_frames = (bl_t+pre_t)*P2.beh_fps;
    post_frames = 5*P2.beh_fps; % collect 5s of data after freeze start
    dur = pre_frames+post_frames;
    
    % test if first or last bout will exceed recording, if so, remove
    if Behavior.Freezing.Bouts(1,1) - pre_frames < 0
        Behavior.Freezing.Bouts(1,:) = [];
        Behavior.Freezing.Length(1) = [];
    end

    if Behavior.Freezing.Bouts(end,2) + post_frames > length(bhsig)
        Behavior.Freezing.Bouts(end,:) = [];
        Behavior.Freezing.Length(end) = [];
    end 

    % initialize freeze data
    zfreeze_onset = zeros(size(Behavior.Freezing.Bouts,1),pre_frames+post_frames);


    % zscore
    for i = 1:size(zfreeze_onset,1)
        bl = [Behavior.Freezing.Bouts(i,1) - pre_frames, Behavior.Freezing.Bouts(i,1) - pre_frames + (pre_t*P2.beh_fps)];
        t0 = bl(1);
        t1 = t0+dur;
        zb = mean(bhsig(bl(1):bl(2))); % baseline period mean
        zsd = std(bhsig(bl(1):bl(2))); % baseline period stdev
        zfreeze_onset(i,:)=(bhsig(t0:t1-1) - zb)/zsd; % Z score per bin
        zfreeze_onset(i,:) = smooth(zfreeze_onset(i,:),25); % smooth
    end
    
    for i = 1:size(zfreeze_onset,1)
        zfreeze_onset(i,:) = zfreeze_onset(i,:) - mean(zfreeze_onset(i,1:bl_t*P2.beh_fps));
    end
        
    % visualize 1s of data
    linePlot(zfreeze_onset(:,1:pre_frames+50),pre_frames,{'freeze onset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    num_bouts = size(zfreeze_onset,1);
    title([id ' GRABDA freezing signal, 1s freeze min, n=' num2str(num_bouts)]);
    savefig([P2.exp_ID '_1s_freeze_onset.fig']);
    close; 

    zf1_onset_out = [zf1_onset_out; zfreeze_onset];
    lbl = {};
    lbl = cell(size(zfreeze_onset,1),1);
    lbl(:) = {P2.exp_ID};
    zf1_onset_labels = [zf1_onset_labels; lbl];

    % visualize 2s of data
    frz_bouts_2s = find(Behavior.Freezing.Length > 100);
    zf2 = zfreeze_onset(frz_bouts_2s,:);
    linePlot(zf2(:,1:pre_frames+100),pre_frames,{'freeze onset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    title([id ' GRABDA freezing signal, 2s freeze min, n=' num2str(size(zf2,1))]);
    savefig([P2.exp_ID '_2s_freeze_onset.fig']);
    close; 

    zf2_onset_out = [zf2_onset_out; zf2];
    lbl = {};
    lbl = cell(size(zf2,1),1);
    lbl(:) = {P2.exp_ID};
    zf2_onset_labels = [zf2_onset_labels; lbl];

    % visualize 3s of data
    frz_bouts_3s = find(Behavior.Freezing.Length > 150);
    zf3 = zfreeze_onset(frz_bouts_3s,:);
    linePlot(zf3(:,1:pre_frames+100),pre_frames,{'freeze onset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    title([id ' GRABDA freezing signal, 3s freeze min, n=' num2str(size(zf3,1))]);
    savefig([P2.exp_ID '_3s_freeze_onset.fig']);
    close; 

    zf3_onset_out = [zf3_onset_out; zf3];
    lbl = {};
    lbl = cell(size(zf3,1),1);
    lbl(:) = {P2.exp_ID};
    zf3_onset_labels = [zf3_onset_labels; lbl];

    %% DO FREEZE OFFSET
    % initialize freeze data
    zfreeze_offset = zeros(size(Behavior.Freezing.Bouts,1),dur);

    % zscore
    for i = 1:size(zfreeze_offset,1)
        bl = [Behavior.Freezing.Bouts(i,2) - pre_frames, Behavior.Freezing.Bouts(i,2) - pre_frames + (pre_t*P2.beh_fps)];
        t0 = bl(1);
        t1 = t0+dur;
        zb = mean(bhsig(bl(1):bl(2))); % baseline period mean
        zsd = std(bhsig(bl(1):bl(2))); % baseline period stdev
        zfreeze_offset(i,:)=(bhsig(t0:t1-1) - zb)/zsd; % Z score per bin
        zfreeze_offset(i,:) = smooth(zfreeze_offset(i,:),25); % smooth
    end
    
    for i = 1:size(zfreeze_offset,1)
        zfreeze_offset(i,:) = zfreeze_offset(i,:) - mean(zfreeze_offset(i,1:bl_t*P2.beh_fps));
    end    

    % visualize 1s of data
    linePlot(zfreeze_offset(:,:),pre_frames,{'freeze offset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    num_bouts = size(zfreeze_offset,1);
    title([id ' GRABDA freezing signal, 1s freeze min, n=' num2str(num_bouts)]);
    savefig([P2.exp_ID '_1s_freeze_offset.fig']);
    close; 

    zf1_offset_out = [zf1_offset_out; zfreeze_offset];
    lbl = {};
    lbl = cell(size(zfreeze_offset,1),1);
    lbl(:) = {P2.exp_ID};
    zf1_offset_labels = [zf1_offset_labels; lbl];

    % visualize 2s of data
    frz_bouts_2s = find(Behavior.Freezing.Length > 100);
    zf2 = zfreeze_offset(frz_bouts_2s,:);
    linePlot(zf2(:,:),pre_frames,{'freeze offset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    title([id ' GRABDA freezing signal, 2s freeze min, n=' num2str(size(zf2,1))]);
    savefig([P2.exp_ID '_2s_freeze_offset.fig']);
    close; 

    zf2_offset_out = [zf2_offset_out; zf2];
    lbl = {};
    lbl = cell(size(zf2,1),1);
    lbl(:) = {P2.exp_ID};
    zf2_offset_labels = [zf2_offset_labels; lbl];

    % visualize 3s of data
    frz_bouts_3s = find(Behavior.Freezing.Length > 150);
    zf3 = zfreeze_offset(frz_bouts_3s,:);
    linePlot(zf3(:,:),pre_frames,{'freeze offset'});
    xlabel('Frames @ 50 fps')
    ylabel('signal (z score)')
    id = strrep(P2.exp_ID,'_',' ');
    title([id ' GRABDA freezing signal, 3s freeze min, n=' num2str(size(zf3,1))]);
    savefig([P2.exp_ID '_3s_freeze_offset.fig']);
    close; 

    zf3_offset_out = [zf3_offset_out; zf3];
    lbl = {};
    lbl = cell(size(zf3,1),1);
    lbl(:) = {P2.exp_ID};
    zf3_offset_labels = [zf3_offset_labels; lbl];

    %% save data in fibpho file
    frz.frz_frames = Behavior.Freezing.Bouts;
    frz.frz_dur = Behavior.Freezing.Length;
    frz.zfreeze_onset = zfreeze_onset;
    frz.zfreeze_offset = zfreeze_offset;
    frz.baseline_time = bl_t;
    frz.pre_time = pre_t;
    frz.pre_frames = pre_frames;
    frz.post_frames = post_frames;

    save(fibphof.name, 'frz', '-append');
end

cd(string(P1.video_directory));
save('batch_freeze_signal.mat','zf1_onset_out', 'zf2_onset_out', 'zf3_onset_out', ...
 'zf1_onset_labels', 'zf2_onset_labels', 'zf3_onset_labels', 'zf1_offset_out', ...
 'zf2_offset_out', 'zf3_offset_out', 'zf1_offset_labels', 'zf2_offset_labels', ...
 'zf3_offset_labels');

