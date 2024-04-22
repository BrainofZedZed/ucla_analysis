% PMA_posthoc_analysis
% created 6/30/21 ZZ

% ASSUMPTIONS:
% 1) BehDEPOT was used to do cued analysis, with CS+ labeled as "CSp", 
% "platform" as platform
% 2) BehDEPOT output folder is labeled '*_analyzed' and resides within
% animal folder, which contains video, .mat experiment file, and CSV DLC
% output
% 3) all files in the batch have the same number of tones (eg cannot
% combine training and testing days)

%INSTRUCTIONS: 
% Point to grandparent folder, containing individual animals organized as
% described above. Let run. Creates 'out' struct, with
% freezing rates for different events

clear; 
%% Params
fps = 49.97; % fps of behavior recording
dur_tone = 30; % (s) duration of tone
dur_shock = 2; % (S) duration of shock

P2.remove_baseline_tones = 0;  % if true, removes baseline tones from analysis
P2.baseline_tones = 0;  % number of baseline tones not paired with shock

P2.do_plot = false; % whether or not to plot some of the measurements. possible broken 20230526
P2.do_implant_in_reward = true; % makes new ROI detection, looking for ROI 'reward' using part 'Implant'
P2.make_reward_roi_small = false; % true if want to reduce size of reward ROI by half vertically
P2.do_head_pf_entry_count = false; % counts head as pf entry/exit instead of midback
P2.exclude_freeze_in_reward = true; % excludes freeze counts when head is in reward ROI

%% Batch Setup
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

for filenum = 1:length(P2.video_folder_list)
% Initialize 
current_video = P2.video_folder_list(filenum);    
video_folder = strcat(P2.video_directory, '\', current_video);
cd(video_folder) %Folder with data files   

%% user params
expf = dir('*-*-*_*-*-*.mat');
load(expf.name); % load experiment file into E struct
bdf = dir('*_analyzed*'); % behdepot folder
cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
load('Behavior.mat');


%% load animal data
id = exp_ID; % load ID

tone_vec = Behavior.Temporal.CSp.Vector;
tone_bouts = Behavior.Temporal.CSp.Bouts;
frz_vec = Behavior.Freezing.Vector;
pf_vec = Behavior.Spatial.platform.inROIvector;

if P2.remove_baseline_tones
    tone_bouts = tone_bouts(P2.baseline_tones+1:end,:);
end

%% track implant in reward
if P2.do_implant_in_reward
    load('Tracking.mat');
    loc = Tracking.Smooth.Head;
    reward_roi_num = 0;
    load('Params.mat');
    for i = 1:numel(Params.roi_name)
        if isequal(Params.roi_name{1,i}, 'reward')
            reward_roi_num = i;
        end
    end
    
    reward_roi = Params.roi{1,reward_roi_num};

    if P2.make_reward_roi_small
        % Find the indices of the two largest values in the second column
        [~, idx1] = max(reward_roi(:, 2));
        % Temporarily set the largest value to -inf to find the second largest
        temp_val = reward_roi(idx1, 2);
        reward_roi(idx1, 2) = -inf;
        [~, idx2] = max(reward_roi(:, 2));
        % Reset the first largest value
        reward_roi(idx1, 2) = temp_val;
        
        % Halve these values and ensure they are whole numbers by rounding
        reward_roi(idx1, 2) = round(reward_roi(idx1, 2) / 2);
        reward_roi(idx2, 2) = round(reward_roi(idx2, 2) / 2);
        Params.roi_name{1,3} = 'roi_small';
        Params.roi{1,3} = reward_roi;
    end

    in_reward_roi = inpolygon(loc(1,:), loc(2,:), reward_roi(:,1), reward_roi(:,2));  % find frames when location is within ROI boundaries
    Behavior.Spatial.reward_head = in_reward_roi;

    if P2.exclude_freeze_in_reward
        frz_vec = Behavior.Freezing.Vector;
        frz_in_reward = find(frz_vec & in_reward_roi);
        Behavior.Freezing.VectorWithReward = frz_vec;
        frz_vec(frz_in_reward) = 0;
        Behavior.Freezing.Vector = frz_vec;
    end
    save('Params.mat','Params');
    save('Behavior.mat', 'Behavior');
end


%% track head as entry/exit on pf 
if P2.do_head_pf_entry_count
    load('Tracking.mat');
    loc = Tracking.Smooth.Head;
    pf_roi_num = 0;
    load('Params.mat');
    for i = 1:numel(Params.roi_name)
        if isequal(Params.roi_name{1,i}, 'platform')
            pf_roi_num = i;
        end
    end
    
    platform_roi = Params.roi{1,pf_roi_num};
    pf_head_in = inpolygon(loc(1,:), loc(2,:), platform_roi(:,1), platform_roi(:,2));  % find frames when location is within ROI boundaries
    Behavior.Spatial.platform_head_vec = pf_head_in;
    Behavior.Spatial.platform_head_bouts = findStartStop(pf_head_in);
    save('Behavior.mat', 'Behavior');
end

%% Part 1: percent of tone spent freezing
tone_frz = cell2mat(Behavior.Intersect.TemBeh.CSp.Freezing.PerBehDuringCue);

if P2.remove_baseline_tones
    tone_frz = tone_frz(P2.baseline_tones+1:end);
end

tone_frz = tone_frz*100;
tone_frz_avg = mean(tone_frz);

%% Part 2: percent of tone spent freezing on platform

tone_pf_frz = zeros(size(tone_frz));
for i = 1:length(tone_bouts)
    i_pf = pf_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_frz = frz_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_frz = find(i_pf & i_frz);
    tone_pf_frz(i) = length(i_pf_frz)/length(i_pf)*100;
end

tone_pf_frz_avg = mean(tone_pf_frz);

%% Part X: percent of tone spent freezing off platform

tone_off_pf_frz = zeros(size(tone_frz));
for i = 1:length(tone_bouts)
    i_pf = pf_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_off = ~i_pf;
    i_frz = frz_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_frz = find(i_pf_off & i_frz);
    tone_off_pf_frz(i) = length(i_pf_frz)/length(i_pf_off)*100;
end

tone_off_pf_frz_avg = mean(tone_off_pf_frz);

%% Part 3:  percent time on platform, per tone
on_pf = Behavior.Spatial.platform.inROIvector;
tone_on = Behavior.Temporal.CSp.Bouts;

% length of tone
tone_dur = tone_on(1,2) - tone_on(1,1);

for i = 1:size(tone_on,1)
    t = on_pf(tone_on(i,1):tone_on(i,1)+tone_dur);
    per_tp_tone(i) = sum(t)/tone_dur;
end


if P2.remove_baseline_tones
    per_tp_tone = per_tp_tone(P2.baseline_tones+1:end);
end
per_tp_tone = per_tp_tone*100;
per_pf_tone_avg = mean(per_tp_tone);

%% Part 4:  latency to platform, per tone
%pf_tone_vec = Behavior_Filter.Intersect.ROIduringCue_Vector.CSp_platform;
tone_vec = Behavior.Temporal.CSp.Vector;

pf_tone_vec = zeros(size(tone_vec));
tmp = find(on_pf & tone_vec);
pf_tone_vec(tmp) = 1;

first_pf = zeros(1,size(tone_on,1));
for i = 1:size(tone_on,1)
    this = find(pf_tone_vec(tone_on(i,1):tone_on(i,1)+tone_dur), 1, 'first');
    if isempty(this)
        first_pf(i) = tone_dur;
    else
        first_pf(i) = this;
    end
end

first_pf = round(first_pf ./ fps);   % convert to seconds
if P2.remove_baseline_tones
    first_pf = first_pf(P2.baseline_tones+1:end);
end

first_pf_avg = mean(first_pf);

%% Part 4b: calculating successful avoids
skip_shock = true;
if ~skip_shock
    shock_start_frames = cueframes.US(:,1);
    avoids = zeros(size(shock_start_frames));
    for i = 1:length(avoids)
        if on_pf(shock_start_frames(i))
            avoids(i) = 1;
        end
    end
    avoids = avoids';
    
    avoids_avg = mean(avoids);
    
    figure;
    datamat = avoids;
    x = 1:size(datamat,2);
    hold on
    plot(x,datamat, '-o');
    xlabel('tone');
    ylim([-0.5 1.5]);
    xlim([0 size(avoids,2)+1])
    yticks([0 1]);
    yticklabels({'shock', 'avoid'});
    title([id ' shock avoids']);
    savename = [id 'avoids.fig'];
    savefig(savename);
    close;
else
    shock_start_frames = cueframes.CSp(:,1);
    avoids = zeros(size(shock_start_frames));
end

%% Part ?: calculating ITI time on platform
on_pf = Behavior.Spatial.platform.inROIvector;
tone_on_vec = Behavior.Temporal.CSp.Vector;

% find when tone is off and in platform
iti_pf = find(on_pf == 1 & tone_on_vec == 0);

% calculate proportion ITI time spent on platform
iti_dur = length(tone_on_vec) - sum(tone_on_vec);
iti_pf_proportion = sum(iti_pf) / iti_dur;

%% Calculate time in reward zone
if P2.do_implant_in_reward
    reward_time = sum(Behavior.Spatial.reward_head)/length(Behavior.Spatial.reward_head);
else
    reward_time = NaN;
end

%% calculate platform entries during tone
pf_tone_vec = zeros(size(tone_vec));
pf_tone_vec(pf_vec & tone_vec) = 1;
pf_tone_bouts = findStartStop(pf_tone_vec);


%% Part 5: batch output
out.per_tone_frz(filenum,:) = [{id}, num2cell(tone_frz)];
out.per_tone_platform_frz(filenum,:) = [{id}, num2cell(tone_pf_frz)];
out.per_tone_off_platform_frz(filenum,:) = [{id}, num2cell(tone_off_pf_frz)];
out.per_time_platform(filenum,:) = [{id}, num2cell(per_tp_tone)];
out.plat_latency(filenum,:) = [{id}, num2cell(first_pf)];
%out.avoids(filenum,:) = [{id}, num2cell(avoids)];
out.per_iti_platform(filenum,:) = [{id}, num2cell(iti_pf_proportion)];
out.per_reward_zone(filenum,:) = [{id}, num2cell(reward_time)];
out.normal_pf_bouts(filenum,:) = [{id}, {Behavior.Spatial.platform.Bouts}];
out.reward_bouts(filenum,:) = [{id}, {Behavior.Spatial.reward.Bouts}];
%out.head_pf_bouts(filenum,:) = [{id}, {Behavior.Spatial.platform_head_bouts}];
out.platform_tone_bouts(filenum,:) = [{id}, {pf_tone_bouts}];
out.avg.tone_frz(filenum,:) = [{id}, num2cell(tone_frz_avg)];
out.avg.tone_pf_frz(filenum,:) = [{id}, num2cell(tone_pf_frz_avg)];
out.avg.tone_off_pf_frz_avg(filenum,:) = [{id}, num2cell(tone_off_pf_frz_avg)];
out.avg.per_pf_time_tone_avg(filenum,:) = [{id}, num2cell(per_pf_tone_avg)];
out.avg.plat_latency(filenum,:) = [{id}, num2cell(first_pf_avg)];
%out.avg.avoids(filenum,:) = [{id}, num2cell(avoids_avg)];



clearvars -except P2 out filenum fps;

end

cd(P2.video_directory);
save('PMA_posthoc_analysis.mat', 'out');

%% Part 6:  plotting

if P2.do_plot
    fnames = fieldnames(out);
    for i = 1:6
        subplot(2,3,i)
        datamat = cell2mat(out.(fnames{i})(:,2:end));
        legmat = out.(fnames{i})(:,1);
        x = 1:size(datamat,2);
        hold on
        for j = 1:size(datamat,1)
            plot(x,datamat(j,:));
        end
        legend(legmat);
        xlabel('tone');
        ylabel(fnames{i});
        hold off
    end
        savename = 'PMA_plots.fig';
        savefig(savename);
        close;
end


%%
% helper fxns 
%%
% Go through spatial and temporal filters to find when both spatial and
% temporal filters are true. Iterate across all behaviors
function out = filterIntersect(Behavior, Params)
            
    
    % gather behaviors 
    beh_name = "Freezing";
    event_names = fieldnames(Behavior.Temporal);
    roi_names = fieldnames(Behavior.Spatial);
    beh_cell = struct2cell(Behavior);
    beh_cell = beh_cell{3:end};

    % get num events
    num_events = length(event_names);
   
    for j = 1:length(Params.roi) % loop through ROIs
        
        roi_vec = Behavior.Spatial.(roi_names{j}).inROIvector;        
        %roi_beh_vec = Behavior.Spatial.(roi_names{j}).(i_beh_name).inROIvector;
        beh_vec = Behavior.(beh_name).Vector;
        intersect_roi_beh = find(roi_vec == 1 & beh_vec == 1);
        roi_beh_vec = zeros(size(roi_vec));
        roi_beh_vec(intersect_roi_beh) = 1;
        
        for k = 1:num_events  % loop through events
            event_vec = Behavior.Temporal.(event_names{k}).Vector;
            intersect_event_beh = find(event_vec == 1 & beh_vec == 1);
            event_beh_vec = zeros(size(beh_vec));
            event_beh_vec(intersect_event_beh) = 1;

            out_name = [beh_name, roi_names{j}, event_names{k}, "Vector"];
            out_name = strjoin(out_name, '_');
            intersect_true = find(event_beh_vec == 1 & roi_beh_vec == 1);
            out_vec = zeros(size(roi_beh_vec));
            out_vec(intersect_true) = 1;
            out.SpaTemBeh.(out_name) = out_vec;
     
        end
        
        
    end
end