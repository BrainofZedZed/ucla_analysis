%% PARAMS TO EDIT
% Set your base directory
baseDir = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\fear conditioning\FC opto\cohort1_20231127\batch105 d0'; % Replace with your directory path

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
    currentDir = fullfile(baseDir, subDirs(i).name);
    
    % Skip '.' and '..' directories
    if strcmp(subDirs(i).name, '.') || strcmp(subDirs(i).name, '..')
        continue;
    end

    % Load exp_ID
    idFile = dir(fullfile(currentDir, '*-*-*_*-*-*.mat'));
    if ~isempty(idFile)
        idData = load(fullfile(idFile.folder, idFile.name));
        exp_ID = idData.exp_ID;
        t_baseline = idData.t_baseline;
    else
        continue; % Skip if no ID file found
    end

    % Look for the '_analyzed' folder
    analyzedDir = dir(fullfile(currentDir, '*_analyzed'));
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

    % Extract and process data
    CSp_frz_all = behaviorData.Behavior.Intersect.TemBeh.CSp.Freezing.PerBehDuringCue;
    CSp_frz_avg = mean(cell2mat(CSp_frz_all));
    if isfield(behaviorData.Behavior.Intersect.TemBeh,'CSm')
        CSm_frz_all = behaviorData.Behavior.Intersect.TemBeh.CSm.Freezing.PerBehDuringCue;
        CSm_frz_avg = mean(cell2mat(CSm_frz_all));
        CSm_flag = true;
    else
        CSm_frz_all = NaN(size(CSp_frz_all));
        CSm_frz_avg = NaN;
        CSm_flag = false;
    end

    % Compute context freezing
    totalFreezing = sum(behaviorData.Behavior.Freezing.Vector);
    CSpSum = sum(behaviorData.Behavior.Intersect.TemBeh.CSp.Freezing.BehInEventVector);
    if CSm_flag
        CSmSum = sum(behaviorData.Behavior.Intersect.TemBeh.CSm.Freezing.BehInEventVector);
    else
        CSmSum = NaN;
    end
        context_frz = (totalFreezing - (CSpSum + CSmSum))/length(behaviorData.Behavior.Freezing.Vector);
    
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

% Display the final table
disp(resultTable);
save([baseDir '\' savefile],"resultTable");
