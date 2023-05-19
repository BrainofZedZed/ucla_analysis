function outputMatrix = batchBDinfo(varargin)
    % Prompt the user to select a directory
    selectedDir = uigetdir('', 'Please select a directory for batch analysis');
    
    % Find all subdirectories within the selected directory
    subDirs = dir(selectedDir);
    subDirs = subDirs([subDirs.isdir]);
    subDirs = subDirs(~ismember({subDirs.name}, {'.', '..'}));
    
    % Initialize the output matrix
    outputMatrix = cell(numel(subDirs)+1, numel(varargin) + 1);
    
    % Set the header row of the output matrix
    outputMatrix(1, 1) = {'exp_ID'};
    outputMatrix(1, 2:end) = varargin;
    
    % Iterate over each subdirectory
    for i = 1:numel(subDirs)
        subDirPath = fullfile(selectedDir, subDirs(i).name);
        
        % Find the file matching the pattern '*-*-*_*-*-*.mat'
        matchingFiles = dir(fullfile(subDirPath, '*-*-*_*-*-*.mat'));
        if isempty(matchingFiles)
            warning('Warning: No matching file found in the directory');
            continue;  % Skip to the next subdirectory
        end
        
        % Initialize the variables
        exp_ID = [];
        inputValues = cell(1, numel(varargin));
        
        % Process each matching file in the subdirectory
        for j = 1:numel(matchingFiles)
            load(fullfile(subDirPath, matchingFiles(j).name), 'exp_ID');
            
            % Find the '_analyzed' directory
            analyzedDir = dir(subDirPath);
            analyzedDir = analyzedDir([analyzedDir.isdir]);
            analyzedDir = analyzedDir(~ismember({analyzedDir.name}, {'.', '..'}));
            analyzedDir = analyzedDir(contains({analyzedDir.name}, '_analyzed'));
            
            if isempty(analyzedDir)
                warning('Warning: "_analyzed" directory not found');
                continue;  % Skip to the next matching file
            end
            
            analyzedDirPath = fullfile(subDirPath, analyzedDir.name);
            
            % Load the 'Behavior.mat' file from the '_analyzed' directory
            behaviorFilePath = fullfile(analyzedDirPath, 'Behavior.mat');
            if ~isfile(behaviorFilePath)
                warning('Warning: "Behavior.mat" file not found');
                continue;  % Skip to the next matching file
            end
            load(behaviorFilePath);
            
            % Save the input values
            for k = 1:numel(varargin)
                inputValues{k} = eval(varargin{k});
            end
            
            % Add the data to the output matrix
            row = i + j;
            outputMatrix{row, 1} = exp_ID;
            for k = 1:numel(inputValues)
                outputMatrix{row, k+1} = inputValues{k};
            end
        end
    end
end
