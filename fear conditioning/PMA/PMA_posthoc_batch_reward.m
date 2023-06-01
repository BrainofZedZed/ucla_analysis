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
P2.baseline_tones = 3;  % number of baseline tones not paired with shock

P2.do_plot = true; % whether or not to plot some of the measurements. possible broken 20230526

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
    tone_bouts = tone_bouts(P2.baseline_tones+1:end);
end


%% Part 1: percent of tone spent freezing
tone_frz = cell2mat(Behavior.Intersect.TemBeh.CSp.Freezing.PerBehDuringCue);

if P2.remove_baseline_tones
    tone_frz = tone_frz(P2.baseline_tones+1:end);
end

tone_frz = tone_frz*100;

%% Part 2: percent of tone spent freezing on platform

tone_pf_frz = zeros(size(tone_frz));
for i = 1:length(tone_bouts)
    i_pf = pf_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_frz = frz_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_frz = find(i_pf & i_frz);
    tone_pf_frz(i) = length(i_pf_frz)/length(i_pf)*100;
end

%% Part X: percent of tone spent freezing off platform

tone_off_pf_frz = zeros(size(tone_frz));
for i = 1:length(tone_bouts)
    i_pf = pf_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_off = ~i_pf;
    i_frz = frz_vec(tone_bouts(i,1):tone_bouts(i,2));
    i_pf_frz = find(i_pf_off & i_frz);
    tone_off_pf_frz(i) = length(i_pf_frz)/length(i_pf_off)*100;
end



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

%% Part 4b: calculating successful avoids
shock_start_frames = cueframes.US(:,1);
avoids = zeros(size(shock_start_frames));
for i = 1:length(avoids)
    if on_pf(shock_start_frames(i))
        avoids(i) = 1;
    end
end
avoids = avoids';

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

%% Part 5: batch output
out.per_tone_frz(filenum,:) = [{id}, num2cell(tone_frz)];
out.per_tone_platform_frz(filenum,:) = [{id}, num2cell(tone_pf_frz)];
out.per_tone_off_platform_frz(filenum,:) = [{id}, num2cell(tone_off_pf_frz)];
out.per_time_platform(filenum,:) = [{id}, num2cell(per_tp_tone)];
out.plat_latency(filenum,:) = [{id}, num2cell(first_pf)];
out.avoids(filenum,:) = [{id}, num2cell(avoids)];

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
