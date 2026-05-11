%% PARAMS TO EDIT
% Set your base directory
baseDir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\discrimination\bd batch\bd batch done';
% set the output save name
savefile = 'freezing_data.mat';

%%
% Initialize the table with more appropriate structure
resultTable = table('Size', [0, 10], ...
    'VariableTypes', {'string', 'cell', 'cell', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'exp_ID', 'CSp_frz_all', 'CSm_frz_all', 'CSp_frz_avg', 'CSm_frz_avg', ...
    'Discrim_Index', 'baseline_frz', 'context_frz', 'num_CSp_trials', 'num_CSm_trials'});

% List all subdirectories in the base directory
subDirs = dir(baseDir);
subDirs = subDirs([subDirs.isdir]);

for i = 1:length(subDirs)
    % Skip '.' and '..' directories and 'D0' directories
    if strcmp(subDirs(i).name, '.') || strcmp(subDirs(i).name, '..') || ...
       endsWith(subDirs(i).name, 'D0')
        continue;
    end

    currentDir = fullfile(baseDir, subDirs(i).name);

    try
        % Load exp_ID and t_baseline from the ID file in currentDir
        idFile = dir(fullfile(currentDir, '*-*-*_*-*-*.mat'));
        if isempty(idFile)
            warning('No ID file found for directory: %s', currentDir);
            continue;
        end

        idData = load(fullfile(idFile.folder, idFile.name));
        exp_ID = string(idData.exp_ID);
        t_baseline = idData.t_baseline;

        % Look for the '_analyzed' folder
        analyzedDir = dir(fullfile(currentDir, '*_analyzed'));
        if isempty(analyzedDir) || ~analyzedDir.isdir
            warning('No analyzed folder found for directory: %s', currentDir);
            continue;
        end

        % Load framerate
        Params = load(fullfile(analyzedDir.folder, analyzedDir.name, 'Params.mat'));
        frameRate = Params.Params.Video.frameRate;
        baseline_frames = t_baseline * frameRate;

        % Load Behavior.mat from the '_analyzed' folder
        behaviorFile = fullfile(analyzedDir.folder, analyzedDir.name, 'Behavior.mat');
        if ~isfile(behaviorFile)
            warning('No Behavior file found for directory: %s', currentDir);
            continue;
        end

        behaviorData = load(behaviorFile);
        behavIntersect = behaviorData.Behavior.Intersect.TemBeh;

        % Process CSp data
        cspData = getFieldCI(behavIntersect, 'CSp');
        if isempty(cspData)
            warning('No CSp data found for directory: %s', currentDir);
            continue;
        end

        CSp_frz_all = cspData.Freezing.PerBehDuringCue;
        CSp_frz_avg = mean(cell2mat(CSp_frz_all));
        CSpSum = sum(cspData.Freezing.BehInEventVector);
        num_CSp_trials = length(CSp_frz_all);

        % Process CSm data
        csmData = getFieldCI(behavIntersect, 'CSm');
        if ~isempty(csmData)
            CSm_frz_all = csmData.Freezing.PerBehDuringCue;
            CSm_frz_avg = mean(cell2mat(CSm_frz_all));
            CSmSum = sum(csmData.Freezing.BehInEventVector);
            num_CSm_trials = length(CSm_frz_all);
            di = (CSp_frz_avg - CSm_frz_avg) / (CSp_frz_avg + CSm_frz_avg);
        else
            CSm_frz_all = {[]};
            CSm_frz_avg = NaN;
            CSmSum = 0;
            num_CSm_trials = 0;
            di = NaN;
        end

        % Compute context freezing
        totalFreezing = sum(behaviorData.Behavior.Freezing.Vector);
        context_frz = (totalFreezing - (CSpSum + CSmSum)) / length(behaviorData.Behavior.Freezing.Vector);

        % Calculate baseline freezing pretone
        baseline_frz = sum(behaviorData.Behavior.Freezing.Vector(1:baseline_frames)) / baseline_frames;

        % Create a new row
        newRow = table(exp_ID, {CSp_frz_all}, {CSm_frz_all}, CSp_frz_avg, CSm_frz_avg, ...
            di, baseline_frz, context_frz, num_CSp_trials, num_CSm_trials, ...
            'VariableNames', resultTable.Properties.VariableNames);

        % Append the new row to the result table
        resultTable = [resultTable; newRow];

    catch ME
        warning('Error processing directory %s: %s', currentDir, ME.message);
        continue;
    end
end

% Display the final table
disp(resultTable);

% Save the results
save(fullfile(baseDir, savefile), "resultTable");

%% Helper function for case-insensitive field search
function value = getFieldCI(struct, fieldName)
    fields = fieldnames(struct);
    idx = find(strcmpi(fields, fieldName));
    if ~isempty(idx)
        actualFieldName = fields{idx};
        value = struct.(actualFieldName);
    else
        value = [];
    end
end
