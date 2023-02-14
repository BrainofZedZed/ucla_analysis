% MiniPC (MINIscope Place Cells)   
% ZZ 2020.02.20
% for aligning animal location and calcium imaging data, then identifying
% place cells and visualzing place fields

% INPUTS
% manual in settings:  cam numbers, frame synchronization numbers, size
% calibrations, behavior camera fps
% prompted:  processed calcium file from MIN1PIPE, timestamp file for msCam
% and animalCam, animal location data (from ezTrack output .csv files assuming two object locations)

% OUTPUTS
% Folder in MiniPC directory containing place fields and a .mat file with a 
% list of place cells, calcium data, location data, speed filtered data,
% spatial information, params, and other calculcations

%% settings
clear;
mscamnum = 0;
dummybehavcamnum = 1;  % cam num on timestamp file from miniscope computer; used to synchronize other camera
behavcamnum = 0;

dorawCa2 = false; % choose whether to use deconvolved or raw calcium transients

frame_beh_sync = 4116;  % synced frame on behavior cam
frame_ms_sync = 5198;    % synced frame on ms_beh cam (dummybehavcam) 

frameStart = 6922; % behavior frame to begin  ([] = beginning)
frameEnd = [];  % behavior frame to end ([] = end)

px2cm = 8; % how many pixels in a centimeter
binsz = 2.5;  % how many cm x cm in each spatial bin (binsz x binsz cm^2 bins)
spdreq = 2.5;   % min speed (in cm/s) for data to be included
fps_beh = 30; %fps of the behavior camera
numshuf = 500;  % number of shuffles to do for shuffled analysis

ID = '87v';
id = strcat(ID,'_training'); % ID (mouse and session) for saving file

dosave = true;  % true or false

%% load spike data and frame timestamps
[cafile, capath] = uigetfile('Select processed calcium data');
if dorawCa2 == 1
    load(strcat(capath, cafile), 'sigfn');
    load(strcat(capath, cafile), 'Params');
    fps_orig = Params.Fsi;
    fps = Params.Fsi_new;
    
    nn = size(sigfn,1);
else
    load(strcat(capath, cafile), 'spkfn');
    load(strcat(capath, cafile), 'sigfn');
    load(strcat(capath, cafile), 'Params');
    fps_orig = Params.Fsi;
    fps = Params.Fsi_new;
    nn = size(spkfn,1);
end
    
%% location tracking concatenation (and error correction)
    [locs_dist, frluX, frlu, objz, too_fast, locs] = ezlocTrack_v3_2TS(mscamnum, behavcamnum, dummybehavcamnum, frame_beh_sync, frame_ms_sync, frameStart, frameEnd, px2cm, fps_beh, fps_orig, fps);

    
%% bin pixel space into cm and make firing maps
if dorawCa2 == true
    [spkmap, gridprob, xedges, yedges, spkfn_fp, spkgrd, locs_dist_fp, spkmap_entry, gridcount] = binNFire_v3_rawCa2(px2cm, binsz, sigfn, locs_dist, spdreq, fps, frluX, fps_beh, minpeakprom);
else
    [spkmap, gridprob, xedges, yedges, spkfn_fp, spkgrd, locs_dist_fp, spkmap_entry, gridcount] = binNFire_v3(px2cm, binsz, spkfn, locs_dist, spdreq, fps, frluX, fps_beh);
end
%% calculate spatial information
    [SI, SI_rand, spkmap_rand, PC, smth_spkmap, smth_gridtime] = calcSI_v3_locshuf(spkfn_fp, locs_dist_fp, gridprob, nn, spkmap, numshuf, fps, xedges, yedges, fps_beh, gridcount);

%% analyze PCs
[PC_info, pc_ratemap, per_binoc] = analyzePCs (PC, spkmap, id, fps, gridprob, spkfn_fp, binsz);

%% save
if dosave
    filename = strcat(['behPC_results_' id '.mat']);
    Params = struct;
    Params.mscamnum = mscamnum;
    Params.dummybehavcam = dummybehavcam;
    Params.behavcamnum = behavcamnum;
    Params.dorawCa2 = dorawCa2;
    Params.frame_beh_sync = frame_beh_sync;
    Params.frame_ms_sync = frame_ms_sync;
    Params.frameStart = frameStart;
    Params.frameEnd = frameEnd;
    Params.px2cm = px2cm;
    Params.binsz = binsz;
    Params.spdreq = spdreq;
    Params.fps_beh = fps_beh;
    Params.numshuf = numshuf;

    save([pwd '\' id '\' filename], 'Params', 'id', 'PC', 'SI', 'SI_rand', 'spkmap', 'smth_spkmap', 'spkfn_fp', 'spkfn', 'sigfn', 'gridprob', 'spkgrd', 'locs_dist_fp', 'locs_dist', 'frluX', 'objz', 'PC_info', 'pc_ratemap', 'fps', 'per_binoc', 'spkmap_entry');
end
