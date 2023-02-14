%% Fiber Photometry Epoc Averaing
% created 6/7/22 ZZ
% last edit 8/17/22 ZZ
% TODO:  fix artifact cleaner, change plot xaxis to use seconds instead of
% frames

% Heavily based on the TDT example, originally by David Root and the 
% Morales Lab. 
% Requires BehaviorDEPOT output (Gabriel et al 2022) and TDT Fiber 
% Photometry system. Requires TDTbin2mat to be on path.

% Edit Manual entires below and run to generate and save zscored fiber
% photometry signal around the epoc of interest (TDT signal or event bouts,
% and heatmap plot. Saves to BD_dir. 
%% Manual entries
mouse = 'ZZ138_hab'; % name of subject (used for saving)
BLOCKPATH = 'C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\TeA_fiber_photometry\cohort2\photometry recordings\zz138-220810-151003'; % path to TDT data

exp_file = 'C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\TeA_fiber_photometry\cohort2\batch\zz138_hab\zz138_hab_2022-08-10_15-30-12.mat'; % char path to experiment file
BD_dir = 'C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\TeA_fiber_photometry\cohort2\batch\zz138_hab\zz138_hab_analyzed'; % char path to BehDEPOT folder
exp_ref_epoc_name = 'CSp'; % name of REF_EPOC in experiment file, used for Behavior:FP frame alignment

do_tdt_epoc = false; % true if want to average FP epoc
REF_EPOC = 'PC2_'; % name of FP epoc in TDT system

do_beh_epoc = true; % true if want to average beh epoc
beh_file = [BD_dir '\Behavior.mat']; % edit if want to use Behavior file instead
load(beh_file);
beh_epoc = Behavior.Temporal.CSp.Bouts; % beh epoc of interest in bouts [start, stop]

STREAM_STORE1 = 'x405A'; % name of the 405 store
STREAM_STORE2 = 'x465A'; % name of the 465 store
FP_DS_FACTOR = 10; % factor by which to downsample FP recording
TRANGE_pre = 3; % seconds to take BEFORE START of epoc
TRANGE_post = 3; % seconds to take AFTER END of epoc
BASELINE_PER = [-3 0]; % baseline period relative to epoc onset
%ARTIFACT = Inf; % optionally set an artifact rejection level
beh_fps = 49.974; % fps of behavior camera

start_trim = 10; %seconds to trim from start of recording

%% optional transform and threshold vector into bouts
%z = findStartStop(Behavior_Filter.Spatial.platform.inROIvector);
%beh_epoc = applymin2bouts(z,100);

%% load, clean, transfor, align FP data
data = TDTbin2mat(BLOCKPATH, 'TYPE', {'epocs', 'scalars', 'streams'});
% create frame lookup translating FP to behavior frames
beh2fp = beh2FPfrlu(exp_file, beh_file, data, exp_ref_epoc_name, REF_EPOC);

% load 465 from 405 signal and downsample
s465 = data.streams.x465A.data;
s405 = data.streams.x405A.data;

% downsample
s465 = s465(1:FP_DS_FACTOR:end);
s405 = s405(1:FP_DS_FACTOR:end);
beh2fp = round(beh2fp / FP_DS_FACTOR);

% Create mean signal, standard error of signal, and DC offset of 405 signal
meanSignal1 = mean(s405);
stdSignal1 = std(double(s405))/sqrt(size(s405,1));
dcSignal1 = mean(meanSignal1);

% Create mean signal, standard error of signal, and DC offset of 465 signal
meanSignal2 = mean(s465);
stdSignal2 = std(double(s465))/sqrt(size(s465,1));
dcSignal2 = mean(meanSignal2);

% Subtract DC offset to get signals on top of one another
meanSignal1 = meanSignal1 - dcSignal1;
meanSignal2 = meanSignal2 - dcSignal2;

% Fitting 405 channel onto 465 channel to detrend signal bleaching
% Algorithm sourced from Tom Davidson's Github:
% https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m
bls_all = polyfit(s405(1:end), s465(1:end), 1);
Y_fit_all = bls_all(1) .* s405 + bls_all(2);
sig = s465 - Y_fit_all;


%% Calculate signal over epocs
% Load the bouts
if do_tdt_epoc
    bouts = data.epocs.(REF_EPOC).onset;
else
    bouts = (beh_epoc);
end
% Create the time vector for each stream store
ts1 = round(bouts(:,1) - (TRANGE_pre*beh_fps));
ts2 = round(bouts(:,2) + (TRANGE_post*beh_fps));

% enforce same length
tmp_dur = ts2-ts1;
beh_ts = [ts1, ts1+min(tmp_dur)];

% get fp frames corresponding to beh frames, enforce same length
fp_ts = round(beh2fp(beh_ts));
tmp_dur = fp_ts(:,2) - fp_ts(:,1);
fp_ts = [fp_ts(:,1), fp_ts(:,1)+min(tmp_dur)];
epoc_length = min(tmp_dur)+1;

% get baseline frames
bl_beh = round([beh_ts(:,1)+(BASELINE_PER(1)*beh_fps), beh_ts(:,1)+(BASELINE_PER(2)*beh_fps)]);
bl_fp = beh2fp(bl_beh);
tmp_dur = bl_fp(:,2) - bl_fp(:,1);
bl_fp = [bl_fp(:,1), bl_fp(:,1)+min(tmp_dur)];
bl_length = min(tmp_dur);


% get signal for all trials and zscore
zall = zeros(size(bouts,1),epoc_length);

for i = 1:size(zall,1)
    zb = mean(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period mean
    zsd = std(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period stdev
    zall(i,:)=(sig(fp_ts(i,1):fp_ts(i,2)) - zb)/zsd; % Z score per bin
end

% get pre fp frame length for plotting
pre_dur = beh2fp(bouts(1,1))- fp_ts(1,1);
post_dur = beh2fp(beh_ts(1,2)) - beh2fp(bouts(1,2));

% Plot heat map
fig = figure;
imagesc(zall)
colormap('parula'); 
c1 = colorbar; 
title(sprintf('Z-Score Heat Map, %d Trials', size(beh_epoc,1)));
ylabel('Trials', 'FontSize', 12);
hold on;
xline(pre_dur, ':', 'LineWidth', 1);
xline(epoc_length - post_dur, ':', 'LineWidth', 1);

% get FP fps (downsample adjusted) to label xaxis
fp_fps = data.streams.x465A.fs;
fp_fps = round(fp_fps/FP_DS_FACTOR);
xlabel(sprintf('frames (@ %d frames per second)', fp_fps));

filename = sprintf('%s%s', mouse, '_Epoc_HeatMap');
filename = [BD_dir '\' filename];
saveas(fig, filename);

mouseTS = struct;
mouseTS.epoc.zall = zall;
mouseTS.epoc.beh_data_range = beh_ts;
mouseTS.epoc.fps = data.streams.x465A.fs;
mouseTS.epoc.downsample = FP_DS_FACTOR;
mouseTS.epoc.behavior_frames = beh_ts;
mouseTS.epoc.fp_frames = fp_ts;
mouseTS.epoc.signal = sig;
mouseTS.epoc.beh2fibpho_frame = beh2fp;
save([BD_dir '\FibPhoData.mat'], 'mouseTS');

%% save key info
CSm = Behavior.Temporal.CSm.Bouts;
CSp = Behavior.Temporal.CSp.Bouts;
freezing_bouts = Behavior.Freezing.Bouts;
subject = mouse;
home_dir = pwd;
signal = sig;
cd(BD_dir);
save('fibpho_data_out.mat',"subject","CSp","CSm","freezing_bouts","signal","beh2fp")
cd(home_dir);
%% create behavior and signal plot
% using whole dta vector, limiting axis to break up data
% calculate start trim
beh_vec = Behavior.Temporal.CSp.Vector;
bhsig = sig(beh2fp);
zsig = (bhsig - mean(bhsig)) / std(bhsig);
t_display = 240; % seconds to display in a row
disp_length = round(t_display * beh_fps);
num_rows = ceil(length(beh_vec)/disp_length); % number of rows to break data into
ct = 0;

for i = 1:num_rows
    s_frame = (i-1)*disp_length + 1;
    ct = ct+1;
    m = ['ax' num2str((i*2)-1)];
    
    %plot beh vec
    axes.(m) = subplot(num_rows*2,1,(i*2)-1);
    imagesc(axes.(m), beh_vec);
    xlim(axes.(m),[s_frame s_frame+disp_length]);
    axes.(m).Colormap('hot');
    axes.(m).FontSize = 5;
    
    %plot sig vec
    ct = ct+1;
    n = ['ax' num2str((i*2))];
    axes.(n) = subplot(num_rows*2,1,i*2);
    imagesc(axes.(n), bhsig); 
    xlim(axes.(n),[s_frame s_frame+disp_length]);
    axes.(n).Colormap('parula');
    axes.(n).FontSize = 5;
    
    %link axes
    linkaxes([axes.(m) axes.(n)], 'xy');
end

%% OTHER CODE BELOW
%%
%%
%%
%% Quantify changes as area under the curve for tone onset, offset, all tone, and shock 
% rowNames = {'tone onset', 'shock', 'all tone', 'tone offset'};
% 
% for i = 1:size(zall,1)
%     aucPeakTones(1,i) = trapz(zall(i,ts2(1,:) > 0 & ts2(1,:) < 3));
%     aucPeakTones(2,i) = trapz(zall(i,ts2(1,:) > 28 & ts2(1,:) < 30));
%     aucPeakTones(3,i) = trapz(zall(i,ts2(1,:) > 0 & ts2(1,:) < 30));
%     aucPeakTones(4,i) = trapz(zall(i,ts2(1,:) > 30 & ts2(1,:) < 33));
% end
% 
% aucPeakTones = array2table(aucPeakTones, 'RowNames', rowNames);
% 
% mouseTS.Tones.aucTones = aucPeakTones;
% save('FibPhoData.mat', 'mouseTS');
%% internal functions
function beh2fp = beh2FPfrlu(exp_file, beh_file, TDTdata, ref_epoc_name, REF_EPOC)
% GOAL: Create a frame lookup table to translate fiber photometry frames
% to Behavior frames (using Fear Conditioning Experiment Designer and 
% BehDEPOT output). NB: assumes a PC0 was recorded on TDT system. 
% INPUT:  exp_file (path to Fear Conditioning Experiment Designer file with
% variable cueframes inside), BehFilt_file (path to Behavior_Filter from 
% BehDEPOT output), TDTdata (output from TDTbin2mat), PC0name (string; name of PC0
% signal in exp_file, eg "tone" or "csp")
% OUTPUT:  frame lookup table translating TDT fiber photometry frames to
% behavior frames. Example:  beh2fp(1) = N, where 1 is behavior frame 1
% which corresponds to FP frame N

% load experiment file, Behavior_Filter
expf = load(exp_file);
load(beh_file);

% get cueframes from experiment file and PC0 timing from TDT
cueframes = expf.cueframes.(ref_epoc_name);

fp.pc0_times = [TDTdata.epocs.(REF_EPOC).onset, TDTdata.epocs.(REF_EPOC).offset]; 
fp.fps = TDTdata.streams.x465A.fs;
fp.pc0_frames = fp.pc0_times * fp.fps;

% interporlate between synchronized behavior and FP points, breaking into
% epocs for additional accuracy (shoutout Ben)

% find length of behavior, insensitive to fieldnames 
tempfld1 = fields(Behavior);
tempfld2 = fields(Behavior.(tempfld1{1}));
tempfld3 = fields(Behavior.(tempfld1{1}).(tempfld2{1}));
tempidx = find(contains(tempfld3, 'vector', 'IgnoreCase', true));
behsz = length(Behavior.(tempfld1{1}).(tempfld2{1}).(tempfld3{tempidx}));

beh_frames = cueframes;
fp_frames = fp.pc0_frames;

temp_BEHs(1)=1; % set first behavior index = 1 
for iii=1:size(beh_frames,1)
    temp_BEHs=[temp_BEHs,round(beh_frames(iii,:))]; % calc behavior indices based on tone onset/offset
end
temp_BEHs=[temp_BEHs,behsz]; % set last behavior index = length of behavior

temp_FPs=[]; % initialize FPs variable
for iii=1:size(fp_frames,1) 
    temp_FPs=[temp_FPs,round(fp_frames(iii,:))]; % calc FP indices based on tone onset/offset
end
temp_FPs=[round(temp_FPs(1)-(temp_BEHs(2)-1)/(temp_BEHs(3)-temp_BEHs(2))*(temp_FPs(2)-temp_FPs(1))),temp_FPs,round(temp_FPs(end)-(temp_BEHs(end-1)-temp_BEHs(end))/(temp_BEHs(end-2)-temp_BEHs(end-1))*(temp_FPs(end-1)-temp_FPs(end)))]; % extrapolate backwards from first tone and forwards from last tone to calc first/last FP indices

vq=interp1(temp_BEHs,temp_FPs,1:behsz); % use interp1 function for linear interpolation between each pair of BEH/FP points
beh2fp=round(vq); % round resultant intperolation so the indices are integers
end