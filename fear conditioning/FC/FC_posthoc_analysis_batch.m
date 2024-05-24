%% FC_posthoc_analysis_batch
% batch version of script

% ASSUMPTIONS:
% 1) BehDEPOT was used to do cued analysis, with CS+ labeled as "CSp", CS-
% as "CSm", laser as "laser", shock as "shock"
% 2) BehDEPOT output folder is labeled '*_analyzed' and resides within
% animal folder, which contains video, .mat experiment file, and CSV DLC
% output

%INSTRUCTIONS: 
% Point to grandparent folder, containing individual animals organized as
% described above. Let run. Creates 'out_all' and 'out_avg' table, with
% freezing rates for different events

%% for final output

%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
clear;
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

%% initialize output vars
%out_all = array2table(zeros(1,3));
%out_all.Properties.VariableNames = ({'ID','event','freeze percent'});
%out_avg = array2table(zeros(1,6));
%out_avg.Properties.VariableNames = ({'ID','frz_csp', 'frz_csp_laser','frz_csm','frz_csm_laser','frz_nontone'});
out_all = cell(1,3); % cols: ID, event, freeze
out_avg = cell(1,10);
out_avg_vars = {'ID','frz_csp', 'frz_csp_laser','frz_csm','frz_csm_laser','frz_nontone', 'laser', 'frz_baseline'};
alli = 1;
avgi = 1;

for filenum = 1:length(P2.video_folder_list)
% Initialize 
current_video = P2.video_folder_list(filenum);    
video_folder = strcat(P2.video_directory, '\', current_video);
cd(video_folder) %Folder with data files   

%% user params
expf = dir('*-*-*_*-*-*.mat');
load(expf.name); % load experiment file into E struct
bdf = dir('*_analyzed'); % behdepot folder
cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
load('Behavior.mat');
%load('Behavior_Filter.mat');

%% load animal data
id = exp_ID; % load ID

%% define different kinds of events
%contained within struct 'e' (events)
%CS+ with and without laser, with and without shock
%CS- with and without laser, with and without shock
%laser, with and without shock
%shock
% order of list is key for registering events

e.csp = [1;0;0;0]; %e_index = 1 %in CSp cueframes
e.csp_shock = [1;0;1;0];        % in CSp
e.csp_laser = [1;0;0;1];        % in CSp
e.csp_shock_laser = [1;0;1;1];  % in CSp

e.csm = [0;1;0;0]; %e_index = 5 % in CSm cueframes
e.csm_shock = [0;1;1;0];        % in CSm
e.csm_laser = [0;1;0;1];        % in CSm
e.csm_shock_laser = [0;1;1;1];  % in CSm

e.laser = [2;2;0;1]; %e_index = 9 % in laser cueframes
e.shock_laser = [2;2;1;1];     % in laser cue frames  % NB: assumes that laser is coincident or precedes shock
e.shock = [2;2;1;0];           % in shock cue frames

c = struct2cell(e);
e_names = fieldnames(e);
e_index = zeros(1,size(xd,2));
e_freeze = cell(size(c));

if size(xd,1) == 5
    xd = xd(1:4,:);
end
%% create event key
numevents = size(xd,2);
for i = 1:numevents
    match = 0;
    idx = 1;
    while ~match
        if isequal(xd(:,i),c{idx})
            e_index(i) = idx; % e_index is the event index (based on e struct) for each event
            match = 1;
        else
            idx = idx+1;
        end
    end
end

%% collect freezing beh for each event
cspi = 1;
csmi = 1;
laseri = 1;
shocki = 1;

% check for  capitalization of event
fnames = fieldnames(Behavior.Intersect.TemBeh);
for f_i = 1:length(fnames)
    if contains(fnames{f_i},'CSp')
        var_csp = 'CSp';
    end
    if contains(fnames{f_i},'csp')
        var_csp = 'csp';
    end
    if contains(fnames{f_i},'CSm')
        var_csm = 'CSm';
    end
    if contains(fnames{f_i},'csm')
        var_csm = 'csm';
    end
end


for i = 1:numevents
    if e_index(i) >= 1 && e_index(i) < 5  % get CS+ events
        thisfrz =Behavior.Intersect.TemBeh.(var_csp).Freezing.PerBehDuringCue(cspi);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        cspi = cspi+1;
    elseif e_index(i) >=5 && e_index(i) < 9 % get CS- events
        thisfrz =Behavior.Intersect.TemBeh.(var_csm).Freezing.PerBehDuringCue(csmi);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        csmi = csmi+1;
    elseif e_index(i) >=9 && e_index(i) < 11  % get laser events
        thisfrz =Behavior.Intersect.TemBeh.laser.Freezing.PerBehDuringCue(laseri);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        laseri = laseri+1;
    elseif e_index(i) == 11  % get just shock events
        thisfrz =Behavior.Intersect.TemBeh.shock.Freezing.PerBehDuringCue(shocki);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        shocki = shocki+1;
    else
        disp('error. unknown event. Check xd for event code and compare to event struct "e" ');
    end
end

%% get data for overall freezing
total_frz = sum(Behavior.Freezing.Vector) / length(Behavior.Freezing.Vector);
both_tone_vec =Behavior.Temporal.(var_csp).Vector +Behavior.Temporal.(var_csm).Vector;
frz_outside_tone = sum(both_tone_vec == 0 & Behavior.Freezing.Vector == 1) / length(find(both_tone_vec==0));


% get baseline freezing
tone1 = 0;
baseline_frz = [];
if cueframes.(var_csp)(1) < cueframes.(var_csm)(1)
    tone1 = cueframes.(var_csp)(1);
elseif cueframes.(var_csm)(1) < cueframes.(var_csp)(1)
    tone1 = cueframes.(var_csm)(1);
end

if tone1
    baseline_frz = sum(Behavior.Freezing.Vector(1:tone1))/tone1;
end

%% assemble into groups
first = 1;
for i = 1:length(e_freeze)
    if ~isempty(e_freeze{i})
        for j = 1:length(e_freeze{i})
            out_all{alli,1} = id;
            out_all{alli,2} = e_names{i};
            out_all{alli,3} = e_freeze{i}{j};
            alli = alli+1;
        end

        
        if i == 1
            out_avg{avgi,2} = mean(cell2mat(e_freeze{i}));
        elseif i == 3
            out_avg{avgi,3} = mean(cell2mat(e_freeze{i}));
        elseif i == 5
            out_avg{avgi,4} = mean(cell2mat(e_freeze{i}));
        elseif i == 7
            out_avg{avgi,5} = mean(cell2mat(e_freeze{i}));
        elseif i == 9
            out_avg{avgi,9} = mean(cell2mat(e_freeze{i}));
        end
    end
end
    out_avg{avgi,1} = id;
    out_avg{avgi,6} = frz_outside_tone;
    out_avg{avgi,10} = baseline_frz;
    if (~isempty(out_avg{avgi,2}) && ~isempty(out_avg{avgi,3}))
        out_avg{avgi,7} = out_avg{avgi,3} - out_avg{avgi,2};
    end
    if (~isempty(out_avg{avgi,4}) && ~isempty(out_avg{avgi,5}))
        out_avg{avgi,8} = out_avg{avgi,5} - out_avg{avgi,4};
    end
 
    avgi = avgi+1;



%disp('summary_freezing: all trials');
%disp(summary_freezing);
%disp('')

%disp('summary_freezing: animal averages');
%disp(summary_freezing_avg);
disp([id ' done']);
clearvars -except P2 out_all out_avg alli avgi filenum;
end
out_all = cell2table(out_all);
out_all.Properties.VariableNames = {'ID','event','freeze percent'};
out_avg = cell2table(out_avg);
out_avg_vars = {'ID','frz_csp', 'frz_csp_laser','frz_csm','frz_csm_laser','frz_nontone', 'delta_csp', 'delta_csm', 'laser', 'frz_baseline'};
out_avg.Properties.VariableNames = out_avg_vars;

cd(P2.video_directory);
save('FC_posthoc_batch_analysis','out_all','out_avg','out_avg_vars','P2');

%% altered format for easier export to Python pandas
out_avg_py = table();

%%
final = 1;
if final
 writetable(out_all,'summary_freezing.csv');
 writetable(out_avg,'summary_freezing_avg.csv');
end

