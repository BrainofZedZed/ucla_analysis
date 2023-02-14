% PMA_posthoc_analysis
% created 6/30/21 ZZ

% ASSUMPTIONS:
% 1) BehDEPOT was used to do cued analysis, with CS+ labeled as "CSp", 
% "platform" as platform
% 2) BehDEPOT output folder is labeled '*_analyzed' and resides within
% animal folder, which contains video, .mat experiment file, and CSV DLC
% output

%INSTRUCTIONS: 
% Point to grandparent folder, containing individual animals organized as
% described above. Let run. Creates 'out_all' and 'out_avg' table, with
% freezing rates for different events
%% INSTRUCTIONS
% 1) load in Behavior, Behavior_Filter, Metrics

%% Params
id = 'DP014_PMA_D0';
fps = 50; % fps of behavior recording
baseline_tones = 3;  % number of baseline tones not paired with shock
dur_tone = 30; % (s) duration of tone
dur_shock = 2; % (S) duration of shock


load('Behavior.mat');
load('Behavior_Filter.mat');

%% Part 1: time freezing during tone
tone_frz = Behavior_Filter.Temporal.CSp.Freezing.PerBehDuringCue;
tone_frz = cell2mat(tone_frz);
tone_frz = tone_frz*100;

%% Part 2: percent time freezing on platform during tone
tmp = Behavior_Filter.Intersect.SpaTemBeh.Freezing_platform_CSp_CueVectors;
tone_platform_frz = (sum(tmp,2)) ./ length(tmp);
tone_platform_frz = tone_platform_frz';
tone_platform_frz(isnan(tone_platform_frz)) = 0;
per_tpf = tone_platform_frz ./ tone_frz;
per_tpf = per_tpf*100;


%% Part 3:  percent time on platform, per tone
per_tp_tone = Behavior_Filter.Intersect.ROIduringCue_PerTime.CSp_platform;
per_tp_tone = cell2mat(per_tp_tone);
per_tp_tone = per_tp_tone*100;

%% Part 4:  latency to platform, per tone
pf_tone_vec = Behavior_Filter.Intersect.ROIduringCue_Vector.CSp_platform;
first_pf = zeros(1,size(pf_tone_vec,1));
for i = 1:size(pf_tone_vec,1)
    this = find(pf_tone_vec(i,:), 1, 'first');
    if isempty(this)
        first_pf(i) = size(pf_tone_vec,2);
    else
        first_pf(i) = this;
    end
end

first_pf = round(first_pf ./ fps);   % convert to seconds

%% Part 5: batch output
out.tone_frz = num2cell(tone_frz);
out.tone_frz = [{id}, out.tone_frz];
out.per_platform_frz = [{id}, num2cell(per_tpf)];
out.per_time_platform = [{id}, num2cell(per_tp_tone)];
out.plat_latency = [{id}, num2cell(first_pf)];