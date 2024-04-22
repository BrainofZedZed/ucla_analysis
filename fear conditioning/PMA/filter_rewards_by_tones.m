% Define the input directory (adjust this to your specific directory)
inputDir = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\PMAR_JAWS\controls\cohort5_20240115\PMAR\batch';

% Initialize output cell arrays with headers
output1 = {'exp_ID', 'rewards_in_tone'};
output2 = {'exp_ID', 'rewards_in_tone', 'tone_frames', 'all_rewards'};

% Get a list of all subdirectories
subDirs = dir(inputDir);
isSub = [subDirs(:).isdir];
subDirNames = {subDirs(isSub).name}';
subDirNames(ismember(subDirNames, {'.', '..'})) = [];

% Iterate over each subdirectory
for d = 1:length(subDirNames)
    currentDir = fullfile(inputDir, subDirNames{d});
    % List all .mat files
    files = dir(fullfile(currentDir, '*.mat')); 

    % Process each file
    for f = 1:length(files)
        fileName = files(f).name;
        % Validate the filename matches the expected datetime pattern
        if ~isempty(regexp(fileName, '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.mat$', 'once'))
            filePath = fullfile(currentDir, fileName);
            data = load(filePath, 'reward_frames', 'cueframes', 'exp_ID');

            if isfield(data, 'reward_frames') && isfield(data, 'cueframes') && isfield(data, 'exp_ID')
                % Extract rewards during tone
                rewardsDuringTone = 0;
                for i = 1:size(data.cueframes.CSp, 1)
                    % Count how many rewards are during each tone interval
                    rewardsDuringTone = rewardsDuringTone + ...
                        sum(data.reward_frames > data.cueframes.CSp(i, 1) & ...
                            data.reward_frames < data.cueframes.CSp(i, 2));
                end
                
                % Append to output arrays
                output1{end+1, 1} = data.exp_ID;
                output1{end, 2} = rewardsDuringTone;
                
                output2{end+1, 1} = data.exp_ID;
                output2{end, 2} = rewardsDuringTone;
                output2{end, 3} = data.cueframes.CSp;
                output2{end, 4} = data.reward_frames;
            end
        end
    end
end

% Optionally, save the results to .mat files
save(fullfile(inputDir, 'reward_filter_tones.mat'), 'output1', 'output2');

% Display the results
disp('Output 1:');
disp(output1);
disp('Output 2:');
disp(output2);
