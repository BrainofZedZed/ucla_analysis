% Extract the data from the structure
data = out.avoids;

% Number of subjects (rows)
numSubjects = size(data, 1);

% Assuming the first column is IDs and the rest are data
% Extract IDs (assuming they are in the first column and are non-numeric)
IDs = data(:, 1);

% Convert the rest of the data to a numeric matrix
% The cell2mat function is used for conversion; it assumes that all cells contain numeric data
numericData = cell2mat(data(:, 2:end));

% Number of data columns
numDataCols = size(numericData, 2);

% Initialize a matrix to store the averages
% First column is for ID, others are for averaged data
averagedData = zeros(numSubjects, 1 + ceil(numDataCols / 3));

% Copy the ID column separately (as it is non-numeric)
averagedIDs = IDs;

% Process each group of three columns
for i = 1:3:numDataCols
    % Calculate the last column of the current group
    lastCol = min(i + 2, numDataCols);
    
    % Average the columns in the group
    % The result is placed in the corresponding column of averagedData
    averagedData(:, 1 + ceil(i / 3)) = mean(numericData(:, i:lastCol), 2);
end

% Combine IDs with the averaged data
% Note: If IDs are not numeric, they cannot be directly combined in a matrix
% You may need to store them in a cell array or handle them separately
finalResult = [averagedIDs, num2cell(averagedData)];
