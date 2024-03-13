%% TO LOAD
% load cnmf_c (miniscope data) as finalC
% load cueframes struct
% load frtslu matrix for aligned.

% averages around CS+, CS-, +/- buffer frames
% min/maxs each neuron and plots it by peak firing
%%

%% step 1: align calcium to behavior
% align calcium
do_interp_calcium = true;
if do_interp_calcium
    calcium_length = length(finalC);
    vid_frames = length(frtslu);
    newX = linspace(1, calcium_length, vid_frames);
    for i = 1:size(finalC, 1)
        c_aligned(i, :) = interp1(1:calcium_length, finalC(i, :), newX, 'linear');
    end

    c_aligned = (c_aligned - min(c_aligned, [], 2)) ./ (max(c_aligned, [], 2) - min(c_aligned, [], 2));

    save('cnmf_c_aligned.mat',"c_aligned");
end

finalC = c_aligned;
%% step 2: collect data over periods of interest
% Initialize variables
[nNeurons, ~] = size(finalC); % Number of neurons
for z = 1:2
    if z == 1
        csp_frames = cueframes.csp;
    else
        csp_frames = cueframes.csm;
    end

    frameRange = csp_frames(:,2) - csp_frames(:,1); % Maximum range of csp_frames
    if sum(diff(frameRange)) > 10
        disp('misaligned frame warning!!!')
    end
    frameRange = max(frameRange);
    fraction_buffer = 0.2;
    buffer = floor(frameRange * fraction_buffer);
    totalRange = frameRange + 2 * buffer + 1; % Total range including buffers
    
    % Initialize matrix to store summed responses
    summedResponses = zeros(nNeurons, totalRange+1);

    for i = 1:size(csp_frames, 1)/4
        startFrame = csp_frames(i, 1) - buffer;
        stopFrame = csp_frames(i, 2) + buffer + 1;
        
        % Ensure the indices are within bounds
        startIdx = max(1, startFrame);
        stopIdx = min(size(finalC, 2), stopFrame);

        if stopIdx < stopFrame
            break;
        end
        
        % Extract data for current period including buffer
        periodData = finalC(:, startIdx:stopIdx);
        
        % Sum responses and update count
        summedResponses = summedResponses + periodData;
    end
    
    % Average the responses across all instances
    % Ensure no division by zero for frames not covered by any period
    averageResponses = summedResponses / size(csp_frames,1)/4;
    
    %% Initialize the matrix for normalized responses
    normalizedResponses = zeros(size(averageResponses));
    
    % Loop through each neuron to rescale its responses individually
    for i = 1:size(averageResponses, 1)
        normalizedResponses(i, :) = rescale(averageResponses(i, :), 0, 1);
    end
    
    %% interpolate to 1500 frames
    O = 1500;
    inputMatrix = normalizedResponses;
    % Get the size of the input matrix
    [M, N] = size(inputMatrix);
    
    % Predefine the output matrix for efficiency
    outputMatrix = zeros(M, O);
    
    % Define the original and new column indices
    originalCols = linspace(1, N, N);
    newCols = linspace(1, N, O);
    
    % Loop over each row to interpolate its values to the new column indices
    for i = 1:M
        outputMatrix(i, :) = interp1(originalCols, inputMatrix(i, :), newCols, 'linear');
    end
    
    normalizedResponses = outputMatrix;
    
    
    %%
    buffer_norm = floor(size(normalizedResponses,2) * fraction_buffer);
    % Find the peak activity frame for each neuron
    [~, peakFrameIndices] = max(normalizedResponses(:, buffer_norm:end-buffer_norm), [], 2);
    
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
    total_dur = size(normalizedResponses,2);
    xline(round(total_dur*fraction_buffer));
    xline(total_dur-round(total_dur*fraction_buffer));
    
    % relabel x axis
    % Assuming buffer = 300 and fps = 29.4
    tone_dur = 30;
    tone_frame = total_dur-(total_dur*fraction_buffer*2);
    fps = tone_frame/30;
    
    % Define desired times in seconds relative to the start of the csp_frame period
    desiredTimes = [-5, 0, 5, 10, 15, 20, 25, 30, 35];
    % Adjust x-axis
    frameIndices = round((desiredTimes * fps) + (total_dur*fraction_buffer) + 1); % +1 because indexing starts at 1
    xticks(frameIndices);
    xticklabels(arrayfun(@num2str, desiredTimes, 'UniformOutput', false));
    
    if z == 1
        savefig('neurons_sorted_peak_time_csp.fig');
        save('avg_csp_response2.mat','normalizedResponses','averageResponses','fraction_buffer');
    else
        savefig('neurons_sorted_peak_time_csm.fig');
        save('avg_csm_response2.mat','normalizedResponses','averageResponses','fraction_buffer');
    end
end
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

