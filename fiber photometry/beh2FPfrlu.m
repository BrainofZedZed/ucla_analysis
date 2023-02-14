function beh2fp = beh2FPfrlu(cueframes_in, TDTdata, cue, numFrames)
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

% get cueframes from experiment file and PC0 timing from TDT
cueframes = cueframes_in.(cue{2});
fp.pc_times = [TDTdata.epocs.(cue{1}).onset, TDTdata.epocs.(cue{1}).offset]; 
fp.fps = TDTdata.streams.x465A.fs;
fp.pc0_frames = fp.pc_times * fp.fps;

% interporlate between synchronized behavior and FP points, breaking into
% epocs for additional accuracy (shoutout Ben)

% find length of behavior, insensitive to fieldnames 
behsz = numFrames;

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