function zscoredMatrix = zscoreMatrix(inputMatrix, baselineIndices, varargin)
    % This function zscores each row of the inputMatrix based on the baseline period specified by baselineIndices.
    % Optionally, it can first smooth the data in each row using a moving average filter if specified.
    %
    % Inputs:
    %   inputMatrix - A numeric matrix where rows are different observations (e.g., trials, samples) and columns are data points.
    %   baselineIndices - A vector of column indices that define the baseline period.
    %   varargin - Variable input arguments:
    %       'smooth' - A logical flag to indicate whether smoothing should be applied.
    %       'width' - An integer specifying the width of the moving average window if smoothing is applied.
    %
    % Outputs:
    %   zscoredMatrix - A matrix of the same size as inputMatrix containing the z-scored values.

    % Parse variable inputs
    smoothFlag = false;
    smoothWidth = 1; % Default width is 1, which means no smoothing effectively
    
    % Check optional arguments
    if ~isempty(varargin)
        for i = 1:length(varargin)
            if strcmpi(varargin{i}, 'smooth') && i < length(varargin)
                smoothFlag = varargin{i+1};
            elseif strcmpi(varargin{i}, 'width') && i < length(varargin)
                smoothWidth = varargin{i+1};
            end
        end
    end
    
    % Number of rows in the input matrix
    numRows = size(inputMatrix, 1);
    
    % Initialize the output z-scored matrix
    zscoredMatrix = zeros(size(inputMatrix));
    
    % Loop over each row
    for i = 1:numRows
        currentRow = inputMatrix(i, :);
        
        % Extract the baseline values from the current (possibly smoothed) row
        baselineValues = currentRow(baselineIndices);
        
        % Calculate the mean and standard deviation of the baseline values
        baselineMean = mean(baselineValues);
        baselineStd = std(baselineValues);
        
        % Check if standard deviation is zero
        if baselineStd == 0
            warning('Standard deviation of baseline is zero for row %d. Z-scores will be set to NaN for this row.', i);
            zscoredMatrix(i, :) = NaN; % Set all values in this row to NaN because we cannot divide by zero
        else
            % Z-score the entire row
            zscoredMatrix(i, :) = (currentRow - baselineMean) / baselineStd;

             % Apply smoothing if flag is true
            if smoothFlag
                zscoredMatrix(i, :) = smoothdata( zscoredMatrix(i, :), 'movmean', smoothWidth);
            end
            zscoredMatrix(i, :) = zscoredMatrix(i,:) - mean(zscoredMatrix(baselineIndices));
        end
    end
end
