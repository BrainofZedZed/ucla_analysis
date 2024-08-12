% Load the .mat file containing cueframes
files = dir('*ZZ*.mat');
if isempty(files)
    error('No .mat files with YYYY-MM-DD format found.');
end
matFileName = files(1).name;
load(matFileName, 'cueframes');

% Define buffers
bufferBefore = 50;
bufferAfter = 300;

% Generate csm frames to remove
csmData = [cueframes.csm(:,1)-bufferBefore, cueframes.csm(:,2)+bufferAfter];
csmFramesToRemove = [];
for i = 1:size(csmData, 1)
    csmFramesToRemove = [csmFramesToRemove, csmData(i, 1):csmData(i, 2)];
end
csmFramesToRemove = unique(csmFramesToRemove); % Ensure frames are unique

% Adjust csp indices based on removed csm frames
adjustedCspData = cueframes.csp;
for i = 1:size(cueframes.csp, 1)
    numRemovedBeforeStart = sum(csmFramesToRemove < cueframes.csp(i, 1));
    numRemovedBeforeEnd = sum(csmFramesToRemove < cueframes.csp(i, 2));
    adjustedCspData(i, 1) = cueframes.csp(i, 1) - numRemovedBeforeStart;
    adjustedCspData(i, 2) = cueframes.csp(i, 2) - numRemovedBeforeEnd;
end
cueframes.csp = adjustedCspData;
cueframes = rmfield(cueframes,'csm');
save(matFileName, 'cueframes', '-append');

% adjust shock / US frames similarly
if isfield(cueframes,"us")
    adjustedUSData = cueframes.us;
    for i = 1:size(cueframes.csp, 1)
        numRemovedBeforeStart = sum(csmFramesToRemove < cueframes.us(i, 1));
        numRemovedBeforeEnd = sum(csmFramesToRemove < cueframes.us(i, 2));
        adjustedUSData(i, 1) = cueframes.us(i, 1) - numRemovedBeforeStart;
        adjustedUSData(i, 2) = cueframes.us(i, 2) - numRemovedBeforeEnd;
    end
    cueframes.us = adjustedUSData;
    save(matFileName, 'cueframes', '-append');
end

% Load the CSV file with "DLC" in the filename, including all headers
csvFiles = dir('*DLC*.csv');
if isempty(csvFiles)
    error('No CSV files with "DLC" in the filename found.');
end
DLCdata = readcell(csvFiles(1).name);

% Convert csmActiveFrames to MATLAB indexing considering the headers
adjustedFrames = csmFramesToRemove + 4;  % Adjust for 3 header rows

% Ensure frame indices do not exceed the number of rows
adjustedFrames(adjustedFrames > size(DLCdata, 1)) = [];

% Remove specified frames
DLCdata(adjustedFrames, :) = [];

% Overwrite the original file preserving all headers
writecell(DLCdata, csvFiles(1).name);

% Load 'frtslu.mat', find aligned frames, adjust indices, and save
load('frtslu.mat', 'frtslu');
sigValuesToDrop = frtslu(csmFramesToRemove, 3);
sigValuesToDrop = unique(sigValuesToDrop);

frtslu(csmFramesToRemove,:) = [];

% for col = 2:3 % Adjusting columns 2 and 3
%     for i = 1:size(frtslu, 1)
%         numRemovedBefore = sum(csmFramesToRemove < frtslu(i, col));
%         frtslu(i, col) = frtslu(i, col) - numRemovedBefore;
%     end
% end
save('frtslu.mat', 'frtslu');
% 
% % Load cnmf data, adjust columns, and save
% load('minian_data.mat', 'Cdata', 'Sdata');
% Cdata(:, sigValuesToDrop) = [];
% Sdata(:, sigValuesToDrop) = [];
% save('minian_data.mat', 'Cdata', 'Sdata', '-append');
