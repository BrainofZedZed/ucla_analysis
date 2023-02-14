%% FC_posthoc_analysis
% for posthoc analysis of FC experiments, robust to
% different designs of CS+, CS-, laser, and shock combos

% ASSUMPTIONS:
% 1) BehDEPOT was used to do cued analysis, with CS+ labeled as "CSp", CS-
% as "CSm", laser as "laser", shock as "shock"

%INSTRUCTIONS:  
% 1) manually load: 
% a) experiment file with appended cueframes variable (added via calcCueFrames function)
% b) Behavior_Filter
% c) Behavior
% 2) fill out params (especially condition)
% 3) run
% 3) repeat for each animal (editing condition and summary_file as you go
% along)
% 4) after last iteration, uncomment final writecell lines and run those
% manually

%% user params
id = exp_ID;  % update to custom if desired
condition = 'control'; % experimental condition
timepoint = 14;
% full file path to summary data; if empty, creates new
summary_file = "C:\Users\Zach\Box\Zach_repo\Projects\Remote memory\TeA inhibition\TeA inhibition cohort2\cohort 2 14d_15d_full\batch\ZZ021 14d\ZZ021 14d_analyzed\summary_freezing.mat";
%summary_file = '';
final = 0;  % true when last one
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
for i = 1:numevents
    if e_index(i) >= 1 && e_index(i) < 5  % get CS+ events
        thisfrz = Behavior_Filter.Temporal.CSp.Freezing.PerBehDuringCue(cspi);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        cspi = cspi+1;
    elseif e_index(i) >=5 && e_index(i) < 9 % get CS- events
        thisfrz = Behavior_Filter.Temporal.CSm.Freezing.PerBehDuringCue(csmi);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        csmi = csmi+1;
    elseif e_index(i) >=9 && e_index(i) < 11  % get laser events
        thisfrz = Behavior_Filter.Temporal.laser.Freezing.PerBehDuringCue(laseri);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        laseri = laseri+1;
    elseif e_index(i) == 11  % get just shock events
        thisfrz = Behavior_Filter.Temporal.shock.Freezing.PerBehDuringCue(shocki);
        e_freeze{e_index(i)} = [e_freeze{e_index(i)}, thisfrz];
        shocki = shocki+1;
    else
        disp('error. unknown event. Check xd for event code and compare to event struct "e" ');
    end
end

%% get data for overall freezing
total_frz = sum(Behavior.Freezing.Vector) / length(Behavior.Freezing.Vector);
both_tone_vec = Behavior_Filter.Temporal.CSp.EventVector + Behavior_Filter.Temporal.CSm.EventVector;
frz_outside_tone = sum(both_tone_vec == 0 & Behavior.Freezing.Vector == 1) / length(find(both_tone_vec==0));

%% assemble into groups
% get number of empty cells
nonempty = find(~cellfun(@isempty,e_freeze));

%initialize vars
out_all = cell(numevents,5);
out_avg = cell(length(nonempty),7);
alli = 1;
avgi = 1;

for i = 1:length(e_freeze)
    if ~isempty(e_freeze{i})
        for j = 1:length(e_freeze{i})
            out_all{alli,1} = id;
            out_all{alli,2} = condition;
            out_all{alli,3} = timepoint;
            out_all{alli,4} = e_names{i};
            out_all{alli,5} = e_freeze{i}{j};
            alli = alli+1;
        end
        out_avg{avgi,1} = id;
        out_avg{avgi,2} = condition;
        out_avg{avgi,3} = timepoint;
        out_avg{avgi,4} = e_names{i};
        out_avg{avgi,5} = mean(cell2mat(e_freeze{i}));
        out_avg{avgi,6} = total_frz;
        out_avg{avgi,7} = frz_outside_tone;
        avgi = avgi+1;
    end
end

if ~isempty(summary_file)
    load(summary_file);
    summary_freezing = [summary_freezing; out_all];
    summary_freezing_avg = [summary_freezing_avg; out_avg];
    save(summary_file, 'summary_freezing', 'summary_freezing_avg');
else
    summary_freezing_avg = out_avg;
    summary_freezing = out_all;
    save('summary_freezing.mat','summary_freezing', 'summary_freezing_avg');
end

%disp('summary_freezing: all trials');
%disp(summary_freezing);
%disp('')

%disp('summary_freezing: animal averages');
%disp(summary_freezing_avg);
disp([id ' done']);
clear;
%%
% if final
 writecell(summary_freezing,'summary_freezing.csv');
 writecell(summary_freezing_avg,'summary_freezing_avg.csv');
% end