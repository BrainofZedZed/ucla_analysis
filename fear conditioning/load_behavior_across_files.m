% Specify the main directory path
mainDirectory = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\PMAR_JAWS\controls\orig vids\batch'; % Change this to your directory path

% Initialize concatenatedData as an empty struct
concatenatedData = struct();
concatenatedData.platform_tone_vector = {};
concatenatedData.proportion_in_platform = {};

% Get a list of all subfolders
folders = dir(mainDirectory);
folders = folders([folders.isdir]); % Keep only directories
folders = folders(~ismember({folders.name}, {'.', '..'})); % Remove '.' and '..'

% Loop through each folder
for i = 1:length(folders)
    folderPath = fullfile(mainDirectory, folders(i).name);

    % Load the exp_ID from the file named with a timestamp format
    expIDFiles = dir(fullfile(folderPath, '*_*_*.mat'));
    exp_ID = '';
    if ~isempty(expIDFiles)
        expIDFile = fullfile(folderPath, expIDFiles(1).name);
        exp_ID_data = load(expIDFile, 'exp_ID');
        if isfield(exp_ID_data, 'exp_ID')
            exp_ID = exp_ID_data.exp_ID;
        end
    end

    % Search for subfolders containing '_analyzed'
    subfolders = dir(fullfile(folderPath, '*_analyzed'));
    subfolders = subfolders([subfolders.isdir]); % Keep only directories

    for j = 1:length(subfolders)
        analyzedDir = fullfile(folderPath, subfolders(j).name);
        behaviorFile = fullfile(analyzedDir, 'Behavior.mat');
        if isfile(behaviorFile)
            behaviorData = load(behaviorFile, 'Behavior');

            % Extract platform_vec and tone_bouts
            if isfield(behaviorData.Behavior, 'Spatial') && isfield(behaviorData.Behavior.Spatial, 'platform') && isfield(behaviorData.Behavior.Spatial.platform, 'inROIvector') && isfield(behaviorData.Behavior, 'Temporal') && isfield(behaviorData.Behavior.Temporal, 'CSp') && isfield(behaviorData.Behavior.Temporal.CSp, 'Bouts')
                platform_vec = behaviorData.Behavior.Spatial.platform.inROIvector;
                tone_bouts = behaviorData.Behavior.Temporal.CSp.Bouts;

                % Process each tone bout
                for k = 1:size(tone_bouts, 1)
                    tone_frames = platform_vec(tone_bouts(k, 1):tone_bouts(k, 2));
                    proportion = sum(tone_frames) / length(tone_frames);

                    % Append exp_ID, tone_frames and proportion to the concatenated data
                    concatenatedData.platform_tone_vector = [concatenatedData.platform_tone_vector; {exp_ID, tone_frames}];
                    concatenatedData.proportion_in_platform = [concatenatedData.proportion_in_platform; {exp_ID, proportion}];
                end
            end
        end
    end
end

% Display the final concatenated data
disp(concatenatedData);
