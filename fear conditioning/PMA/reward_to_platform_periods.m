% Adjustable variables
t = 2;
timeBeforeRewardExit = t; % Time in seconds before the reward exit
timeAfterRewardExit = t; % Time in seconds after the reward exit
timeBeforePlatformEntry = t; % Time in seconds before the platform entry
timeAfterPlatformEntry = t; % Time in seconds after the platform entry
timeToPlatform = 10; % Maximum time in seconds to consider between reward exit and platform entry
fps = 50; % Frame rate

% Assuming Behavior.Spatial.reward.inROIvector and Behavior.Spatial.platform.inROIvector are defined along with bhsig

% Find exits from reward and entries to platform
exitsFromReward = find(diff(Behavior.Spatial.reward.inROIvector) == -1);
entriesToPlatform = find(diff(Behavior.Spatial.platform.inROIvector) == 1);

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

% Extract and normalize signals for valid reward exits and platform entries
rewardExitSignals = extractSignals(validPeriods(:, 1), bhsig, timeBeforeRewardExit, timeAfterRewardExit, fps);
platformEntrySignals = extractSignals(validPeriods(:, 2), bhsig, timeBeforePlatformEntry, timeAfterPlatformEntry, fps);

% Plot normalized signals for reward exit periods
plotSignals(rewardExitSignals, 'Normalized Neural Signals Around Valid Reward Exits', timeBeforeRewardExit, timeAfterRewardExit, fps);
%saveplot('reward_to_pf_exit_signal.fig');
%close;
% Plot normalized signals for platform entry periods
plotSignals(platformEntrySignals, 'Normalized Neural Signals Around Valid Platform Entries', timeBeforePlatformEntry, timeAfterPlatformEntry, fps);
%saveplot('pf_entry_after_reward_signal.fig');
%close;

% Function to plot signals
function plotSignals(signalCell, titleStr, timeBefore, timeAfter, fps)
    figure;
    hold on;
    colors = parula(length(signalCell));
    maxSignalLength = max(cellfun(@length, signalCell));
    allSignals = NaN(length(signalCell), maxSignalLength);
    for i = 1:length(signalCell)
        signalLength = length(signalCell{i});
        timeVector = linspace(-timeBefore, timeAfter, signalLength);
        plot(timeVector, signalCell{i}, 'LineWidth', 1.5, 'Color', [colors(i, :) 0.5]);
        allSignals(i, 1:signalLength) = signalCell{i};
    end
    averageSignal = nanmean(allSignals, 1);
    plot(linspace(-timeBefore, timeAfter, maxSignalLength), averageSignal, 'LineWidth', 2, 'Color', 'blue');
    xline(0, '--', 'LineWidth', 2, 'Color', 'black');
    xlabel('Time (seconds)');
    ylabel('Normalized Neural Signal');
    title(titleStr);
    axis tight;
    hold off;
end

% Function to normalize and extract signal segments
function signals = extractSignals(indices, bhsig, timeBefore, timeAfter, fps)
    signals = cell(size(indices, 1), 1);
    for i = 1:size(indices, 1)
        index = indices(i);
        startIndex = max(1, index - timeBefore * fps);
        endIndex = min(length(bhsig), index + timeAfter * fps);
        signal = bhsig(startIndex:endIndex);
        signals{i} = signal - signal(1); % Normalizing
    end
end
