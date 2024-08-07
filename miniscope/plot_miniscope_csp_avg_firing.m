%% TO LOAD
% load cnmf_c (miniscope data) as A
% load cueframes struct
% averages around CS+, +/- buffer frames
% min/maxs each neuron, plots it by tone onset modulation and also sorted
% by peak firing time
%%

csp = false;

% Initialize variables
[nNeurons, ~] = size(A); % Number of neurons

if csp
    csp_frames = cueframes.csp;
else
    csp_frames = cueframes.csm;
end

buffer = 300; % Buffer size
frameRange = csp_frames(:,2) - csp_frames(:,1); % Maximum range of csp_frames
if 
totalRange = frameRange + 2 * buffer; % Total range including buffers

% Initialize matrix to store summed responses
summedResponses = zeros(nNeurons, totalRange);
countPerFrame = zeros(1, totalRange); % Keep track of how many times each frame is considered

for i = 1:size(csp_frames, 1)
    startFrame = csp_frames(i, 1) - buffer;
    stopFrame = csp_frames(i, 2) + buffer;
    
    % Ensure the indices are within bounds
    startIdx = max(1, startFrame);
    stopIdx = min(size(A, 2), stopFrame);
    actualBufferStart = max(0, buffer - (csp_frames(i, 1) - startIdx));
    actualBufferEnd = buffer + (stopIdx - csp_frames(i, 2));
    
    % Extract data for current period including buffer
    periodData = A(:, startIdx:stopIdx);
    
    % Sum responses and update count
    summedResponses(:, actualBufferStart + 1:actualBufferStart + size(periodData, 2)) = ...
        summedResponses(:, actualBufferStart + 1:actualBufferStart + size(periodData, 2)) + periodData;
    countPerFrame(actualBufferStart + 1:actualBufferStart + size(periodData, 2)) = ...
        countPerFrame(actualBufferStart + 1:actualBufferStart + size(periodData, 2)) + 1;
end

% Average the responses across all instances
% Ensure no division by zero for frames not covered by any period
countPerFrame(countPerFrame == 0) = 1; 
averageResponses = summedResponses ./ repmat(countPerFrame, nNeurons, 1);

%% Initialize the matrix for normalized responses
normalizedResponses = zeros(size(averageResponses));

% Loop through each neuron to rescale its responses individually
for i = 1:size(averageResponses, 1)
    normalizedResponses(i, :) = rescale(averageResponses(i, :), 0, 1);
end



%%
% Find the peak activity frame for each neuron
[~, peakFrameIndices] = max(normalizedResponses(:, buffer:end-buffer), [], 2);

% Sort neurons based on when their peak activity occurs
[~, sortedIndices] = sort(peakFrameIndices);
sortedIndices = flip(sortedIndices);
% Reorder the rows of averageResponses based on the timing of peak activity
sortedAverageResponses = normalizedResponses(sortedIndices, :);

% You can now visualize this sorted matrix using a heatmap
figure; % Open a new figure window
imagesc(sortedAverageResponses); % Plot the sorted averageResponses as a heatmap
colorbar; % Show a colorbar
xlabel('Time since tone onset (s)');
ylabel('Neuron (sorted by peak activity frame)');
title('Neurons Sorted by Timing of Peak Activity');
ax = gca; 
ax.YDir = 'normal'; % Ensure y-axis starts from the bottom
xline(300);
xline(size(normalizedResponses,2)-300);

% relabel x axis
% Assuming buffer = 300 and fps = 29.4
fps = 30;

% Define desired times in seconds relative to the start of the csp_frame period
desiredTimes = [-5, 5, 15, 25, 35];
% Adjust x-axis
frameIndices = round((desiredTimes * fps) + buffer + 1); % +1 because indexing starts at 1
xticks(frameIndices);
xticklabels(arrayfun(@num2str, desiredTimes, 'UniformOutput', false));

savefig('neurons_sorted_peak_time3.fig');
%% unused -- sorting by tone modulation

%% sort by change at tone
% % Calculate mean response during the 250-frame buffer period before csp_frame time
% meanBefore = mean(averageResponses(:, 1:buffer), 2);
% 
% % Assuming the length of the csp_frame period is stored in frameRange
% % Calculate mean response during the csp_frame time
% % Adjust indices for the 250-frame buffer
% meanDuring = mean(averageResponses(:, buffer+1:buffer+frameRange), 2);
% 
% % Calculate the change in activity for each neuron
% changeInActivity = meanDuring - meanBefore;
% 
% % Sort neurons based on the change in activity, descending
% [~, sortedIndices] = sort(changeInActivity, 'descend');  % 'descend' for descending order
% 
% % Reorder the rows of averageResponses based on the sorting
% sortedAverageResponses = averageResponses(sortedIndices, :);
% 
% % Visualizing the sorted average responses
% figure; % Open a new figure window
% imagesc(sortedAverageResponses); % Plot the sorted averageResponses as a heatmap
% colorbar; % Show a colorbar
% xlabel('Frame relative to csp_frames periods (+/- buffer)');
% ylabel('Neuron (sorted by change in activity)');
% title('Neurons Sorted by Change in Activity (Buffer = 250)');
% colormap(jet); % Using jet colormap for visualization
% ax = gca; 
% ax.YDir = 'normal'; % Ensure y-axis starts from the bottom
% 
% 
% % Initialize the matrix for normalized responses
% normalizedResponses = zeros(size(sortedAverageResponses));
% 
% % Loop through each neuron to rescale its responses individually
% for i = 1:size(sortedAverageResponses, 1)
%     normalizedResponses(i, :) = rescale(sortedAverageResponses(i, :), 0, 1);
% end
% 
% normalizedResponses = sortedAverageResponses;
% % Visualizing the sorted average responses
% figure; % Open a new figure window
% imagesc(normalizedResponses); % Plot the sorted averageResponses as a heatmap
% colorbar; % Show a colorbar
% xlabel('Frame relative to csp_frames periods (+/- buffer)');
% ylabel('Neuron (sorted by change in activity)');
% title('Neurons Sorted by Change in Activity (Buffer = 250)');
% %colormap(jet); % Using jet colormap for visualization
% 
% % Assuming buffer = 300 and fps = 29.4
% fps = 29.4;
% 
% % Define desired times in seconds relative to the start of the csp_frame period
% desiredTimes = [-5, 5, 15, 25, 35];
% % Adjust x-axis
% frameIndices = round((desiredTimes * fps) + buffer + 1); % +1 because indexing starts at 1
% xticks(frameIndices);
% xticklabels(arrayfun(@num2str, desiredTimes, 'UniformOutput', false));
% 
% % Label axes
% xlabel('Time since start of csp_frame period (seconds)');
% ylabel('Neuron (sorted by time of tone onset modulation)');
% title('Neurons Sorted by Time of Tone Onset Modulation');
% 
% % Ensure the y-axis starts from the bottom
% ax = gca;
% ax.YDir = 'normal';
% 
% xline(buffer);
% xline(totalRange-buffer);
% savefig('neurons sorted by tone onset.fig');

