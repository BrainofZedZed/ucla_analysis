% Define the grandparent directory and output directory
grandparent_dir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL\CSminus removed\normal gcamp\ZZ208';
output_dir = grandparent_dir;

% Get list of subject directories
subjects = dir(fullfile(grandparent_dir, 'ZZ*'));
subjects = {subjects.name};

% Define trials
trials = {'hab', 'D0', 'D1', 'D28'};

% Initialize data structure
data = struct();

% Process data for each subject
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('Processing subject: %s\n', subject);
    
    for j = 1:length(trials)
        trial = trials{j};
        file_path = fullfile(grandparent_dir, subject, [subject '_' trial], 'ca_roc_output.mat');
        
        if ~exist(file_path, 'file')
            fprintf('File not found: %s\n', file_path);
            continue;
        end
        
        % Load data
        load(file_path, 'sig', 'out');
        
        % Calculate total number of neurons
        total_neurons = size(sig, 1);
        
        % Get field names of 'out' struct
        features = fieldnames(out);
        
        fprintf('Subject %s, Trial %s: %d features\n', subject, trial, length(features));
        
        % Process each feature
        for k = 1:length(features)
            feature = features{k};
            n_excited_count = length(out.(feature).n_excited);
            n_suppressed_count = length(out.(feature).n_suppressed);
            n_combined_count = n_excited_count + n_suppressed_count;
            
            % Store data
            data(i).subject = subject;
            data(i).([trial '_' feature '_n_excited']) = n_excited_count / total_neurons;
            data(i).([trial '_' feature '_n_suppressed']) = n_suppressed_count / total_neurons;
            data(i).([trial '_' feature '_n_combined']) = n_combined_count / total_neurons;
        end
    end
end

% Convert struct to table
T = struct2table(data);

% Separate tables for excited, suppressed, and combined
excited_cols = [{'subject'} T.Properties.VariableNames(contains(T.Properties.VariableNames, 'n_excited'))];
suppressed_cols = [{'subject'} T.Properties.VariableNames(contains(T.Properties.VariableNames, 'n_suppressed'))];
combined_cols = [{'subject'} T.Properties.VariableNames(contains(T.Properties.VariableNames, 'n_combined'))];

T_excited = T(:, excited_cols);
T_suppressed = T(:, suppressed_cols);
T_combined = T(:, combined_cols);

% Save tables
writetable(T_excited, fullfile(output_dir, 'n_excited_table.csv'));
writetable(T_suppressed, fullfile(output_dir, 'n_suppressed_table.csv'));
writetable(T_combined, fullfile(output_dir, 'n_combined_table.csv'));

%% reformat csv
reformatCSV(fullfile(output_dir, 'n_excited_table.csv'));
reformatCSV(fullfile(output_dir, 'n_suppressed_table.csv'));
reformatCSV(fullfile(output_dir, 'n_combined_table.csv'));

fprintf('Data processing complete. Output files saved in %s\n', output_dir);
cd(grandparent_dir);

%% fxn
function reformatCSV(data_table)
% Load the CSV file
data = readtable(data_table);

% Get the column names
colNames = data.Properties.VariableNames;

% Rename columns for CSp_onset and CSp_offset by removing underscore and capitalizing O
for k = 1:length(colNames)
    % Replace '_onset' with 'Onset'
    if contains(colNames{k}, '_CSp_onset')
        colNames{k} = strrep(colNames{k}, '_CSp_onset', '_CSpOnset');
    end
    % Replace '_offset' with 'Offset'
    if contains(colNames{k}, '_CSp_offset')
        colNames{k} = strrep(colNames{k}, '_CSp_offset', '_CSpOffset');
    end
end

% Update table with new column names
data.Properties.VariableNames = colNames;

% Extract unique features and trials (after renaming)
features = {'freeze', 'nontone_freeze', 'CSp', 'CSpOnset', 'CSpOffset', ...
            'shock', 'post_shock'};
trials = {'hab', 'D0', 'D1', 'D28'};

% Initialize a new table to hold the reorganized data
reorganizedData = table();

% Add the subject column to the reorganized table
reorganizedData = [data(:, 'subject')];

% Iterate over each feature to organize columns by trial
for i = 1:length(features)
    feature = features{i};
    featureData = table(); % Separate table for current feature
    for j = 1:length(trials)
        trial = trials{j};
        
        % Create a pattern to match columns with the exact feature name
        pattern = ['^' trial '_' feature '_'];
        
        % Use regex to find columns matching the current trial and feature
        matchingCols = colNames(~cellfun('isempty', regexp(colNames, pattern)));

        % Append matching columns to the feature-specific table
        featureData = [featureData, data(:, matchingCols)];
    end
    % Append the feature-specific table to the reorganized data
    reorganizedData = [reorganizedData, featureData];
end

% Save the reorganized table to a new CSV file
writetable(reorganizedData, data_table);
end


