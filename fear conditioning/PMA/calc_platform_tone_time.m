% Define the input (grandfather) directory
inputDir = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\PMAR_JAWS\controls\cohort1\batch'; % Replace with your directory path
outputName = 'platform_tone_output.mat';
% Initialize the output cell matrix with a header row
outputMatrix = {'exp_ID', 'all_platform_bouts', 'platform_bout_during_tone', 'platform_bouts_during_tone', ...
                'duration_of_tone_platform_bouts', 'average_duration_tone_platform_bouts', ...
                'platform_bouts_not_in_tone', 'duration_of_non_tone_platform_bouts', ...
                'average_duration_non_tone_platform_bouts'};

% List all immediate subdirectories of the input directory
subDirs = dir(inputDir);
isSub = [subDirs(:).isdir];
subDirNames = {subDirs(isSub).name}';
subDirNames(ismember(subDirNames, {'.', '..'})) = [];

% Iterate over each immediate subdirectory to find "_analyzed" folders
for d = 1:length(subDirNames)
    currentSubDir = fullfile(inputDir, subDirNames{d});
    analyzedDirs = dir(fullfile(currentSubDir, '*_analyzed'));
    analyzedSub = [analyzedDirs(:).isdir];
    analyzedDirNames = {analyzedDirs(analyzedSub).name}';

    % Iterate over each "_analyzed" subdirectory found
    for a = 1:length(analyzedDirNames)
        analyzedDirPath = fullfile(currentSubDir, analyzedDirNames{a});
        exp_ID = analyzedDirNames{a}(1:end-9); % Use the prefix before '_analyzed' as the experiment ID

        behaviorPath = fullfile(analyzedDirPath, 'Behavior.mat');
        if isfile(behaviorPath)
            behaviorData = load(behaviorPath, 'Behavior');
            platform_bouts = behaviorData.Behavior.Spatial.platform.Bouts;
            tone_times = behaviorData.Behavior.Temporal.CSp.Bouts;

            platform_bout_during_tone = false(size(platform_bouts, 1), 1);
            platform_bouts_during_tone = [];
            duration_of_tone_platform_bouts = [];
            platform_bouts_not_in_tone = [];
            duration_of_non_tone_platform_bouts = [];

            % Determine platform bout overlaps with tones
            for i = 1:size(platform_bouts, 1)
                bout_start = platform_bouts(i, 1);
                bout_end = platform_bouts(i, 2);
                
                for j = 1:size(tone_times, 1)
                    tone_start = tone_times(j, 1);
                    tone_end = tone_times(j, 2);

                    if (bout_start <= tone_end && bout_end >= tone_start)
                        platform_bout_during_tone(i) = true;
                        actual_start = max(bout_start, tone_start);
                        actual_end = min(bout_end, tone_end);
                        platform_bouts_during_tone = [platform_bouts_during_tone; [actual_start, actual_end]];
                        duration = (actual_end - actual_start) / 50; % Assuming 50 fps
                        duration_of_tone_platform_bouts = [duration_of_tone_platform_bouts; duration];
                        break; % Assume one bout doesn't span multiple tones
                    end
                end
                
                if ~platform_bout_during_tone(i)
                    platform_bouts_not_in_tone = [platform_bouts_not_in_tone; [bout_start, bout_end]];
                    duration = (bout_end - bout_start) / 50; % Assuming 50 fps
                    duration_of_non_tone_platform_bouts = [duration_of_non_tone_platform_bouts; duration];
                end
            end

            average_duration_tone_platform_bouts = mean(duration_of_tone_platform_bouts);
            average_duration_non_tone_platform_bouts = mean(duration_of_non_tone_platform_bouts);
            
            % Append to output cell matrix
            outputMatrix{end+1, 1} = exp_ID;
            outputMatrix{end, 2} = platform_bouts;
            outputMatrix{end, 3} = platform_bout_during_tone;
            outputMatrix{end, 4} = platform_bouts_during_tone;
            outputMatrix{end, 5} = duration_of_tone_platform_bouts;
            outputMatrix{end, 6} = average_duration_tone_platform_bouts;
            outputMatrix{end, 7} = platform_bouts_not_in_tone;
            outputMatrix{end, 8} = duration_of_non_tone_platform_bouts;
            outputMatrix{end, 9} = average_duration_non_tone_platform_bouts;
        end
    end
end

% Display the output
disp(outputMatrix);

save(fullfile(inputDir, outputName),'outputMatrix');