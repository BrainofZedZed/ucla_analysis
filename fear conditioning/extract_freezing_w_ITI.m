%% Parameters
fps = 50;
post_tone_sec = 30;
post_tone_frames = post_tone_sec * fps;

% --- USER INPUT: Define your groups here ---
laser_off_idx = [1, 3]; 
laser_on_idx  = [2, 4]; 

% Check if Behavior struct exists
if ~exist('Behavior', 'var')
    error('The variable "Behavior" was not found in the workspace.');
end

% Extract Main Data
tone_matrix = Behavior.Intersect.TemBeh.CSp.Freezing.Cue_BehInEventVector; 
tone_bouts = Behavior.Temporal.CSp.Bouts; % Nx2 start/stop indices
full_freeze_vec = Behavior.Freezing.Vector;

%% 1. Extract Data for Groups
% Get raw frame-by-frame matrices

% --- Group 1: Laser Off ---
raw_tone_off = tone_matrix(laser_off_idx, :);
[raw_post_off, ~] = get_post_tone_matrix(laser_off_idx, tone_bouts, full_freeze_vec, post_tone_frames);

% --- Group 2: Laser On ---
raw_tone_on = tone_matrix(laser_on_idx, :);
[raw_post_on, ~] = get_post_tone_matrix(laser_on_idx, tone_bouts, full_freeze_vec, post_tone_frames);

%% 2. Calculate Structural Metrics (AVERAGED)
% This calculates the metrics for all trials, then takes the MEAN across trials
Results.LaserOff = get_averaged_metrics(raw_tone_off, raw_post_off, fps);
Results.LaserOn  = get_averaged_metrics(raw_tone_on, raw_post_on, fps);

%% 3. Bin Data for Plotting (AVERAGE Logic)
% Logic: Average the 50 frames in a second (0.5 = 50% freezing in that second)

[binned_tone_off, t_vec_tone] = bin_data_average(raw_tone_off, fps);
[binned_tone_on, ~]           = bin_data_average(raw_tone_on, fps);

[binned_post_off, t_vec_post] = bin_data_average(raw_post_off, fps);
[binned_post_on, ~]           = bin_data_average(raw_post_on, fps);

% Calculate Group Means across trials (*100 for percentage)
mean_tone_off = mean(binned_tone_off, 1, 'omitnan') * 100;
mean_tone_on  = mean(binned_tone_on, 1, 'omitnan') * 100;

mean_post_off = mean(binned_post_off, 1, 'omitnan') * 100;
mean_post_on  = mean(binned_post_on, 1, 'omitnan') * 100;

%% 4. Plotting

figure('Color', 'w', 'Position', [100 100 1200 500]);

% --- Subplot 1: Tone ---
subplot(1,2,1); hold on;
plot(t_vec_tone, mean_tone_off, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot(t_vec_tone, mean_tone_on, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerSize', 4);
xlabel('Time in Tone (s)');
ylabel('Mean Freezing (%)'); 
title('Freezing During Tone (1s Avg)');
legend({'Laser Off', 'Laser On'}, 'Location', 'Best');
ylim([0 105]); 
grid on;

% --- Subplot 2: Post-Tone ---
subplot(1,2,2); hold on;
plot(t_vec_post, mean_post_off, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot(t_vec_post, mean_post_on, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerSize', 4);
xlabel('Time Post-Tone (s)');
ylabel('Mean Freezing (%)');
title('Freezing Post-Tone (1s Avg)');
ylim([0 105]);
grid on;

disp('Analysis Complete. Results struct now contains Group Averages.');

%% ---------------------------------------------------------
%  HELPER FUNCTIONS
%  ---------------------------------------------------------

function GroupStats = get_averaged_metrics(tone_mat, post_mat, fps)
    n = size(tone_mat, 1);
    
    % 1. Create temporary vectors to hold data for each trial
    temp_AvgBoutDur_Tone = nan(n,1);
    temp_NumBouts_Tone = nan(n,1);
    temp_LatencyFirstFreeze_Tone = nan(n,1);
    temp_AvgIBI_Tone = nan(n,1);
    
    temp_AvgBoutDur_Post = nan(n,1);
    temp_NumBouts_Post = nan(n,1);
    temp_LatencySwitch_Post = nan(n,1);
    temp_InitialState_Post = nan(n,1);
    temp_AvgIBI_Post = nan(n,1);
    
    % 2. Loop through trials and calculate individual metrics
    for i = 1:n
        % --- Tone Analysis ---
        vec_tone = tone_mat(i, :);
        [ab, nb, lat, ibi] = analyze_freezing_structure(vec_tone, fps);
        
        temp_AvgBoutDur_Tone(i) = ab;
        temp_NumBouts_Tone(i) = nb;
        temp_LatencyFirstFreeze_Tone(i) = lat;
        temp_AvgIBI_Tone(i) = ibi;
        
        % --- Post-Tone Analysis ---
        vec_post = post_mat(i, :);
        if ~all(isnan(vec_post))
             [ab_p, nb_p, ~, ibi_p] = analyze_freezing_structure(vec_post, fps);
             
             % Latency to switch state logic
             start_idx = find(~isnan(vec_post), 1, 'first');
             if isempty(start_idx)
                 lat_sw = NaN; initial_state = NaN;
             else
                 valid_vec = vec_post(start_idx:end);
                 initial_state = valid_vec(1);
                 
                 if initial_state == 0
                    lat_sw = find(valid_vec == 1, 1, 'first'); % Moving -> Freezing
                 else
                    lat_sw = find(valid_vec == 0, 1, 'first'); % Freezing -> Moving
                 end
                 
                 if isempty(lat_sw), lat_sw = NaN; else, lat_sw = lat_sw / fps; end
             end
             
             temp_AvgBoutDur_Post(i) = ab_p;
             temp_NumBouts_Post(i) = nb_p;
             temp_LatencySwitch_Post(i) = lat_sw;
             temp_InitialState_Post(i) = initial_state;
             temp_AvgIBI_Post(i) = ibi_p;
        end
    end
    
    % 3. Calculate MEAN across the group and save to struct
    % 'omitnan' ensures trials with no freezing don't break the calculation
    GroupStats.AvgBoutDur_Tone = mean(temp_AvgBoutDur_Tone, 'omitnan');
    GroupStats.NumBouts_Tone = mean(temp_NumBouts_Tone, 'omitnan');
    GroupStats.LatencyFirstFreeze_Tone = mean(temp_LatencyFirstFreeze_Tone, 'omitnan');
    GroupStats.AvgIBI_Tone = mean(temp_AvgIBI_Tone, 'omitnan');
    
    GroupStats.AvgBoutDur_Post = mean(temp_AvgBoutDur_Post, 'omitnan');
    GroupStats.NumBouts_Post = mean(temp_NumBouts_Post, 'omitnan');
    GroupStats.LatencySwitch_Post = mean(temp_LatencySwitch_Post, 'omitnan');
    GroupStats.InitialState_Post = mean(temp_InitialState_Post, 'omitnan'); % Result is a proportion (0 to 1)
    GroupStats.AvgIBI_Post = mean(temp_AvgIBI_Post, 'omitnan');
end

function [avg_len, num_bouts, latency, avg_ibi] = analyze_freezing_structure(vec, fps)
    % Filter NaNs for calculation
    vec = vec(~isnan(vec));
    if isempty(vec)
        avg_len=NaN; num_bouts=NaN; latency=NaN; avg_ibi=NaN; return; 
    end
    d = diff([0, vec(:)', 0]); 
    starts = find(d == 1);
    stops = find(d == -1);
    num_bouts = length(starts);
    
    if num_bouts > 0
        avg_len = mean(stops - starts) / fps;
    else
        avg_len = 0;
    end
    
    first_idx = find(vec == 1, 1, 'first');
    if isempty(first_idx), latency = NaN; else, latency = first_idx / fps; end
    
    if num_bouts > 1
        avg_ibi = mean(starts(2:end) - stops(1:end-1)) / fps;
    else
        avg_ibi = NaN;
    end
end

function [binned_data, t_vec] = bin_data_average(data_matrix, fps)
    n_frames = size(data_matrix, 2);
    n_trials = size(data_matrix, 1);
    n_bins = floor(n_frames / fps);
    binned_data = nan(n_trials, n_bins);
    for b = 1:n_bins
        idx_start = (b-1)*fps + 1;
        idx_end = b*fps;
        chunk = data_matrix(:, idx_start:idx_end);
        binned_data(:, b) = mean(chunk, 2, 'omitnan');
    end
    t_vec = 1:n_bins; 
end

function [post_mat, valid_indices] = get_post_tone_matrix(indices, all_bouts, full_vec, pt_frames)
    num_trials = length(indices);
    post_mat = nan(num_trials, pt_frames);
    valid_indices = [];
    for k = 1:num_trials
        idx = indices(k);
        stop_idx = all_bouts(idx, 2);
        start_post = stop_idx + 1;
        end_post = stop_idx + pt_frames;
        if end_post > length(full_vec), end_post = length(full_vec); end
        if start_post <= length(full_vec)
            vec = full_vec(start_post:end_post);
            post_mat(k, 1:length(vec)) = vec;
        end
    end
end