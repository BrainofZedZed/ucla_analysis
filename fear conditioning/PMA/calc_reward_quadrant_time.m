% Define the input (grandfather) directory
inputDir = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\PMAR_JAWS\cohort4_20231113\batch\other_days'; % Replace with your directory path

% Initialize the output cell matrix with a header row
outputMatrix = {'exp_ID', 'overall_percent_in_reward_zone', ...
                'total_percent_in_reward_zone_during_tones', 'percent_in_reward_zone_each_tone', ...
                'percent_in_reward_zone_avg_three_tones', 'overall_percent_in_platform_zone', ...
                'total_percent_in_platform_zone_during_tones', 'percent_in_platform_zone_each_tone', ...
                'percent_in_platform_zone_avg_three_tones'};

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
        % Use the prefix before '_analyzed' as the experiment ID
        exp_ID = analyzedDirNames{a}(1:end-9); % Remove '_analyzed' from the folder name

        % Load data from .mat files if they exist
        paramsPath = fullfile(analyzedDirPath, 'Params.mat');
        trackingPath = fullfile(analyzedDirPath, 'Tracking.mat');
        behaviorPath = fullfile(analyzedDirPath, 'Behavior.mat');
        
        if isfile(paramsPath) && isfile(trackingPath) && isfile(behaviorPath)
            paramsData = load(paramsPath, 'Params');
            trackingData = load(trackingPath, 'Tracking');
            behaviorData = load(behaviorPath, 'Behavior');
            
            % Extract necessary variables
            xdim = paramsData.Params.Video.frameWidth;
            ydim = paramsData.Params.Video.frameHeight;
            location = trackingData.Tracking.Smooth.BetwShoulders;
            tone_times = behaviorData.Behavior.Temporal.CSp.Bouts;      
            platform_vector = behaviorData.Behavior.Spatial.platform.inROIvector;
            overall_percent_in_platform_zone = behaviorData.Behavior.Spatial.platform.PerTimeInROI;
            
            %invert location
            location = location';

            % Define the reward quadrant
            reward_quadrant_top_left = [xdim*0.4, 1];
            reward_quadrant_bottom_right = [xdim, ydim*0.6];

            % Create the binary vector for each frame's presence in reward quadrant
            in_reward_quadrant = location(:,1) >= reward_quadrant_top_left(1) & ...
                                 location(:,1) <= reward_quadrant_bottom_right(1) & ...
                                 location(:,2) <= reward_quadrant_bottom_right(2) & ...
                                 location(:,2) >= reward_quadrant_top_left(2);
            
            % Calculate overall percent time in reward zone
            overall_percent_in_reward_zone = 100 * sum(in_reward_quadrant) / length(in_reward_quadrant);
            
            % Initialize variables for tone-by-tone analysis
            num_tones = size(tone_times, 1);
            percent_in_reward_zone_each_tone = zeros(num_tones, 1);
            percent_on_platform_each_tone = zeros(num_tones, 1);

            % Calculate metrics for each tone
            for i = 1:num_tones
                tone_frames = tone_times(i, 1):tone_times(i, 2);
                tone_frames = tone_frames(tone_frames <= length(in_reward_quadrant));
                percent_in_reward_zone_each_tone(i) = 100 * sum(in_reward_quadrant(tone_frames)) / length(tone_frames);
                percent_on_platform_each_tone(i) = 100 * sum(platform_vector(tone_frames)) / length(tone_frames);
            end

            % Calculate averages across every three tones
            avg_every_three = @(x) arrayfun(@(i) mean(x(i:min(i+2, end))), 1:3:length(x))';
            percent_in_reward_zone_avg_three_tones = avg_every_three(percent_in_reward_zone_each_tone);
            percent_on_platform_avg_three_tones = avg_every_three(percent_on_platform_each_tone);

            % Calculate total percent time during tones
            total_percent_in_reward_zone_during_tones = mean(percent_in_reward_zone_each_tone);
            total_percent_in_platform_zone_during_tones = mean(percent_on_platform_each_tone);

            % Append to output cell matrix
            outputMatrix{end+1, 1} = exp_ID;
            outputMatrix{end, 2} = overall_percent_in_reward_zone;
            outputMatrix{end, 3} = total_percent_in_reward_zone_during_tones;
            outputMatrix{end, 4} = percent_in_reward_zone_each_tone'; % Individual tones
            outputMatrix{end, 5} = percent_in_reward_zone_avg_three_tones'; % Averages of every three tones
            outputMatrix{end, 6} = overall_percent_in_platform_zone;
            outputMatrix{end, 7} = total_percent_in_platform_zone_during_tones;
            outputMatrix{end, 8} = percent_on_platform_each_tone'; % Individual tones
            outputMatrix{end, 9} = percent_on_platform_avg_three_tones'; % Averages of every three tones
        end
    end
end

% Display the output
disp(outputMatrix);


%save
save(fullfile(inputDir,'reward_platform_location_metrics2.mat'));


