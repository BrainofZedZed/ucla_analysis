function zscored_data = zscore_matrix(data, baseline_period)
    % Function to z-score an NxM matrix based on a specified baseline period
    % 
    % Parameters:
    % data: NxM matrix where N is the number of rows and M is the number of columns
    % baseline_period: 1x2 vector specifying the start and end indices of
    % the baseline period, then zeros to the baseline period
    %
    % Returns:
    % zscored_data: NxM z-scored matrix

    % Check if the baseline_period is valid
    if length(baseline_period) ~= 2 || baseline_period(1) < 1 || baseline_period(2) > size(data, 2) || baseline_period(1) >= baseline_period(2)
        error('Invalid baseline period.');
    end

    % Extract the baseline data
    baseline_data = data(:, baseline_period(1):baseline_period(2));

    % Calculate the mean and standard deviation for each row based on the baseline period
    baseline_mean = mean(baseline_data, 2);
    baseline_std = std(baseline_data, 0, 2);

    % Initialize the z-scored data matrix
    zscored_data = zeros(size(data));

    % Z-score each row of the data matrix and zero baseline
    for i = 1:size(data, 1)
        zscored_data(i, :) = (data(i, :) - baseline_mean(i)) / baseline_std(i);
        zscored_data(i,:) = zscored_data(i,:) - mean(zscored_data(i,baseline_period(1):baseline_period(2)));
    end
 
end
