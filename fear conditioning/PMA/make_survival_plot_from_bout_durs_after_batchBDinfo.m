bout_dur = {1};
for i = 2:size(platform_data,1)
    nbouts = size(platform_data{i,4},1);
    nmin = size(platform_data{i,2},2)/3000;
    bouts_per_min(i-1) = nbouts/nmin;
    bout_dur{i-1} = diff(platform_data{i,4},[],2);
end

bouts_per_min = bouts_per_min';

for i = 1:length(bout_dur)

    values = bout_dur{i};
    values = values/50;
    % Sort the values in ascending order
    sortedValues = sort(values);
    
    % Calculate the total number of values
    numValues = numel(sortedValues);
    
    % Generate the x-axis values
    x = 1:numValues;
    
    % Calculate the proportion of values less than or equal to each value
    y = x ./ numValues;
    
    % Create the plot
    plot(sortedValues, y, '');
    hold on;
    
    % Set the axis labels
    xlabel('Platform Stay (s)');
    ylabel('Proportion of bouts');
    
    % Display the grid
    grid on;
end