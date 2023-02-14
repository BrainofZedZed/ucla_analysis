
clear;
workspace;  % Make sure the workspace panel is showing.


% Define a starting folder.
start_path = 'E:\External_Desktop\Documents\MATLAB\MIN1PIPE-master\behTrack_wPC_v3_20190919\behTrack_wPC_v3_20190919';
% Ask user to confirm or change.
topLevelFolder = uigetdir(start_path);
if topLevelFolder == 0
	return;
end
% Get list of all subfolders.
allSubFolders = genpath(topLevelFolder);
% Parse into a cell array.
remain = allSubFolders;
listOfFolderNames = {};
while true
	[singleSubFolder, remain] = strtok(remain, ';');
	if isempty(singleSubFolder)
		break;
	end
	listOfFolderNames = [listOfFolderNames singleSubFolder];
end
listOfFolderNames = listOfFolderNames(2:end);
numberOfFolders = length(listOfFolderNames)

makematrix = true;
m80vtrain = ["misc080_vermis_ofolm_training", "80", "pos", "vermis", "vermis", "training"];
dur = 20; % time in seconds for winddow
normfps = 20;
stimdur_array = [];
fps_array = [];
id_array = "";
%% step 1:  get list of PCs from comparison file
% Process all image files in those folders.
for k = 1 : numberOfFolders
	% Get this folder and print it out.
	thisFolder = listOfFolderNames{k};
	%fprintf('Processing folder %s\n', thisFolder);
	
    % Get file names
    filePattern = sprintf('%s/behPC*.mat', thisFolder);
	baseFileNames = dir(filePattern);
    
	% Now we have a list of all files in this folder.
    numberOfFiles = length(baseFileNames);

	if numberOfFiles >= 1
		% Go through all those files.
		for f = 1 : numberOfFiles
            fullFileName = fullfile(thisFolder, baseFileNames(f).name);
			data = load(fullFileName);            
            % get ID
            id = data.id;
            stimtimes = data.pstimData.peristimframes;
            fps = data.fps;
            
            for stms = 1:size(stimtimes,1)
                d = (stimtimes(stms,2)-stimtimes(stms,1));
                stimdur_array = [stimdur_array; d];
                fps_array = [fps_array; fps];
                id_array = [id_array; id];
            end
        end
    end
end

