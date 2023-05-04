% Read the contents of the text file
filename = 'C:\Users\Zach\Box\Zach_repo\Projects\DA PMA\reward port test\PMAR_F_Cohort2_20230424\F1_PMAR_D4_reward_data_20230427_081951.txt'; % Replace with your actual text file name
fileID = fopen(filename, 'r');
fileContent = fscanf(fileID, '%c');
fclose(fileID);

% Find the required elements using regular expressions
pinNameExp = '(?<="pin_name": ")[^"]*';
stateExp = '(?<="state": )[0-9]*';
timeExp = '(?<="time": )[0-9]*';

pinNames = regexp(fileContent, pinNameExp, 'match');
states = regexp(fileContent, stateExp, 'match');
times = regexp(fileContent, timeExp, 'match');

% Convert the extracted strings to appropriate types
states = cellfun(@str2double, states);
times = cellfun(@str2double, times);

% Create the cell matrix
out = [pinNames', num2cell(states)', num2cell(times)'];

% Display the cell matrix
disp(cellMatrix);
