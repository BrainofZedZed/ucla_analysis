% Specify the main directory path
mainDirectory = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\fiber photometry\GRABDA FC\cohort2\batch'; % Change this to your directory path

% Define the list of variables to load
additionalVariables = {'tone_onset_pk_norm', 'tone_onset_mean_norm', 'tone_onset_mean' 'mean_end_response_norm'}; % Add your variable names here
    
% Initialize concatenatedData as an empty struct
concatenatedData = struct();
concatenatedData.tone_onset_pk_norm = {};
concatenatedData.tone_onset_latency = {};

% Initialize each field in concatenatedData for other additional variables
for v = 1:numel(additionalVariables)
    if ~strcmp(additionalVariables{v}, 'tone_onset_pk_norm')
        concatenatedData.(additionalVariables{v}) = {};
    end
end

% Get a list of all subfolders
folders = dir(mainDirectory);
folders = folders([folders.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'

% Loop through each folder
for i = 1:length(folders)
    folderPath = fullfile(mainDirectory, folders(i).name);

    % Load the exp_ID from the file named with a timestamp format
    expIDFiles = dir(fullfile(folderPath, '*_*_*.mat'));
    if ~isempty(expIDFiles)
        expIDFile = fullfile(folderPath, expIDFiles(1).name);
        exp_ID_data = load(expIDFile, 'exp_ID');
        if isfield(exp_ID_data, 'exp_ID')
            exp_ID = exp_ID_data.exp_ID;

            % Load the other variables from the file containing 'shock_tone'
            shockToneFiles = dir(fullfile(folderPath, '*shock_tone*.mat'));
            if ~isempty(shockToneFiles)
                shockToneFile = fullfile(folderPath, shockToneFiles(1).name);
                shockToneData = load(shockToneFile, additionalVariables{:});

                % Process each additional variable
                for v = 1:numel(additionalVariables)
                    varName = additionalVariables{v};
                    if isfield(shockToneData, varName)
                        if strcmp(varName, 'tone_onset_pk_norm')
                            % Special handling for tone_onset_pk_norm
                            tone_onset_pk_norm = shockToneData.(varName);

                            % Splitting the data into two parts
                            tone_onset_pk_norm_data = tone_onset_pk_norm(:, 1);
                            tone_onset_latency_data = tone_onset_pk_norm(:, 2);

                            % Combine exp_ID with each part and concatenate
                            combinedDataNorm = cell(size(tone_onset_pk_norm_data, 1), 2);
                            combinedDataNorm(:, 1) = {exp_ID};
                            combinedDataNorm(:, 2) = num2cell(tone_onset_pk_norm_data);
                            concatenatedData.tone_onset_pk_norm = [concatenatedData.tone_onset_pk_norm; combinedDataNorm];

                            combinedDataLatency = cell(size(tone_onset_latency_data, 1), 2);
                            combinedDataLatency(:, 1) = {exp_ID};
                            combinedDataLatency(:, 2) = num2cell(tone_onset_latency_data);
                            concatenatedData.tone_onset_latency = [concatenatedData.tone_onset_latency; combinedDataLatency];
                        else
                            % Normal handling for other variables
                            combinedData = cell(size(shockToneData.(varName), 1), 2);
                            combinedData(:, 1) = {exp_ID};
                            combinedData(:, 2) = num2cell(shockToneData.(varName));

                            % Concatenate with the existing data in the struct
                            concatenatedData.(varName) = [concatenatedData.(varName); combinedData];
                        end
                    end
                end
            end
        end
    end
end

% Display the final concatenated data
disp(concatenatedData);
