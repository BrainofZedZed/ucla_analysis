% Root directory where the folders are located
rootDir = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\fiber photometry\GRABDA_PMAR_closedloop\cohort2\batch'; % Replace with your root directory path

% Initialize variable to store concatenated data
concatenatedData = [];

% Get a list of all subdirectories in the root directory
subDirs = dir(rootDir);
subDirs = subDirs([subDirs.isdir]); % Filter only directories
subDirs = subDirs(~ismember({subDirs.name}, {'.', '..'})); % Exclude '.' and '..'

% Iterate through each subdirectory
for i = 1:length(subDirs)
    % Change to the subdirectory
    cd(fullfile(rootDir, subDirs(i).name));
    
   % GOAL:  look at signal centered on periods when exiting the reward area
% and proceeding to platform area

% TO RUN: load Behavior, bhsig

% Adjustable variables
t = 2;
timeBeforeRewardExit = t; % Time in seconds before the reward exit
timeAfterRewardExit = t; % Time in seconds after the reward exit
timeBeforePlatformEntry = t; % Time in seconds before the platform entry
timeAfterPlatformEntry = t; % Time in seconds after the platform entry
timeToPlatform = 5; % Maximum time in seconds to consider between reward exit and platform entry
fps = 50; % Frame rate

% Assuming Behavior.Spatial.reward.inROIvector and Behavior.Spatial.platform.inROIvector are defined along with bhsig

%%auto load things
% Step 1: Search for a file with 'CSp_fibpho_analysis' in its title
files = dir('*CSp_fibpho_analysis*.mat');  % Assuming it's a .mat file
if isempty(files)
    error('No file with ''CSp_fibpho_analysis'' in its title found.');
else
    filename = files(1).name;  % Assuming you want the first file if there are multiple matches
end

% Step 2: Load the variable 'bhsig' from the found file
loadedData = load(filename, 'bhsig');
if isfield(loadedData, 'bhsig')
    bhsig = loadedData.bhsig;
else
    error('Variable ''bhsig'' not found in the file %s.', filename);
end

% Step 3: Search for a directory with '_analyzed' in its name
dirs = dir('*_analyzed');
if isempty(dirs)
    error('No directory with ''_analyzed'' in its name found.');
else
    analyzedDir = dirs(1).name;  % Assuming you want the first directory if there are multiple matches
end

% Step 4: Navigate to that directory and load the file 'Behavior.mat'
behaviorFilePath = fullfile(analyzedDir, 'Behavior.mat');
if exist(behaviorFilePath, 'file')
    load(behaviorFilePath);  % Assuming the file contains variables to be loaded directly into the workspace
else
    error('File ''Behavior.mat'' not found in the directory %s.', analyzedDir);
end

% Step 5: Load exp_ID
exp_file = dir('*-*-*_*-*-*.mat');
load(exp_file.name,'exp_ID'); % load experiment file

%%

% Find exits from reward and entries to platform
exitsFromReward = find(diff(Behavior.Spatial.reward.inROIvector) == -1);
entriesToPlatform = find(diff(Behavior.Spatial.platform.inROIvector) == 1);

% exclude shock periods 
flag = [];
for i = 1:length(exitsFromReward)
    if Behavior.Temporal.US.Vector(exitsFromReward(i))
        flag = [flag;i];
    end
end

exitsFromReward(flag) = [];

% Identify valid periods where reward exit is followed by platform entry
validPeriods = [];
for exitIdx = 1:length(exitsFromReward)
    exitIndex = exitsFromReward(exitIdx);
    for entryIdx = 1:length(entriesToPlatform)
        entryIndex = entriesToPlatform(entryIdx);
        if entryIndex > exitIndex && (entryIndex - exitIndex) <= timeToPlatform * fps
            validPeriods = [validPeriods; exitIndex, entryIndex];
            break; % Exit the loop after finding the first valid entry
        end
    end
end

if ~isempty(validPeriods)
    
    % Normalize and extract signal segments for reward exit
    rewardExitSignals = cell(size(validPeriods, 1), 1);
    for i = 1:size(validPeriods, 1)
        index = validPeriods(i, 1);
        startIndex = max(1, index - timeBeforeRewardExit * fps);
        endIndex = min(length(bhsig), index + timeAfterRewardExit * fps);
        signal = bhsig(startIndex:endIndex);
        rewardExitSignals{i} = signal - signal(1); % Normalizing
    end
    
    % Normalize and extract signal segments for platform entry
    platformEntrySignals = cell(size(validPeriods, 1), 1);
    for i = 1:size(validPeriods, 1)
        index = validPeriods(i, 2);
        startIndex = max(1, index - timeBeforePlatformEntry * fps);
        endIndex = min(length(bhsig), index + timeAfterPlatformEntry * fps);
        signal = bhsig(startIndex:endIndex);
        platformEntrySignals{i} = signal - signal(1); % Normalizing
    end
    
    % Plotting function logic for reward exit signals
    figure;
    hold on;
    colors = parula(length(rewardExitSignals));
    maxSignalLength = max(cellfun(@length, rewardExitSignals));
    allSignals = NaN(length(rewardExitSignals), maxSignalLength);
    for i = 1:length(rewardExitSignals)
        signalLength = length(rewardExitSignals{i});
        timeVector = linspace(-timeBeforeRewardExit, timeAfterRewardExit, signalLength);
        plot(timeVector, rewardExitSignals{i}, 'LineWidth', 1.5, 'Color', [colors(i, :) 0.5]);
        allSignals(i, 1:signalLength) = rewardExitSignals{i};
    end
    averageSignal = nanmean(allSignals, 1);
    plot(linspace(-timeBeforeRewardExit, timeAfterRewardExit, maxSignalLength), averageSignal, 'LineWidth', 2, 'Color', 'blue');
    xline(0, '--', 'LineWidth', 2, 'Color', 'black');
    xlabel('Time (seconds)');
    ylabel('Normalized Neural Signal');
    title('Normalized Neural Signals Around Valid Reward Exits');
    axis tight;
    hold off;
    savefig('reward_exit_to_pf_sig.fig');
    close;
    
    % Plotting function logic for platform entry signals
    figure;
    hold on;
    colors = parula(length(platformEntrySignals));
    maxSignalLength = max(cellfun(@length, platformEntrySignals));
    allSignals = NaN(length(platformEntrySignals), maxSignalLength);
    for i = 1:length(platformEntrySignals)
        signalLength = length(platformEntrySignals{i});
        timeVector = linspace(-timeBeforePlatformEntry, timeAfterPlatformEntry, signalLength);
        plot(timeVector, platformEntrySignals{i}, 'LineWidth', 1.5, 'Color', [colors(i, :) 0.5]);
        allSignals(i, 1:signalLength) = platformEntrySignals{i};
    end
    averageSignal = nanmean(allSignals, 1);
    plot(linspace(-timeBeforePlatformEntry, timeAfterPlatformEntry, maxSignalLength), averageSignal, 'LineWidth', 2, 'Color', 'blue');
    xline(0, '--', 'LineWidth', 2, 'Color', 'black');
    xlabel('Time (seconds)');
    ylabel('Normalized Neural Signal');
    title('Normalized Neural Signals Around Valid Platform Entries');
    axis tight;
    hold off;
    savefig('platform_entry_after_reward_exit.fig');
    close;
    
    platformEntrySignals = cell2mat(platformEntrySignals);
    rewardExitSignals = cell2mat(rewardExitSignals);
    
    for i = 1:size(rewardExitSignals,1)
        avg_pre_exit(i) = mean(rewardExitSignals(i,round(end/2)-fps:round(end/2)));
        avg_post_exit(i) = mean(rewardExitSignals(i,round(end/2):round(end/2)+fps));
    end
    
    z = string(exp_ID);
    zz = repmat(z,[size(avg_pre_exit,2),1]);
    
    pre_post_exit_sig = [zz, avg_pre_exit', avg_post_exit'];
    save('reward_exit_workspace_5s.mat')
    
        
        % Load 'reward_exit_workspace.mat' which contains 'pre_post_exit_sig'
        tempData = load('reward_exit_workspace_5s.mat', 'pre_post_exit_sig');
        
        % Concatenate the data
        concatenatedData = [concatenatedData; tempData.pre_post_exit_sig];
        
        % Return to the root directory (optional, depending on your folder structure)
        cd(rootDir);
end
end

% Save the concatenated data as 'batch_pre_post_reward.mat'
save(fullfile(rootDir, 'batch_pre_post_reward_5s.mat'), 'concatenatedData');
