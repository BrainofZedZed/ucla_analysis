function [frlu, frlu_cols] = createFrlu(f_tbl, ca_downsample)

% creates a frame lookup (frlu) table converting behavior frames to
% miniscope frames

%% set params and load file
mscamnum = 0;  % miniscope camera number -- typically 0
behcamnum = 1; % behavior camera number -- typically 1

frlu_cols = {'BehavCam', 'Miniscope'};

%frameStart = []; % starting frame to clip section of interest (wrt behavior camera). empty if keep all
%frameEnd = []; % end frame to clip section of interest (wrt behavior camera. empty if keep all

% [tfile, tpath] = uigetfile('.dat','Select miniscope timestamp file');  % file with timestamps of mscam and behcam

%% align behavior cam and miniscope cam

% assumes timestamp file has col1: camNum, col2: frameNum, col3, timestamp,
% col4: buffer

%tbl = readtable(strcat(tpath, tfile));
tbl = table2array(f_tbl);

msframes = [];
behframes = [];

for i = 1:size(tbl,1)
    if tbl(i,1) == mscamnum
        msframes = [msframes; tbl(i,:)];
    elseif tbl(i,1) == behcamnum
        behframes = [behframes; tbl(i,:)];
    end
end

% throw out garbage first frame
msframes = msframes(2:end,:);
behframes = behframes(2:end,:);

% adjust for miniscope temporal downsampling during processing
ds = ca_downsample;
msframes = msframes(1:ds:end,:);    % adjusts for temporal ds

newnum = [1:size(msframes,1)];
newnum = newnum';
msframes(:,2) = newnum;

% for each behavior frame, finds closest miniscope frame 
match = [];
for i = 1:size(behframes,1)
    t = behframes(i,3);
    [~,ind] = min(abs(msframes(:,3) - t));
     match(i) = ind;
end

disp('Aligned timepoints');
%% make a frame lookup (frlu) table, col1 is behavior frame, col2 is miniscope frame
frlu = [];
frlu(:,1) = behframes(:,2);
frlu(:,2) = match;

%% only include section of interest
% if no frame is specified for start of analysis, start at 1
% if isempty(frameStart)
%     frameStart = 1;
% end
% 
% % if no end frame is specified, go til end
% if isempty(frameEnd)
%     frameEnd = length(behframes);
% end

%  only keep frames within start and end boundaries
% [r, ~] = find(frlu(:,2) >= frameStart & frlu(:,2) <= frameEnd);
% frluX = frlu(r,:);
end