%% Fiber Photometry posthoc analysis
% to be used in conjunction with BehDEPOT output and FCXD.
% Intended to be used to examine fiber photometry response to event bouts
% of the same length. NB -- events must be same (approximate) length (eg
% tones). Events of different durations (freezing, platform time) will be
% inaccurate. 
% Run script and point to grandparent folder, which holds indiviudal
% subject folders. Within each subject folder should be the experiment
% file, the BehDEPOT analysis output, and the TDT recording folder. 
%% To use:
% Choosing which analyses / plots to perform.
% single animals data (including signal (sig),
% signal-aligned-to-behavior-frames (bhsig), behavior bouts (bouts), and
% behavior vector (beh_vec) will be saved.
% Batch output of AUC / peak values will also be saved.
%%
clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% USER DEFINED PARAMS FOR SIGNAL ANALYSIS
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P2.fp_ds_factor = 10; % factor by which to downsample FP recording (eg 10 indicates 1:10:end)
P2.trange_peri_bout = [2 10]; % [sec_before, sec_after] event to visualize
P2.baseline_per = [-1 -2]; % baseline period relative to plotted data [sec_start, sec_end] (including trange_peri_bout) 
P2.remove_last_trials = 0; % true if remove last trial from analysis (helpful for looking at dynamics long after cues end)
P2.t0_as_zero = false; % true to set signal values at t0 (tone onset) as 0
P2.reward_t = 5; % (seconds) time after reward initiation to visualize signal
P2.peakWnd = [0 15]; % (seconds, seconds) 1x2 vector denoting window within epoc to look for peak, relative to epoc onset. empty defaults to entire tone

P2.pc_name = 'PC0_';
bouts_name = 'CSp'; % char name of bouts (for labeling and saving)(must be exactly as in BehDEPOT)

P2.skip_prev_analysis = false; % true if skip over previous analysis
P2.save_analysis = true;
P2.cleanbeh2fp = true; % true if hardcode fix poor behavior and photometry alignment

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% USER DEFINED PLOTTING & ANALYSIS
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P2.do_lineplot = true;
P2.do_heatmap = true;
P2.do_peak = true;
P2.do_auc = true;

% PMA specific analyses
P2.do_platform = false;
P2.do_platform_tone_intersect = false;
P2.do_platform_reward_tone_intersect = false;
P2.remove_nonshock_tones = 0; % applies only to vector plot for PMA, removes first three tones from visualization 

P2.save_analysis = true; % true if save details of analysis
P2.skip_prev_analysis = false; % true if not redo previous analysis

%% REGISTER TDT TTL AND BEHDEPOT CUE NAME
% identify PC trigger names with BehDEPOT events as 1x2 cell. first is name
% of TDT input (eg PC0_, PC2_, PC3_, etc) and second is name of BehDEPOT
% event (eg 'tone', 'CSp')
% NB: these must be the exact names and spelling of
P2.cue = {P2.pc_name, bouts_name};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Batch Setup
%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Collect 'video_folder_list' from 'P.video_directory'
P2.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P2.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
cd(string(P2.video_directory));
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
    current_structure = directory_contents(i);
    if current_structure.isdir
        ii = ii + 1;
        P2.video_folder_list(ii) = string(current_structure.name);
        disp([num2str(i) ' directory loaded'])
    end
end

%% initialize vars
ct = 0;
auc_fc_abs = {};
auc_names_fc = {'ID','0-10s auc', '10-20s auc', '20-30s auc', '0-30s auc', '7-12s auc (shock)'};
peaks = {};
peak_names = {'ID','peak value', 'latency'};

%% loop through folders
for j = 1:length(P2.video_folder_list)
    % clear from previous round
    clearvars -except 'P2' 'ct' 'auc_fc' 'auc_names_fc' 'peaks_shock_all' 'peaks_nonshock_all' 'peak_names' 'j' 'auc_shock_all' 'auc_nonshock_all' 'auc_shock_names' ' peaks_baseline_all' 'auc_baseline_all' 'peaks' 'auc_fc_ind' 'auc_fc_ind_abs' 'auc_fc_abs' 'bouts_name';
    % Initialize 
    ct = ct+1; % increase count
    current_video = P2.video_folder_list(j);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   

    basedir = pwd;
    P2.basedir = basedir;

    if P2.skip_prev_analysis
        if ~isempty(dir('*fibpho_analysis*'))
            continue
        end
    end

    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    load('Params.mat');
    cd(basedir);
    exp_file = dir('*-*-*_*-*-*.mat');
    load(exp_file.name); % load experiment file


    bouts = Behavior.Temporal.(bouts_name).Bouts;

    if P2.remove_last_trials
        bouts = bouts(1:end-1,:);
    end

    %% load stuff from current folder
    basedir = pwd;
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    load('Params.mat');
    cd(basedir);
    exp_file = dir('*-*-*_*-*-*.mat');
    load(exp_file.name); % load experiment file
    P2.exp_ID = exp_ID; % load ID
    numFrames = Params.numFrames;
    fps = Params.Video.frameRate;

    %%%%%%%%%%%%%%%%%%%%%%%%
    %% DO ANALYSIS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% load, clean, transform, align FP data
    [data, s405, s465, sig] = cleanFPData(basedir,P2);

    %% create frame lookup translating FP to behavior frames
    beh2fp = beh2FPfrlu(cueframes, data, P2.cue, numFrames, P2);

    if P2.cleanbeh2fp && (~isempty(find(beh2fp<0)) || ~isempty(find(beh2fp>length(sig)))) 
        beh2fp(beh2fp<1) = 1;
        beh2fp(beh2fp>length(sig)) = length(sig);
        disp(['error in alignment of behavior and photometry frames. hardcode fixed_' P2.exp_ID]);
        error_var = "HARDCODE ALIGNMENT OF BEHAVIOR AND PHOTOMETRY FRAMES. ERROR MAY HAVE OCCURRED";
        save('hardcode_error_flag.mat',"error_var");
    end

    bhsig = sig(beh2fp);
    %% calcuate signal over epocs (tones)
    [P2, zall] = calcSignalEpoc(Params, P2, bouts, data, bhsig);
    
    %% plot heatmap of tones
    go_heatmap(zall, bouts_name, [P2.pre_dur, P2.tone_dur+P2.pre_dur], P2);

    %% do lineplot of tones
    go_lineplot(zall, bouts_name, [P2.pre_dur, P2.tone_dur+P2.pre_dur], P2)

    %% calculate peaks of epoc signal
    if P2.do_peak
        [peaks, peaks_ind_trials] = calcPeaks(P2, zall, P2.peakWnd, ct);
    end
    %% calculate AUC of epoc signals
    if P2.do_auc
        [auc_fc_abs, auc_fc_ind_abs, auc_fc_ind] = calcAUC(P2, zall, ct);
    else
        auc_fc_abs = [];
        auc_fc_ind_abs = [];
        auc_fc_ind = [];
    end
    %% do platform heatmap and signal
    if P2.do_platform
        [zall_pf_entry, zall_pf_exit] = go_platform_analysis(bhsig, Behavior, P2);
    else
        zall_pf_entry = [];
        zall_pf_exit = [];
    end

    %% split platform between tone and nontone periods
    if P2.do_platform_tone_intersect
        [zall_pf_nontone, zall_pf_during_tone] = go_platform_tone_intersect(bhsig, Behavior, 5, on_platform_shock, P2);
    else
        zall_pf_nontone = [];
        zall_pf_during_tone = [];
    end

    %% split tone onsets between platform, reward zone, and neither
    if P2.do_platform_reward_tone_intersect
        [zall_pf_nontone, zall_pf_during_tone] = go_reward_tone_intersect(bhsig, Behavior, 5, on_platform_shock, P2);
    else
        zall_pf_nontone = [];
        zall_pf_during_tone = [];
    end


    
    %% SAVE INDIVIDUAL ANIMAL DATA (to be factorized)
     %% Save individual animal data
        bhsig = sig(beh2fp);
        if ~exist('peaks','var')
            peaks = {};
        end
        if ~exist('peak_names','var')
            peak_names = [];
        end
        if ~exist('peaks_shock','var')
            peaks_shock = [];
        end
        if ~exist('peaks_nonshock','var')
            peaks_nonshock = [];
        end
        if ~exist('auc_shock','var')
            auc_shock = [];
        end
        if ~exist('auc_shock_names','var')
            auc_shock_names = [];
        end
        if ~exist('auc_nonshock','var')
            auc_nonshock = [];
        end
        if ~exist('auc_baseline','var')
            auc_baseline=[];
        end
        if ~exist('shock_trials', 'var')
            shock_trials = [];
        end
        if ~exist('nonshock_trials', 'var')
            nonshock_trials = [];
        end
        if ~exist('on_platform_shock','var')
            on_platform_shock = [];
        end
        if ~exist('zall_pf','var')
            zall_pf = [];
        end
        if ~exist('zall_pf_avoid', 'var')
            zall_pf_avoid = [];
        end
        if ~exist('zall_pf_nontone','var')
            zall_pf_nontone = [];
        end
        if~exist('zall_pf_tone','var')
            zall_pf_tone=[];
        end
        if ~exist('peaks_baseline','var')
            peaks_baseline=[];
        end
        if ~exist('pre_dur', 'var')
            pre_dur = [];
        end
        if ~exist('epoc_length', 'var')
            epoc_length = [];
        end
        if ~exist('zall_pf_entry', 'var')
            zall_pf_entry = [];
        end
        if ~exist('zall_pf_exit', 'var')
            zall_pf_exit = [];
        end
        if ~exist('zall_pf_nontone', 'var')
            zall_pf_nontone = [];
        end
        if ~exist('zall_pf_during_tone','var')
            zall_pf_during_tone = [];
        end
        if ~exist('peaks_ind_trials','var')
            peaks_ind_trials = [];
        end

        P2.event_on = pre_dur;
        P2.event_off = epoc_length;
        savename = [basedir '\' P2.exp_ID '_' bouts_name '_fibpho_analysis.mat'];
        if P2.save_analysis
          save(savename, 'data', 'bouts', 'bouts_name', 'zall', 'peaks', 'peak_names', 'auc_fc_abs', 'auc_names_fc', 'sig', 'bhsig', 'P2', 'auc_shock', 'auc_shock_names', 'auc_nonshock', 'peaks_shock', 'peaks_nonshock', 'shock_trials', 'nonshock_trials', 'on_platform_shock', 'beh2fp', 'peaks_baseline', 'auc_baseline', 'zall_pf', 'zall_pf_avoid','zall_pf_nontone','zall_pf_tone', 'zall_pf_entry', 'zall_pf_exit', 'peaks_ind_trials');
        end
end

 %save compiled data
    cd(string(P2.video_directory));
    
    % make params struct for records

    Params.bouts_name = bouts_name; % char name of bouts (for labeling and saving)
    

    if ~exist('peaks_shock_all','var')
        peaks_shock_all = [];
    end
    if ~exist('peaks_nonshock_all','var')
        peaks_nonshock_all = [];
    end
    if ~exist('peak_names','var')
        peak_names = [];
    end
    if ~exist('auc_shock_all','var')
        auc_shock_all = [];
    end
    if ~exist('auc_shock_names', 'var')
        auc_shock_names = [];
    end
    if ~exist('auc_nonshock_all', 'var')
        auc_nonshock_all = [];
    end
    if ~exist('auc_baseline_all', 'var')
        auc_baseline_all = [];
    end
    if~exist('peaks_baseline_all','var')
        peaks_baseline_all = [];
    end
    if ~exist('auc_fc_abs','var')
        auc_fc_abs = [];
    end
    if ~exist('auc_fc_ind_abs','var')
        auc_fc_ind_abs = [];
    end
    if ~exist('auc_fc_ind','var')
        auc_fc_ind = [];
    end
    
    if P2.save_analysis
        save(['fibpho_analysis_' bouts_name '.mat'], 'auc_fc_ind', 'auc_fc_ind_abs', 'auc_fc_abs', 'auc_names_fc', 'peaks', 'peaks_shock_all', 'peaks_nonshock_all', 'peak_names', 'Params', 'auc_shock_all', 'auc_shock_names', 'auc_nonshock_all', 'auc_baseline_all', 'peaks_baseline_all');
    end

        


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% INTERNAL FUNCTIONS
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data, s405, s465, sig] = cleanFPData(basedir,P2)
     %% load TDT data
    % get list of folders
    files = dir(basedir);
    dirFlags = [files.isdir];
    folders = files(dirFlags);
    subfolderNames = {folders.name};

    % look for two 6-digit patterns to identify TDT folder
    pat = digitsPattern(6);
    for i = 1:length(subfolderNames)
        m = extract(subfolderNames{i}, pat);
        if length(m) == 2
            tdt_f = i;
        end
    end
    tdt_dir = [folders(tdt_f).folder '\' folders(tdt_f).name];
    data = TDTbin2mat(tdt_dir, 'TYPE', {'epocs', 'scalars', 'streams'});

    % load 465 from 405 signal and downsample
    s465 = data.streams.x465A.data;
    s405 = data.streams.x405A.data;
    
    % downsample
    s465 = s465(1:P2.fp_ds_factor:end);
    s405 = s405(1:P2.fp_ds_factor:end);
    
    % Fitting 405 channel onto 465 channel to detrend signal bleaching
    % Algorithm sourced from Tom Davidson's Github:
    % https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m
    bls_all = polyfit(s405(1:end), s465(1:end), 1);
    Y_fit_all = bls_all(1) .* s405 + bls_all(2);
    sig = s465 - Y_fit_all;
    %sig = s465; % TEST LINE ADDED BY ZACH TO PLAY WITH JUST 465 SIGNAL
    
end

%%

function beh2fp = beh2FPfrlu(cueframes_in, TDTdata, cue, numFrames, P2)
% GOAL: Create a frame lookup table to translate fiber photometry frames
% to Behavior frames (using Fear Conditioning Experiment Designer and 
% BehDEPOT output). 
% INPUT:  cueframes_in, TDTdata (output from TDTbin2mat), PC0name (string; name of PC0
% signal in exp_file, eg "tone" or "csp")
% OUTPUT:  frame lookup table translating TDT fiber photometry frames to
% behavior frames. Example:  beh2fp(1) = N, where 1 is behavior frame 1
% which corresponds to FP frame N

% get cueframes from experiment file and PC0 timing from TDT
cueframes = cueframes_in.(cue{2});
fp.pc_times = [TDTdata.epocs.(cue{1}).onset, TDTdata.epocs.(cue{1}).offset]; 

%hardcode to remove erroneous cues in TDT data
dif = fp.pc_times(:,2) - fp.pc_times(:,1);
drop_row = [];
for i = 1:length(dif)
    if dif(i) < 2
        drop_row = [drop_row, i];
    end
end

fp.pc_times(drop_row,:) = [];



% hardcode to adjust bug in final event acquisition
if fp.pc_times(end,2) == Inf
    fp.pc_times = fp.pc_times(1:end-1,:);
end

fp.fps = TDTdata.streams.x465A.fs;
fp.pc0_frames = fp.pc_times * fp.fps;

% find length of behavior, insensitive to fieldnames 
beh_frames = cueframes;
fp_frames = fp.pc0_frames;

temp_BEHs = []; % initialize BEHs var
for iii=1:size(beh_frames,1)
    temp_BEHs=[temp_BEHs,round(beh_frames(iii,:))]; % calc behavior indices based on tone onset/offset
end

temp_FPs=[]; % initialize FPs variable
for iii=1:size(fp_frames,1) 
    temp_FPs=[temp_FPs,round(fp_frames(iii,:))]; % calc FP indices based on tone onset/offset
end

% make a linear model to predict all beh frame FP values
mdl = fitlm(temp_BEHs',temp_FPs',"quadratic");
ynew = 1:numFrames;
ypred = predict(mdl,ynew');
beh2fp=round(ypred); % round resultant intperolation so the indices are integers
beh2fp=beh2fp';

% downsample beh2fp
beh2fp = round(beh2fp / P2.fp_ds_factor);


end

%%

function [P2, zall] = calcSignalEpoc(Params, P2, bouts, data, bhsig)
    P2.beh_fps = Params.Video.frameRate;
    % % hardcode adjustment for 50fps lag
    % if P2.beh_fps == 50
    %     P2.beh_fps = 49.97;
    % end

        ts1 = round(bouts(:,1) - (P2.trange_peri_bout(1)*P2.beh_fps));
        ts2 = round(bouts(:,2) + (P2.trange_peri_bout(2)*P2.beh_fps));
    
        % enforce same length
        tmp_dur = ts2-ts1;
        beh_ts = [ts1, ts1+min(tmp_dur)];
        epoc_length =  beh_ts(1,2) - beh_ts(1,1);
        pre_dur = bouts(1,1) - beh_ts(1,1);
        post_dur = beh_ts(1,2) - bouts(1,2);

        P2.pre_dur = pre_dur;
        P2.post_dur = post_dur;
        P2.tone_dur = epoc_length-pre_dur-post_dur;
        % get fp frames corresponding to beh frames, enforce same length
        if P2.remove_last_trials
            beh_ts = beh_ts(1:end-1,:);
            bouts = bouts(1:end-1,:);
        end
       
        % get signal for all trials and zscore
        zall = zeros(size(bouts,1),epoc_length);
    
        % calc baseline frames
        bl = [P2.baseline_per(1)*P2.beh_fps, P2.baseline_per(2)*P2.beh_fps];

        % zscore
        % beh_ts(1,1) holds the start of the zscore baseline period, beh_ts(1,2)
        % holds the end of the zscore baseline period
        for i = 1:size(zall,1)
            zb = mean(bhsig((beh_ts(i,1)-bl(1):beh_ts(i,1)-bl(2)))); % baseline period mean
            zsd = std(bhsig((beh_ts(i,1)-bl(1):beh_ts(i,1)-bl(2)))); % baseline period stdev
            zall(i,:)=(bhsig(beh_ts(i,1):beh_ts(i,2)-1) - zb)/zsd; % Z score per bin
            zall(i,:)=smooth(zall(i,:),25);  % optional smoothing
        end
   
        % get fp fps
        P2.fp_fps = data.streams.x465A.fs;
        P2.fp_fps = round(P2.fp_fps/P2.fp_ds_factor);
    
        % set t0 to 0
        if P2.t0_as_zero
            t0 = round(P2.trange_peri_bout(1)*P2.fp_fps);
            for i = 1:size(zall,1)
                tmp_smth = smooth(zall(i,:),round(P2.fp_fps/4));
                zall(i,:) = zall(i,:)-tmp_smth(t0);
            end
        end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [peaks, peaks_ind_trials] = calcPeaks(P2, zall, peakWnd, ct)        
    t0 = round(P2.trange_peri_bout(1)*P2.beh_fps);
    if isempty(peakWnd)
        z = zall;
    else
        wndStart = t0+(peakWnd(1)*P2.beh_fps);
        wndEnd = t0+(peakWnd(2)*P2.beh_fps);
        z = zall(:,wndStart:wndEnd);
    end
    [peak, latency] = max(mean(z));
    [pk_all, lat_all] = max(z,[],2);
    latency = mean(latency);
    latency = latency/P2.beh_fps;
    peaks{ct,1} = P2.exp_ID;
    peaks{ct,2} = peak;
    peaks{ct,3} = latency;
    peaks_ind_trials = [pk_all, lat_all];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [auc_fc_abs, auc_fc_ind_abs, auc_fc_ind] = calcAUC(P2, zall, ct)
    t0 = round(P2.trange_peri_bout(1)*P2.beh_fps);
    meanz = mean(zall);
    auc_offset = mean(meanz(1:t0));
    meanz = meanz-auc_offset;
    auc_fc_abs{ct,1} = P2.exp_ID;
    auc_fc_abs{ct,2} = trapz(abs(meanz(t0:t0+(round(10*P2.beh_fps)))));

    try
        auc_fc_abs{ct,3} = trapz(abs(meanz(t0+round(10*P2.beh_fps):t0+round(20*P2.beh_fps))));
    catch
        auc_fc_abs{ct,3} = '';
    end

    try
        auc_fc_abs{ct,4} = trapz(abs(meanz(t0+round(20*P2.beh_fps):t0+round(30*P2.beh_fps))));
    catch
        auc_fc_abs{ct,4} = '';
    end

    try
        auc_fc_abs{ct,5} = trapz(abs(meanz(t0:t0+round(30*P2.beh_fps))));
    catch
        auc_fc_abs{ct,5} = '';
    end


    % AUC calculated over indiviudual trials, abs
    auc_fc_ind_abs{ct,1} = P2.exp_ID;
    auc_fc_ind_abs{ct,2} = trapz(abs(zall(:,t0:t0+(round(10*P2.beh_fps)))),2);
    auc_fc_ind_abs{ct,2} = mean(auc_fc_ind_abs{ct,2});

    try
        auc_fc_ind_abs{ct,3} = trapz(abs(zall(:,t0+round(10*P2.beh_fps):t0+round(20*P2.beh_fps))),2);
        auc_fc_ind_abs{ct,3} = mean(auc_fc_ind_abs{ct,3});

    catch
        auc_fc_ind_abs{ct,3} = '';
    end

    try
        auc_fc_ind_abs{ct,4} = trapz(abs(zall(:,t0+round(20*P2.beh_fps):t0+round(30*P2.beh_fps))),2);
        auc_fc_ind_abs{ct,4} = mean(auc_fc_ind_abs{ct,4});

    catch
        auc_fc_ind_abs{ct,4} = '';
    end

    try
        auc_fc_ind_abs{ct,5} = trapz(abs(zall(:,t0:t0+round(30*P2.beh_fps))),2);
        auc_fc_ind_abs{ct,5} = mean(auc_fc_ind_abs{ct,5});
    catch
        auc_fc_ind_abs{ct,5} = '';
    end

   % AUC calculated over indiviudual trials, not abs
    auc_fc_ind{ct,1} = P2.exp_ID;
    auc_fc_ind{ct,2} = trapz(zall(:,t0:t0+(round(10*P2.beh_fps))),2);
    auc_fc_ind{ct,2} = mean(auc_fc_ind{ct,2});

    try
        auc_fc_ind{ct,3} = trapz(zall(:,t0+round(10*P2.beh_fps):t0+round(20*P2.beh_fps)),2);
        auc_fc_ind{ct,3} = mean(auc_fc_ind{ct,3});

    catch
        auc_fc_ind{ct,3} = '';
    end

    try
        auc_fc_ind{ct,4} = trapz(zall(:,t0+round(20*P2.beh_fps):t0+round(30*P2.beh_fps)),2);
        auc_fc_ind{ct,4} = mean(auc_fc_ind{ct,4});

    catch
        auc_fc_ind{ct,4} = '';
    end

    try
        auc_fc_ind{ct,5} = trapz(zall(:,t0:t0+round(30*P2.beh_fps)),2);
        auc_fc_ind{ct,5} = mean(auc_fc_ind{ct,5});
    catch
        auc_fc_ind{ct,5} = '';
    end         
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function go_heatmap(zall, bouts_name, vertLines, P2)
    % Plot heat map over trials
    fig = figure;
    imagesc(zall)
    colormap('parula'); 
    c1 = colorbar; 
    title(sprintf('Z-Score Heat Map, %d %s%s', size(zall,1), bouts_name));
    ylabel('Trials', 'FontSize', 12);
    hold on;
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end

    % get FP fps (downsample adjusted) to label xaxis
    xlabel(sprintf('frames (@ %d frames per second)', P2.beh_fps));

    filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'HeatMap'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function go_lineplot(zall, bouts_name, vertLines, P2)

    % Subtract DC offset to get signals on top of one another and adjust
    % baseline to be zeroed
    zall_offset = zall - mean(mean(zall));
    for i = 1:size(zall,1)
        %zall_offset(i,:) = smooth(zall_offset(i,:),25);
    end
    sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));

    % plot mean and sem
    fig = figure;
    y = mean(zall_offset);
    x = 1:numel(y);
    curve1 = y + sem_zall;
    curve2 = y - sem_zall;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    h = fill(x2, inBetween, 'r');
    set(h, 'facealpha', 0.25, 'edgecolor', 'none');
    hold on;
    plot(x, y, 'r', 'LineWidth', 2);

    % Plot vertical line at epoch onset, time = 0
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end

    %labels
    n1 = sprintf('%s%s', P2.exp_ID);
    n2 = sprintf('%s%s', bouts_name);
    n3 = sprintf('%d', size(zall,1));
    ttl = [n1 ' average ' n2 ' response with SEM, ' n3 ' Trials'];
    title (ttl);
    xlabel(sprintf('frames (@ %d frames per second)', round(P2.beh_fps)));
    ylabel('zscore')
    axis tight

    %save
    filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'LinePlot'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;

    % do same, with each trial plotted individually
    fig = figure;
    plot(zall_offset');
    % Plot vertical line at epoch onset, time = 0
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end
    %labels
    num_t = size(zall,1);
    leg = {};
    for i = 1:num_t
        i_t = ['trial ' num2str(i)];
        leg = [leg {i_t}];
    end
    leg = [leg {'tone on'} {'tone off'}];
    legend(leg)
    n1 = sprintf('%s%s', P2.exp_ID);
    n2 = sprintf('%s%s', bouts_name);
    n3 = sprintf('%d', size(zall,1));
    ttl = [n1 ' average ' n2 ' response, ' n3 ' Trials'];
    title (ttl);
    xlabel(sprintf('frames (@ %d frames per second)', round(P2.beh_fps)));
    ylabel('zscore')
    axis tight
    %save
     filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'LinePlot_IndvLines'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 function [zall_pf_entry, zall_pf_exit] = go_platform_analysis(bhsig, Behavior, P2)
    pf_bout_dur = Behavior.Spatial.platform.Bouts(:,2) - Behavior.Spatial.platform.Bouts(:,1);     
    
    pf_time = P2.trange_peri_bout(2); % seconds after platform encounter to visualize
    pre_pf_time = P2.trange_peri_bout(1); % seconds before platform encounter to visualize
    pre_pf_baseline = abs(P2.baseline_per(1)); % seconds before pre_pf to use as baseline
    % calc baseline frames
    bl = [P2.baseline_per(1)*P2.beh_fps, P2.baseline_per(2)*P2.beh_fps];

    pf_idx = find(pf_bout_dur>(pf_time*P2.beh_fps));

    pf_entry = Behavior.Spatial.platform.Bouts(:,1);
    pf_exit = Behavior.Spatial.platform.Bouts(:,2);
    total_length = round((pf_time+pre_pf_time)*P2.beh_fps);

    % test to see if entry happens immediately following or during a shock,
    % reject platform entry if so
    us_vec = Behavior.Temporal.US.Vector;
    pf_idx_reject = [];
    for i = 2:length(pf_idx)
        if sum(us_vec(pf_entry(pf_idx(i))-(2*P2.beh_fps):pf_entry(pf_idx(i)))) > 0
            pf_idx_reject(i) = i;
        end
    end
    pf_idx_reject = pf_idx_reject(find(pf_idx_reject));
    pf_idx(pf_idx_reject) = [];

    % test to see if there's platform entries. exit if not
    if isempty(pf_idx)
        disp('no platform entries. skipping platform heatmap');
        zall_pf_entry = []; 
        zall_pf_exit = [];
    else
    
    % test if first or end point will exceed recording limit
    omega = pf_exit(pf_idx(end)) + total_length;
    if omega > length(bhsig)
        pf_idx = pf_idx(1:end-1);
    end

    alpha = pf_entry(pf_idx(1)) - (pre_pf_time+pre_pf_baseline)*P2.beh_fps;
    if alpha < 1
        pf_idx = pf_idx(2:end);
    end

    % get signal for all trials and zscore for entry
    zall_pf_entry = zeros(size(pf_idx,1),total_length);
    
    for i = 1:size(zall_pf_entry,1)
        bl_pf = bhsig(pf_entry(pf_idx(i)) - bl(1) : pf_entry(pf_idx(i)) - bl(2));
        zb = mean(bl_pf); % baseline period mean
        zsd = std(bl_pf); % baseline period stdev
        s1 = pf_entry(pf_idx(i)) - (P2.trange_peri_bout(1)*P2.beh_fps);
        s2 = pf_entry(pf_idx(i)) + (P2.trange_peri_bout(2)*P2.beh_fps);
        zall_pf_entry(i,:)=((bhsig(s1:s2-1)- zb) / zsd);
        zall_pf_entry(i,:)=smooth(zall_pf_entry(i,:),25);
        %zall_pf_entry(i,:) = zall_pf_entry(i,:) - mean(zall_pf_entry(i,1:pre_pf_baseline*P2.beh_fps));
    end
     
    % make plots
   go_heatmap(zall_pf_entry, 'Platform Entry', [pre_pf_time*P2.beh_fps], P2);
   go_lineplot(zall_pf_entry, 'Platform Entry', [pre_pf_time*P2.beh_fps], P2);

    % get signal for all trials and zscore for exit
    zall_pf_exit = zeros(size(pf_idx,1),total_length);
    
    for i = 1:size(zall_pf_exit,1)
        bl_pf = bhsig(pf_exit(pf_idx(i)) - ((pre_pf_time+pre_pf_baseline)*P2.beh_fps) : pf_exit(pf_idx(i)) - ((pre_pf_baseline)*P2.beh_fps));
        zb = mean(bl_pf); % baseline period mean
        zsd = std(bl_pf); % baseline period stdev
        s1 = pf_exit(pf_idx(i)) - (pre_pf_time*P2.beh_fps);
        s2 = pf_exit(pf_idx(i)) + (pf_time*P2.beh_fps);
        zall_pf_exit(i,:)=((bhsig(s1:s2-1)- zb) / zsd);
        zall_pf_exit(i,:)=smooth(zall_pf_exit(i,:),25);
        %zall_pf_exit(i,:) = zall_pf_exit(i,:) - mean(zall_pf_exit(i,1:pre_pf_baseline*P2.beh_fps));
    end
    
    % make heatmap
    go_heatmap(zall_pf_exit, 'Platform Exit', [pre_pf_time*P2.beh_fps], P2);
    go_lineplot(zall_pf_exit,'Platform Exit', [pre_pf_time*P2.beh_fps], P2);

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [zall_pf_nontone, zall_pf_during_tone] = go_platform_tone_intersect(bhsig, Behavior, min_pf_dur, on_platform_shock, P2)
    P2.beh_fps = 50;
    tone_bouts = Behavior.Temporal.CSp.Bouts;
    bouts_pf_og = Behavior.Spatial.platform.Bouts;
    bout_dur = bouts_pf_og(:,2)-bouts_pf_og(:,1);
    
    min_dur = min_pf_dur*P2.beh_fps;  % dur in behavior frames
    long_bouts = find(bout_dur>min_dur);
    bouts_pf = bouts_pf_og(long_bouts,:);

    if isempty(bouts_pf)
        zall_pf_nontone = [];
        zall_pf_during_tone = [];
    else    
        tone_vec = Behavior.Temporal.CSp.Vector;
        
        % ask if movement bout is during tone or not
        move_in_tone = zeros(size(bouts_pf,1),1);
    
        % get which platform entry occurs during a tone
        for i = 1:size(bouts_pf,1)
            if tone_vec(bouts_pf(i,1))
                move_in_tone(i) = 1;
            end
        end
    
        % find which in tone entries were successful avoids
        ops2 = on_platform_shock;
        tone_avoid_vec = zeros(size(tone_vec));
        for i = 1:length(ops2)
            if ops2(i)
                tone_avoid_vec(tone_bouts(i,1):tone_bouts(i,2)) = 1;
            end
        end
    
        % tone avoid vec codes tones which were successful avoids
        % now need use bouts for pf, intersect with tone avoid vec
        avoid_pf_entry = zeros(size(move_in_tone));
        for i = 1:size(bouts_pf,1)
            tmp = sum(tone_avoid_vec(bouts_pf(i,1):bouts_pf(i,2)));
            if tmp > 0
                avoid_pf_entry(i) = 1;
            else
                avoid_pf_entry(i) = 0;
            end
        end
    
        pre_pf_bl = P2.baseline_per * P2.beh_fps; % pre platform time in beh frames to baseline to
        P2.pre_pf_window = 250; % time pre platform entry to gather in beh frames
    
        % test if first or end point will exceed recording limit
        omega = bouts_pf(end,2) + min_dur-1;
        if omega > length(bhsig)
            bouts_pf = bouts_pf(1:end-1,:);
            move_in_tone = move_in_tone(1:end-1);
            avoid_pf_entry = avoid_pf_entry(1:end-1);
        end
    
        alpha = bouts_pf(1,1) - pre_pf_bl(1);
        if alpha < 1
            bouts_pf = bouts_pf(2:end,:);
            move_in_tone = move_in_tone(2:end,:);
            avoid_pf_entry = avoid_pf_entry(2:end);
    
        end
    
       % get signal for all trials and zscore
        zall_pf = zeros(size(bouts_pf,1),min_dur+P2.pre_pf_window);
    
    
        for i = 1:size(zall_pf,1)
            if bouts_pf(i,1)-P2.pre_pf_window > 0 && bouts_pf(i,1)+min_dur-1 < omega
                zb = mean(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period mean
                zsd = std(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period stdev
                zall_pf(i,:)=(bhsig((bouts_pf(i,1)-P2.pre_pf_window):bouts_pf(i,1)+min_dur-1) - zb)/zsd; % Z score per bin
            end
        end
    
        % get just entries during tonem excluding baseline
        zall_pf_tone = zall_pf(find(move_in_tone),:);
    
        %
        % get just entries NOT during tone
        zall_pf_nontone = zall_pf(find(move_in_tone==0),:);
    
        % get entries just during tones with successful avoids
        zall_pf_during_tone = zall_pf(find(avoid_pf_entry),:);
    
        go_heatmap(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_heatmap(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        go_lineplot(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_lineplot(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        %% redo with platform exits
        % get which platform entry occurs during a tone
        for i = 1:size(bouts_pf,1)
            if tone_vec(bouts_pf(i,2))
                move_in_tone(i) = 1;
            end
        end
    
        % tone avoid vec codes tones which were successful avoids
        % now need use bouts for pf, intersect with tone avoid vec
        avoid_pf_entry = zeros(size(move_in_tone));
        for i = 1:size(bouts_pf,1)
            tmp = sum(tone_avoid_vec(bouts_pf(i,1):bouts_pf(i,2)));
            if tmp > 0
                avoid_pf_entry(i) = 1;
            else
                avoid_pf_entry(i) = 0;
            end
        end
    
        pre_pf_bl = P2.baseline_per * P2.beh_fps; % pre platform time in beh frames to baseline to
        P2.pre_pf_window = 250; % time pre platform entry to gather in beh frames
    
        % test if first or end point will exceed recording limit
        omega = bouts_pf(end,2) + min_dur-1;
        if omega > length(bhsig)
            bouts_pf = bouts_pf(1:end-1,:);
            move_in_tone = move_in_tone(1:end-1);
            avoid_pf_entry = avoid_pf_entry(1:end-1);
        end
    
        alpha = bouts_pf(1,1) - pre_pf_bl(1);
        if alpha < 1
            bouts_pf = bouts_pf(2:end,:);
            move_in_tone = move_in_tone(2:end,:);
            avoid_pf_entry = avoid_pf_entry(2:end);
    
        end
    
       % get signal for all trials and zscore
        zall_pf = zeros(size(bouts_pf,1),min_dur+P2.pre_pf_window);
    
        for i = 1:size(zall_pf,1)
            if bouts_pf(i,1)-P2.pre_pf_window > 0 && bouts_pf(i,1)+min_dur-1 < omega
                zb = mean(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period mean
                zsd = std(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period stdev
                zall_pf(i,:)=(bhsig((bouts_pf(i,1)-P2.pre_pf_window):bouts_pf(i,1)+min_dur-1) - zb)/zsd; % Z score per bin
            end
        end
    
        % get just entries during tonem excluding baseline
        zall_pf_tone = zall_pf(find(move_in_tone),:);
    
        % get just entries NOT during tone
        zall_pf_nontone = zall_pf(find(move_in_tone==0),:);
    
        % get entries just during tones with successful avoids
        zall_pf_during_tone = zall_pf(find(avoid_pf_entry),:);
    
        go_heatmap(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_heatmap(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        go_lineplot(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_lineplot(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    end
end

function [zall_pf_nontone, zall_pf_during_tone] = go_reward_tone_intersect(bhsig, Behavior, min_pf_dur, on_platform_shock, P2)
    P2.beh_fps = 50;
    tone_bouts = Behavior.Temporal.CSp.Bouts;
    bouts_pf_og = Behavior.Spatial.platform.Bouts;
    bout_dur = bouts_pf_og(:,2)-bouts_pf_og(:,1);
    
    min_dur = min_pf_dur*P2.beh_fps;  % dur in behavior frames
    long_bouts = find(bout_dur>min_dur);
    bouts_pf = bouts_pf_og(long_bouts,:);
    
    if isempty(bouts_pf)
        zall_pf_nontone = []; 
        zall_pf_during_tone = [];
    else
        tone_vec = Behavior.Temporal.CSp.Vector;
        
        % ask if movement bout is during tone or not
        move_in_tone = zeros(size(bouts_pf,1),1);
    
        % get which platform entry occurs during a tone
        for i = 1:size(bouts_pf,1)
            if tone_vec(bouts_pf(i,1))
                move_in_tone(i) = 1;
            end
        end
    
        % find which in tone entries were successful avoids
        ops2 = on_platform_shock;
        tone_avoid_vec = zeros(size(tone_vec));
        for i = 1:length(ops2)
            if ops2(i)
                tone_avoid_vec(tone_bouts(i,1):tone_bouts(i,2)) = 1;
            end
        end
    
        % tone avoid vec codes tones which were successful avoids
        % now need use bouts for pf, intersect with tone avoid vec
        avoid_pf_entry = zeros(size(move_in_tone));
        for i = 1:size(bouts_pf,1)
            tmp = sum(tone_avoid_vec(bouts_pf(i,1):bouts_pf(i,2)));
            if tmp > 0
                avoid_pf_entry(i) = 1;
            else
                avoid_pf_entry(i) = 0;
            end
        end
    
        pre_pf_bl = [300 150]; % pre platform time in beh frames to baseline to
        P2.pre_pf_window = 250; % time pre platform entry to gather in beh frames
    
        % test if first or end point will exceed recording limit
        omega = bouts_pf(end,2) + min_dur-1;
        if omega > length(bhsig)
            bouts_pf = bouts_pf(1:end-1,:);
            move_in_tone = move_in_tone(1:end-1);
            avoid_pf_entry = avoid_pf_entry(1:end-1);
        end
    
        alpha = bouts_pf(1,1) - pre_pf_bl(1);
        if alpha < 1
            bouts_pf = bouts_pf(2:end,:);
            move_in_tone = move_in_tone(2:end,:);
            avoid_pf_entry = avoid_pf_entry(2:end);
    
        end
    
       % get signal for all trials and zscore
        zall_pf = zeros(size(bouts_pf,1),min_dur+P2.pre_pf_window);
    
        for i = 1:size(zall_pf,1)
            zb = mean(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period mean
            zsd = std(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period stdev
            zall_pf(i,:)=(bhsig((bouts_pf(i,1)-P2.pre_pf_window):bouts_pf(i,1)+min_dur-1) - zb)/zsd; % Z score per bin
        end
    
        % get just entries during tonem excluding baseline
        zall_pf_tone = zall_pf(find(move_in_tone),:);
    
        %
        % get just entries NOT during tone
        zall_pf_nontone = zall_pf(find(move_in_tone==0),:);
    
        % get entries just during tones with successful avoids
        zall_pf_during_tone = zall_pf(find(avoid_pf_entry),:);
    
        go_heatmap(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_heatmap(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        go_lineplot(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_lineplot(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        %% redo with platform exits
        % get which platform entry occurs during a tone
        for i = 1:size(bouts_pf,1)
            if tone_vec(bouts_pf(i,2))
                move_in_tone(i) = 1;
            end
        end
    
        % tone avoid vec codes tones which were successful avoids
        % now need use bouts for pf, intersect with tone avoid vec
        avoid_pf_entry = zeros(size(move_in_tone));
        for i = 1:size(bouts_pf,1)
            tmp = sum(tone_avoid_vec(bouts_pf(i,1):bouts_pf(i,2)));
            if tmp > 0
                avoid_pf_entry(i) = 1;
            else
                avoid_pf_entry(i) = 0;
            end
        end
    
        pre_pf_bl = [300 150]; % pre platform time in beh frames to baseline to
        P2.pre_pf_window = 250; % time pre platform entry to gather in beh frames
    
        % test if first or end point will exceed recording limit
        omega = bouts_pf(end,2) + min_dur-1;
        if omega > length(bhsig)
            bouts_pf = bouts_pf(1:end-1,:);
            move_in_tone = move_in_tone(1:end-1);
            avoid_pf_entry = avoid_pf_entry(1:end-1);
        end
    
        alpha = bouts_pf(1,1) - pre_pf_bl(1);
        if alpha < 1
            bouts_pf = bouts_pf(2:end,:);
            move_in_tone = move_in_tone(2:end,:);
            avoid_pf_entry = avoid_pf_entry(2:end);
    
        end
    
       % get signal for all trials and zscore
        zall_pf = zeros(size(bouts_pf,1),min_dur+P2.pre_pf_window);
    
        for i = 1:size(zall_pf,1)
            zb = mean(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period mean
            zsd = std(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period stdev
            zall_pf(i,:)=(bhsig((bouts_pf(i,1)-P2.pre_pf_window):bouts_pf(i,1)+min_dur-1) - zb)/zsd; % Z score per bin
        end
    
        % get just entries during tonem excluding baseline
        zall_pf_tone = zall_pf(find(move_in_tone),:);
    
        % get just entries NOT during tone
        zall_pf_nontone = zall_pf(find(move_in_tone==0),:);
    
        % get entries just during tones with successful avoids
        zall_pf_during_tone = zall_pf(find(avoid_pf_entry),:);
    
        go_heatmap(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_heatmap(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    
        go_lineplot(zall_pf_nontone, 'Platform entries outside of tone', [P2.pre_pf_window], P2);
        go_lineplot(zall_pf_during_tone, 'Platform entries during tone', [P2.pre_pf_window], P2);
    end
end
    