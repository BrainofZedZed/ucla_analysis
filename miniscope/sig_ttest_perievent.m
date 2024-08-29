z = findStartStop(tone_freeze_vec);
z=z(:,1);

num_neurons = size(sig, 1);  % Number of neurons
num_indices = length(z);  % Number of indices (freeze onset marks)
pre_start = 90;  % Start frame for pre-activity window
pre_end = 0;    % End frame for pre-activity window
post_start = 0;  % Start frame for post-activity window
post_end = 90;   % End frame for post-activity window

% Initialize array to store p-values, significance, and direction of change
p_values = zeros(num_neurons, 1);
is_significant = false(num_neurons, 1); % Logical array to indicate significance
direction = zeros(num_neurons, 1); % +1 for increase, -1 for decrease

% Loop through each neuron
for neuron = 1:num_neurons
    pre_activity = zeros(num_indices, 1);
    post_activity = zeros(num_indices, 1);
    
    % Loop through each index
    for i = 1:num_indices
        idx = z(i);
        
        % Ensure the index doesn't go out of bounds
        if idx - pre_start > 0 && idx + post_end <= size(sig, 2)
            % Extract pre and post activity
            pre_activity(i) = mean(sig(neuron, idx-pre_start:idx-pre_end));
            post_activity(i) = mean(sig(neuron, idx+post_start:idx+post_end));
        else
            pre_activity(i) = NaN; % Set as NaN if out of bounds
            post_activity(i) = NaN;
        end
    end
    
    % Remove NaNs
    valid_indices = ~isnan(pre_activity) & ~isnan(post_activity);
    pre_activity = pre_activity(valid_indices);
    post_activity = post_activity(valid_indices);
    
    % Perform paired t-test
    [~, p_values(neuron)] = ttest(post_activity, pre_activity);
    
    % Check if p-value is significant
    if p_values(neuron) < 0.05
        is_significant(neuron) = true;
        
        % Determine the direction of change
        if mean(post_activity) > mean(pre_activity)
            direction(neuron) = 1;  % Increase
        elseif mean(post_activity) < mean(pre_activity)
            direction(neuron) = -1; % Decrease
        end
    end
end

% Output significant neurons with direction of change
significant_neurons = find(is_significant);
disp('Significant neurons and their direction of change:');
for i = 1:length(significant_neurons)
    neuron = significant_neurons(i);
    if direction(neuron) == 1
        disp(['Neuron ', num2str(neuron), ': Increase']);
    elseif direction(neuron) == -1
        disp(['Neuron ', num2str(neuron), ': Decrease']);
    end
end