% MiniStim v1.2
% started 6/05/2020 by ZZ
% last edit 7/30/2020 ZZ 

% Modular posthoc miniscope analysis suite to examine response to stimuli 
% (or, more generally, time locked events)
% Built around experimental setup in which animal connected to miniscope
% (mscam) receives intermittent light stimuli, which is split to also flash
% onto the corresponding behavior camera (stimcam). 
% Stimulus on and off frames ultclearimately just need to be in the variable
% 'stimframes_ms', first column containing stim on frames, second column
% containing corresponding stim off frames.
% 
% 'stimFrameFinder' looks for brightness flashes and identifies stim
% periods on stimcam, then translates to miniscope frame numbers
%
%'bootstrapStimFunc' takes average response of each cell around the
%stimulus, compares it to a bootstrapped baseline distribution, and looks
%for significant responses (based on numSD)
%
%'globalStimFunc' gets averaged, global respone across all cells around the
%stimulus
% 
%'corrStimFunc' looks at global correlated activity between all cells

%% PARAMS 
clear;
% GENERAL PARAMS %
params.exp_id = 'JF038 Train1';  % identifying info (eg mouse ID, exp ID)
params.sig_type = 'spk'; % choice is 'sig' (normal calcium signal) or 'spk' (deconvolved signal)
params.dosave = true; % saves analysis and plots in subdir of source folder
params.doplot = true; % individually plots responses
id = [params.exp_id ' stim response'];

% CHOOSE WHICH ANALYSES TO DO %
params.load_stimtimes = true; % if false, analyzes video for stim flashes; if true, loads them from file
do_single_cell = false; % do analysis at single cell level
do_global = false; % do analysis at global level
do_corr = true; % do global correlation analysis

% PARAMS FOR ALIGNING GATHERING AND ALIGNING STIM FRAMES %
params.mscamnum = 1; % miniscope cam number (typically 0)
params.stimcamnum = 0; % cam recording stim flashes number (typically 1)

% PARAMS FOR BOOTSTRAPSTIMFUNC AND GLOBALSTIMFUNC %
params.tprior = 1; % time (s) to visualize pre stim (integer only)
params.tpost = 10; % time(s) for post stim window (integer only)
params.numSD = 2; % standard deviations to use as criteria for significance (in single cell)

% PARAMS FOR CORRSTIMFUNC %
params.dur = 5; % time (s) to pre- and post-stim 
params.binsz = 0.1; % time (s) to chunk and binarize frame activity (also is the sliding window increment)
params.Rwnd = 1; % time (s) sliding window to average correlation scores


%% point to relevant files
disp('Select processed calcium file');
[ca_file, ca_path] = uigetfile('Select processed calcium file');
disp('Select timestamp file');
[ts_file, ts_path] = uigetfile('*.DAT', 'Select timestamp file');

% load in data and params important params
disp('Loading data')
if params.sig_type == 'sig'
    sig = load([ca_path ca_file], 'sigfn');
    sig = sig.sigfn;
elseif params.sig_type == 'spk'
    sig = load([ca_path ca_file], 'spkfn');
    sig = sig.spkfn;
else
    disp('invalid signal type choice. Defaulting to normal signal')
    sig = load([ca_path ca_file], 'sigfn');
    sig = sig.sigfn;
end

ca_params = load([ca_path ca_file], 'Params');
ds = ca_params.Params.Fsi / ca_params.Params.Fsi_new;
fps = ca_params.Params.Fsi_new;

%% make save dir (if needed)
if params.dosave
    disp('Attempting to make dir')
    savepath = [ca_path params.exp_id 'stim responses\'];    
    mkdir(savepath)
else
    savepath = '';
end
%% find stim times
if params.load_stimtimes
    [st_f, st_p] = uigetfile('Select file with stim times');
    load([st_p st_f], 'stimframes', 'stimframes_ms');
else
    [stimframes, stimframes_ms] = stimFrameFinder([ts_path ts_file], ds, params.mscamnum, params.stimcamnum, savepath);
end
%% functions
if do_single_cell
    disp('Now looking at individual cell responses');
    bootstrapStimFunc(sig, stimframes_ms, fps, params.tprior, params.tpost, params.dosave, id, savepath, params.numSD);
end

if do_global
    disp('Now looking at global responses');
    globalStimFunc(sig, stimframes_ms, fps, params.tprior, params.tpost, params.dosave, params.exp_id, savepath)
end

if do_corr
    disp('Now looking at correlated activity between cells');
    spk = load([ca_path ca_file], 'spkfn');
    spk = spk.spkfn;
    corrStimFunc(stimframes_ms, spk, params.dur, fps, params.binsz, params.Rwnd, savepath, params.dosave)
end