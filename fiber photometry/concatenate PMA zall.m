% Find the file ending with 'CSp_fibpho_analysis.mat' in the current directory
filePattern = fullfile(pwd, '*CSp_fibpho_analysis.mat');
files = dir(filePattern);

if isempty(files)
    error('No file ending with ''CSp_fibpho_analysis.mat'' found in the current directory.');
end

% Load the variables on_platform_shock and zall from the file
load(files(1).name, 'zall');

% Check if the variables exist in the loaded file
if  ~exist('zall', 'var')
    error('Variables on_platform_shock or zall not found in the file.');
end

% Get a list of all files in the current directory
files = dir();

% Define the regular expression pattern for the digit pattern
pattern = '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.mat';

% Initialize a cell array to store matching filenames
matchingFiles = {};

% Loop through each file in the directory
for i = 1:length(files)
    % Get the current filename
    filename = files(i).name;
    
    % Use regular expression to check if the filename matches the pattern
    if ~isempty(regexp(filename, pattern, 'once'))
        % If it matches, add it to the matchingFiles cell array
        matchingFiles{end+1} = filename;
    end
end

% Display the matching filenames
if ~isempty(matchingFiles)
    disp('Matching filenames:');
    disp(matchingFiles);
    
    % Load the first matching file
    firstMatchingFile = matchingFiles{1};
    disp(['Loading file: ', firstMatchingFile]);
    
    % Load the variable 'on_platform_shock' from the file
    data = load(firstMatchingFile, 'on_platform_shock');
    
    % Check if the variable exists in the file
    if isfield(data, 'on_platform_shock')
        on_platform_shock = data.on_platform_shock;
        disp('Variable "on_platform_shock" loaded successfully.');
        % Display the variable content if needed
        disp(on_platform_shock);
    else
        disp('Variable "on_platform_shock" not found in the file.');
    end
else
    disp('No matching filenames found');
end

% Group rows of zall based on the binary indicators in on_platform_shock
shock_trials = zall(on_platform_shock == 0, :);
avoid_trials = zall(on_platform_shock == 1, :);

%
all_trials = [all_trials; zall];
all_shock_trials = [all_shock_trials; shock_trials];
all_avoid_trials = [all_avoid_trials; avoid_trials];

% Save the variables into a new file called 'trials_for_TG.mat'
save('trials_for_TG.mat', 'zall', 'shock_trials', 'avoid_trials');

disp('Variables zall, shock_trials, and avoid_trials have been saved to trials_for_TG.mat');
