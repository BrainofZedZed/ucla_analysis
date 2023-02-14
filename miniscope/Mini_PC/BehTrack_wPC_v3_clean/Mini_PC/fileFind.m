function [output] = fileFind(fpattern)

 % fpattern = '%s/behPC*.mat';
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


for k = 1 : numberOfFolders
	% Get this folder and print it out.
	thisFolder = listOfFolderNames{k};
	%fprintf('Processing folder %s\n', thisFolder);
	
    % Get file names
    filePattern = sprintf(fpattern, thisFolder);
	baseFileNames = dir(filePattern);
    
	% Now we have a list of all files in this folder.
    numberOfFiles = length(baseFileNames);
end

		fullFileName = fullfile(thisFolder, baseFileNames(f).name);

end