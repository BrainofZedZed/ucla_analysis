%% PARAMS TO EDIT
% Set your base directory
baseDir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\good\CSminus removed\'; % Replace with your directory path
% set the output save name
savefile = 'freezing_data.mat';
%%
% Initialize the table
resultTable = table([], [], [], [], [], [], [], [], 'VariableNames', ...
    {'exp_ID', 'CSp_frz_all', 'CSm_frz_all', 'CSp_frz_avg', 'CSm_frz_avg', 'Discrim Index', 'baseline_frz','context_frz'});

% List all subdirectories in the base directory
subDirs = dir(baseDir);
subDirs = subDirs([subDirs.isdir]); % Filter only directories

for i = 1:length(subDirs)
    % Skip '.' and '..' directories
    if strcmp(subDirs(i).name, '.') || strcmp(subDirs(i).name, '..')
        continue;
    end
    
    currentDir = fullfile(baseDir, subDirs(i).name);
    
    % Get all subdirectories within the current directory
    deepDirs = dir(currentDir);
    deepDirs = deepDirs([deepDirs.isdir]); % Filter only directories
    
    % Loop through each deep directory
    for j = 1:length(deepDirs)
        % Skip '.' and '..' directories and 'D0' directories
        if strcmp(deepDirs(j).name, '.') || strcmp(deepDirs(j).name, '..') || ...
           endsWith(deepDirs(j).name, 'D0')
            continue;
        end
        
        deepCurrentDir = fullfile(currentDir, deepDirs(j).name);        
        % Load exp_ID
        idFile = dir(fullfile(deepCurrentDir, '*-*-*_*-*-*.mat'));
        if ~isempty(idFile)
            idData = load(fullfile(idFile.folder, idFile.name));
            exp_ID = idData.exp_ID;
            t_baseline = idData.t_baseline;
        else
            continue; % Skip if no ID file found
        end
        
        % Look for the '_analyzed' folder
        analyzedDir = dir(fullfile(deepCurrentDir, '*_analyzed'));
        if isempty(analyzedDir) || ~analyzedDir.isdir
            continue; % Skip if no analyzed folder found
        end
        
        % Load framerate
        Params = load(fullfile(analyzedDir.folder, analyzedDir.name, 'Params.mat'));
        frameRate = Params.Params.Video.frameRate;
        baseline_frames = t_baseline*frameRate;
        
        % Load Behavior.mat from the '_analyzed' folder
        behaviorFile = fullfile(analyzedDir.folder, analyzedDir.name, 'Behavior.mat');
        if isfile(behaviorFile)
            behaviorData = load(behaviorFile);
        else
            continue; % Skip if no Behavior file found
        end
        
        % Extract and process data using case-insensitive field access
        behavIntersect = behaviorData.Behavior.Intersect.TemBeh;
        
        % Look for CSp/csp
        cspData = getFieldCI(behavIntersect, 'CSp');
        if ~isempty(cspData)
            CSp_frz_all = cspData.Freezing.PerBehDuringCue;
            CSp_frz_avg = mean(cell2mat(CSp_frz_all));
            CSpSum = sum(cspData.Freezing.BehInEventVector);
        else
            continue; % Skip if no CSp data found
        end
        
        % Look for CSm/csm
        csmData = getFieldCI(behavIntersect, 'CSm');
        if ~isempty(csmData)
            CSm_frz_all = csmData.Freezing.PerBehDuringCue;
            CSm_frz_avg = mean(cell2mat(CSm_frz_all));
            CSmSum = sum(csmData.Freezing.BehInEventVector);
            CSm_flag = true;
        else
            CSm_frz_all = NaN(size(CSp_frz_all));
            CSm_frz_avg = NaN;
            CSmSum = NaN;
            CSm_flag = false;
        end
        
        % Compute context freezing
        totalFreezing = sum(behaviorData.Behavior.Freezing.Vector);
        context_frz = (totalFreezing - (CSpSum + CSmSum))/length(behaviorData.Behavior.Freezing.Vector);
        
        if CSm_flag
            CSmSum = sum(behaviorData.Behavior.Intersect.TemBeh.CSm.Freezing.BehInEventVector);
        else
            CSmSum = NaN;
        end
                
        % get baseline freezing pretone
        baseline_frz = sum(behaviorData.Behavior.Freezing.Vector(1:baseline_frames))/baseline_frames;
        
        % compute discrim index
        if CSm_flag
            di = (CSp_frz_avg - CSm_frz_avg) / (CSp_frz_avg + CSm_frz_avg);
        else
            di = NaN;
        end
        
        % Add to table
        resultTable = [resultTable; {exp_ID, CSp_frz_all, CSm_frz_all, CSp_frz_avg, CSm_frz_avg, di, baseline_frz, context_frz}];
    end
end

% Display the final table
disp(resultTable);
save([baseDir '\' savefile],"resultTable");


%% Helper function for case-insensitive field search
function value = getFieldCI(struct, fieldName)
    % Get all field names
    fields = fieldnames(struct);
    % Find case-insensitive match
    idx = find(strcmpi(fields, fieldName));
    if ~isempty(idx)
        % Get the actual field name with correct case
        actualFieldName = fields{idx};
        % Return the value
        value = struct.(actualFieldName);
    else
        value = [];
    end
end