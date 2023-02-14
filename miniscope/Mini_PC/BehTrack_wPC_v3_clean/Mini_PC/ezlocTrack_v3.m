function [locs_match, frluX] = ezlocTrack(mscamnum, behavcamnum, frameStart, frameEnd, px2cm, fps)

%% initialization
[loc_path_name, loc_file_base, loc_file_fmt] = loc_import;
loc_path_name = char(loc_path_name);
loc_file_fmt = char(loc_file_fmt);
loc_file_base = char(loc_file_base);
loc_dirst = dir([loc_path_name, loc_file_base, '*', '.csv']);

[tfile, tpath] = uigetfile('.dat','Select timestamp file');  % file with timestamps of mscam and behcam

tbl2 = [];
locs = [];

%%
% concatenate location data

% convert location directory info to cell array to enable natural sorting
% of file names
tmp_name = {loc_dirst.name};
tmp_name_sort = natsortfiles(tmp_name);
    
for i = 1:size(loc_dirst,1)
    filename = [loc_dirst(i).folder '\' char(tmp_name_sort(i))];
    tbl = readtable(filename);
    tbl2 = table2array(tbl(:,10:12));
    locs = [locs; tbl2];
end

%% align behavior cam and miniscope cam
% using this method, 62% of behavior cam to miniscope cam matches fall
% within +/- 10ms, >99.9% within +/- 25ms.
tbl = readtable(strcat(tpath, tfile));
tbl2 = table2array(tbl);

msframes = [];
behavframes = [];

for i = 1:size(tbl2,1)
    if tbl2(i,1) == mscamnum
        msframes = [msframes; tbl2(i,:)];
    elseif tbl2(i,1) == behavcamnum
        behavframes = [behavframes; tbl2(i,:)];
    end
end

% for each miniscope frame, finds closest behavior frame 
match = [];
for i = 1:size(msframes,1)
    t = msframes(i,3);
    [m,ind] = min(abs(behavframes(:,3) - t));
     match(i) = ind;
end

% make a lookup table, col1 is miniscope frame, col2 is aligned behavior
% frame
frlu = [];
frlu(:,1) = msframes(:,2);
frlu(:,2) = match;

% if no frame is specified for start of analysis, start at 1
if isempty(frameStart)
    frameStart = 1;
    % remove first frame (timestamp is junk)
    msframes = msframes([2:end],[1:3]);
    behavframes = behavframes([2:end],[1:3]);
end

% if no end frame is specified, go til end
if isempty(frameEnd)
    frameEnd = length(behavframes);
end

% only keep frames within start and end boundaries
[r, c] = find(frlu(:,2) >= frameStart & frlu(:,2) <= frameEnd);
frluX = frlu(r,:);
locs_match = locs(frluX(:,2));

%% look for potential tracking errors
spdlim = 100;  %in cm/s
spdlim = spdlim*px2cm/fps_beh;
too_fast = find(locs_match(:,3) > spdlim);

if isempty(too_fast)
    display('no obvious tracking errors');
else
    display('tracking errors occurred. Check frames in array too_fast');
end
    
%% plot movement
% figure;
% hold on
% plot(locs_match(:,1),locs_match(:,2)) % make a plot of where the mouse went
% title('Location Tracking')

figure;
title('Location Tracking')
comet(locs_match(:,1), locs_match(:,2));
end