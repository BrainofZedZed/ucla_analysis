%% ---------------------------------------------------------
%   BATCH ANALYSIS SCRIPT: DETAILED FREEZING + BRAKE FADE
%   ---------------------------------------------------------
clear;

%% 1. Parameters
fps = 50;
post_tone_sec = 30;
post_tone_frames = post_tone_sec * fps;

% --- BRAKE FADE PARAMETERS ---
tone_dur_sec = 30;
bin_size_sec = 5; % Size of the "micro-assessment" bins
num_bins = floor(tone_dur_sec / bin_size_sec);

% --- DEFINE GROUPS (Trial Indices) ---
TARGET_LASER_OFF = [6, 8]; 
TARGET_LASER_ON  = [5, 7]; 

%% 2. Directory Selection
main_dir = uigetdir(pwd, 'Select the Parent Directory (e.g., bb)');
if main_dir == 0, disp('User cancelled.'); return; end

% Recursive Search for Behavior.mat
fileList = dir(fullfile(main_dir, '**', 'Behavior.mat'));
if isempty(fileList)
    warning('No Behavior.mat files found in %s', main_dir);
    return;
end

%% 3. Initialize Accumulator Table & Group Arrays
SummaryData = table(); 

% Matrices to hold Time-Course data for Group Plots
% Dimensions: [Rows = Animals, Cols = Time Bins]
Group_Tone_Off = [];
Group_Tone_On  = [];
Group_IDs      = {};
Global_Time_Bins = []; % To store the x-axis values

% Standard Metrics
standard_metrics = {...
    'AvgBoutDur_Tone', 'NumBouts_Tone', 'LatencyFirstFreeze_Tone', 'AvgIBI_Tone', ...
    'AvgBoutDur_Post', 'NumBouts_Post', 'LatencySwitch_Post', 'InitialState_Post', 'AvgIBI_Post'};

% Create Bin Metric Names dynamically (e.g., Bin1_0to5s)
bin_metrics = cell(1, num_bins);
for b = 1:num_bins
    t_start = (b-1)*bin_size_sec;
    t_end = b*bin_size_sec;
    bin_metrics{b} = sprintf('Bin%d_%dto%ds', b, t_start, t_end);
end

% Combine all metric names
all_metrics = [standard_metrics, bin_metrics];

%% 4. Batch Loop
fprintf('Found %d Behavior.mat files. Starting batch processing...\n', length(fileList));

for k = 1:length(fileList)
    
    % File & Folder Info
    beh_file = fullfile(fileList(k).folder, fileList(k).name);
    curr_path = fileList(k).folder;
    [~, curr_folder_name] = fileparts(curr_path);
    
    if endsWith(curr_folder_name, '_analyzed')
        
        animalID = strrep(curr_folder_name, '_analyzed', '');
        fprintf('Processing: %s ... ', animalID);
        
        try
            % --- LOAD DATA ---
            loaded_data = load(beh_file);
            if ~isfield(loaded_data, 'Behavior'), continue; end
            Behavior = loaded_data.Behavior;
            
            if ~isfield(Behavior, 'Intersect') || ~isfield(Behavior.Intersect, 'TemBeh')
                 continue;
            end
            
            tone_matrix = Behavior.Intersect.TemBeh.CSp.Freezing.Cue_BehInEventVector; 
            tone_bouts = Behavior.Temporal.CSp.Bouts; 
            full_freeze_vec = Behavior.Freezing.Vector;
            
            n_trials = size(tone_matrix, 1);
            valid_off = TARGET_LASER_OFF(TARGET_LASER_OFF <= n_trials);
            valid_on  = TARGET_LASER_ON(TARGET_LASER_ON <= n_trials);
            
            % --- 1. EXTRACT RAW MATRICES ---
            raw_tone_off = tone_matrix(valid_off, :);
            [raw_post_off, ~] = get_post_tone_matrix(valid_off, tone_bouts, full_freeze_vec, post_tone_frames);
            
            raw_tone_on = tone_matrix(valid_on, :);
            [raw_post_on, ~] = get_post_tone_matrix(valid_on, tone_bouts, full_freeze_vec, post_tone_frames);
            
            % --- 2. CALCULATE METRICS (Standard) ---
            Results = struct();
            Results.LaserOff = get_averaged_metrics(raw_tone_off, raw_post_off, fps);
            Results.LaserOn  = get_averaged_metrics(raw_tone_on, raw_post_on, fps);
            
            % --- 3. CALCULATE INTRA-TRIAL DYNAMICS (Brake Fade) ---
            % Returns a vector [MeanBin1, MeanBin2, ...] representing % freezing
            [fade_off, ~] = get_binned_evolution(raw_tone_off, fps, bin_size_sec, num_bins);
            [fade_on, t_bins] = get_binned_evolution(raw_tone_on, fps, bin_size_sec, num_bins);
            
            % --- ACCUMULATE TIME-SERIES FOR GROUP PLOTS ---
            % Store entire trace for this animal
            Group_Tone_Off = [Group_Tone_Off; fade_off]; %#ok<*AGROW>
            Group_Tone_On  = [Group_Tone_On;  fade_on];
            Group_IDs      = [Group_IDs; {animalID}];
            Global_Time_Bins = t_bins; % Save for x-axis later
            
            % Store bins in Results struct for dynamic access
            for b = 1:num_bins
                mName = bin_metrics{b};
                Results.LaserOff.(mName) = fade_off(b);
                Results.LaserOn.(mName)  = fade_on(b);
            end
            
            % --- 4. GENERATE INDIVIDUAL PLOT ---
            % We pass the calculated 'fade' vectors to plot them directly
            hFig = generate_plot_fade(fade_off, fade_on, raw_post_off, raw_post_on, fps, t_bins, animalID);
            
            % Save Outputs
            save(fullfile(curr_path, 'detailed_freezing_cla.mat'), 'Results');
            saveas(hFig, fullfile(curr_path, 'detailed_freezing_cla.png'));
            close(hFig);
            
            % --- 5. APPEND TO TABLE ---
            newRow = table();
            newRow.ID = {animalID};
            
            for m = 1:length(all_metrics)
                mName = all_metrics{m};
                
                val_off = Results.LaserOff.(mName);
                val_on  = Results.LaserOn.(mName);
                val_diff = val_off - val_on;
                
                newRow.(['Off_' mName]) = val_off;
                newRow.(['On_' mName])  = val_on;
                newRow.(['Diff_' mName]) = val_diff;
            end
            
            if isempty(SummaryData)
                SummaryData = newRow;
            else
                SummaryData = [SummaryData; newRow];
            end
            
            fprintf('Done.\n');
            
        catch ME
            fprintf('ERROR: %s\n', ME.message);
        end
    end
end

%% 5. Save Summary Data
fprintf('\n---------------------------------------------------------\n');
fprintf('Batch Processing Complete.\n');

if ~isempty(SummaryData)
    assignin('base', 'BatchSummary', SummaryData);
    
    % Save to Excel
    summary_path = fullfile(main_dir, 'Batch_Freezing_Summary_cla.xlsx');
    save(fullfile(main_dir,'summary_freezing_batch_cla.mat'), "SummaryData");
    
    fprintf('Summary saved to: %s\n', summary_path);
else
    disp('No data was processed.');
    return;
end

%% 6. GENERATE GROUP TIME-COURSE PLOTS
fprintf('Generating Group Time-Course Plots...\n');

% Calculate Mean and SEM across animals (Dimension 1)
n_subs = size(Group_Tone_Off, 1);

mean_off = mean(Group_Tone_Off, 1, 'omitnan');
sem_off  = std(Group_Tone_Off, 0, 1, 'omitnan') / sqrt(n_subs);

mean_on  = mean(Group_Tone_On, 1, 'omitnan');
sem_on   = std(Group_Tone_On, 0, 1, 'omitnan') / sqrt(n_subs);

x = Global_Time_Bins; 

% --- PLOT A: Mean +/- SEM (Shaded Area) ---
hGroup1 = figure('Name', 'Group Dynamics: Mean SEM', 'Color', 'w', 'Position', [100 100 600 500]);
hold on;

% Plot OFF (Black/Grey)
fill([x, fliplr(x)], [mean_off + sem_off, fliplr(mean_off - sem_off)], ...
     [0.2 0.2 0.2], 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Grey shade
p1 = plot(x, mean_off, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'k');

% Plot ON (Blue)
fill([x, fliplr(x)], [mean_on + sem_on, fliplr(mean_on - sem_on)], ...
     [0 0 1], 'FaceAlpha', 0.2, 'EdgeColor', 'none'); % Blue shade
p2 = plot(x, mean_on, '-ob', 'LineWidth', 2, 'MarkerFaceColor', 'b');

xlabel('Time in Tone (s)');
ylabel('Freezing (%)');
title(sprintf('Group Tone Dynamics (Mean \\pm SEM, n=%d)', n_subs));
legend([p1, p2], {'Laser Off', 'Laser On'}, 'Location', 'SouthWest');
ylim([0 100]); xlim([0 max(x)+2]);
xticks(x);
grid on; axis square;
hold off;

saveas(hGroup1, fullfile(main_dir, 'Group_Dynamics_MeanSEM.png'));

% --- PLOT B: Mean + Thin Individual Lines ---
hGroup2 = figure('Name', 'Group Dynamics: Individual', 'Color', 'w', 'Position', [700 100 600 500]);
hold on;

% Plot Individual Lines (Thin)
for i = 1:n_subs
    plot(x, Group_Tone_Off(i, :), '-', 'Color', [0.7 0.7 0.7, 0.4], 'LineWidth', 1); % Faint Grey
    plot(x, Group_Tone_On(i, :),  '-', 'Color', [0.6 0.6 1, 0.4],   'LineWidth', 1); % Faint Blue
end

% Plot Means (Thick)
p1 = plot(x, mean_off, '-k', 'LineWidth', 3);
p2 = plot(x, mean_on,  '-b', 'LineWidth', 3);

xlabel('Time in Tone (s)');
ylabel('Freezing (%)');
title('Individual Animal Dynamics');
legend([p1, p2], {'Mean Off', 'Mean On'}, 'Location', 'SouthWest');
ylim([0 100]); xlim([0 max(x)+2]);
xticks(x);
grid on; axis square;
hold off;

saveas(hGroup2, fullfile(main_dir, 'Group_Dynamics_Individual.png'));

fprintf('Group plots saved to parent directory.\n');

%% ---------------------------------------------------------
%  HELPER FUNCTIONS
%  ---------------------------------------------------------
function [bin_means, time_labels] = get_binned_evolution(data_matrix, fps, bin_sec, n_bins)
    % DATA_MATRIX: Trials x Frames
    % Returns mean % freezing for each bin across all trials
    
    if isempty(data_matrix)
        bin_means = nan(1, n_bins);
        time_labels = 1:n_bins;
        return;
    end
    
    bin_frames = bin_sec * fps;
    bin_means = nan(1, n_bins);
    
    for b = 1:n_bins
        idx_start = (b-1)*bin_frames + 1;
        idx_end = b*bin_frames;
        
        % Check bounds
        if idx_end > size(data_matrix, 2), idx_end = size(data_matrix, 2); end
        
        % Extract slice: All trials, specific time window
        slice = data_matrix(:, idx_start:idx_end);
        
        % Mean of slice (Mean of all pixels in that block) * 100
        bin_means(b) = mean(slice, 'all', 'omitnan') * 100;
    end
    
    % Create simple time labels (e.g., 5, 10, 15...)
    time_labels = (1:n_bins) * bin_sec; 
end

function h = generate_plot_fade(fade_off, fade_on, raw_post_off, raw_post_on, fps, t_bins, ID)
    % Generates 2 subplots:
    % 1. "Brake Fade" (Tone Dynamics) - 5s bins
    % 2. Post-Tone Dynamics - 1s bins (High Res)
    
    % Prepare Post-Tone Data (High res 1s bins)
    [binned_post_off, t_vec_post] = bin_data_average(raw_post_off, fps);
    [binned_post_on, ~]           = bin_data_average(raw_post_on, fps);
    mean_post_off = mean(binned_post_off, 1, 'omitnan') * 100;
    mean_post_on  = mean(binned_post_on, 1, 'omitnan') * 100;
    
    h = figure('Color', 'w', 'Position', [100 100 1000 500], 'Visible', 'off');
    
    % --- SUBPLOT 1: TONE (Intra-Trial Dynamics) ---
    subplot(1,2,1); hold on;
    % Plot lines connecting the bins
    plot(t_bins, fade_off, '-o', 'Color', 'k', 'LineWidth', 2, 'MarkerFaceColor', 'k', 'MarkerSize', 6);
    plot(t_bins, fade_on,  '-o', 'Color', 'b', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerSize', 6);
    
    xlabel('Time in Tone (s)'); 
    ylabel('Mean Freezing (%)'); 
    title([ID ' - Intra-Trial Dynamics']);
    legend({'Laser Off', 'Laser On'}, 'Location', 'SouthWest');
    ylim([0 105]); xlim([0 max(t_bins)+2]);
    set(gca, 'XTick', t_bins); 
    grid on;
    
    % --- SUBPLOT 2: POST-TONE ---
    subplot(1,2,2); hold on;
    plot(t_vec_post, mean_post_off, '-ok', 'LineWidth', 1.5, 'MarkerFaceColor', 'k', 'MarkerSize', 4);
    plot(t_vec_post, mean_post_on, '-ob', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'MarkerSize', 4);
    
    xlabel('Time Post-Tone (s)'); 
    ylabel('Mean Freezing (%)'); 
    title('Post-Tone Persistence');
    ylim([0 105]); 
    grid on;
end

function GroupStats = get_averaged_metrics(tone_mat, post_mat, fps)
    n = size(tone_mat, 1);
    metrics = {'AvgBoutDur_Tone', 'NumBouts_Tone', 'LatencyFirstFreeze_Tone', 'AvgIBI_Tone', ...
               'AvgBoutDur_Post', 'NumBouts_Post', 'LatencySwitch_Post', 'InitialState_Post', 'AvgIBI_Post'};
           
    if n == 0
        for m = 1:length(metrics), GroupStats.(metrics{m}) = NaN; end
        return;
    end
    
    t_AB_T=nan(n,1); t_NB_T=nan(n,1); t_Lat_T=nan(n,1); t_IBI_T=nan(n,1);
    t_AB_P=nan(n,1); t_NB_P=nan(n,1); t_LatSw=nan(n,1); t_Init=nan(n,1); t_IBI_P=nan(n,1);
    
    for i = 1:n
        % Tone Stats
        [ab, nb, lat, ibi] = analyze_freezing_structure(tone_mat(i,:), fps);
        t_AB_T(i)=ab; t_NB_T(i)=nb; t_Lat_T(i)=lat; t_IBI_T(i)=ibi;
        
        % Post Stats
        if ~all(isnan(post_mat(i,:)))
             [ab_p, nb_p, ~, ibi_p] = analyze_freezing_structure(post_mat(i,:), fps);
             
             start_idx = find(~isnan(post_mat(i,:)), 1, 'first');
             if isempty(start_idx)
                 lat_sw = NaN; init_s = NaN;
             else
                 vec = post_mat(i, start_idx:end);
                 init_s = vec(1);
                 if init_s == 0, lat_sw = find(vec==1,1,'first'); else, lat_sw = find(vec==0,1,'first'); end
                 if isempty(lat_sw), lat_sw=NaN; else, lat_sw=lat_sw/fps; end
             end
             t_AB_P(i)=ab_p; t_NB_P(i)=nb_p; t_LatSw(i)=lat_sw; t_Init(i)=init_s; t_IBI_P(i)=ibi_p;
        end
    end
    
    GroupStats.AvgBoutDur_Tone = mean(t_AB_T, 'omitnan');
    GroupStats.NumBouts_Tone = mean(t_NB_T, 'omitnan');
    GroupStats.LatencyFirstFreeze_Tone = mean(t_Lat_T, 'omitnan');
    GroupStats.AvgIBI_Tone = mean(t_IBI_T, 'omitnan');
    
    GroupStats.AvgBoutDur_Post = mean(t_AB_P, 'omitnan');
    GroupStats.NumBouts_Post = mean(t_NB_P, 'omitnan');
    GroupStats.LatencySwitch_Post = mean(t_LatSw, 'omitnan');
    GroupStats.InitialState_Post = mean(t_Init, 'omitnan');
    GroupStats.AvgIBI_Post = mean(t_IBI_P, 'omitnan');
end

function [avg_len, num_bouts, latency, avg_ibi] = analyze_freezing_structure(vec, fps)
    vec = vec(~isnan(vec));
    if isempty(vec), avg_len=NaN; num_bouts=NaN; latency=NaN; avg_ibi=NaN; return; end
    d = diff([0, vec(:)', 0]); 
    starts = find(d == 1); stops = find(d == -1);
    num_bouts = length(starts);
    if num_bouts > 0, avg_len = mean(stops - starts) / fps; else, avg_len = 0; end
    first_idx = find(vec == 1, 1, 'first');
    if isempty(first_idx), latency = NaN; else, latency = first_idx / fps; end
    if num_bouts > 1, avg_ibi = mean(starts(2:end) - stops(1:end-1)) / fps; else, avg_ibi = NaN; end
end

function [binned_data, t_vec] = bin_data_average(data_matrix, fps)
    n_frames = size(data_matrix, 2); n_trials = size(data_matrix, 1);
    n_bins = floor(n_frames / fps);
    binned_data = nan(n_trials, n_bins);
    for b = 1:n_bins
        idx_start = (b-1)*fps + 1; idx_end = b*fps;
        binned_data(:, b) = mean(data_matrix(:, idx_start:idx_end), 2, 'omitnan');
    end
    t_vec = 1:n_bins; 
end

function [post_mat, valid_indices] = get_post_tone_matrix(indices, all_bouts, full_vec, pt_frames)
    num_trials = length(indices); post_mat = nan(num_trials, pt_frames); valid_indices = [];
    for k = 1:num_trials
        idx = indices(k); stop_idx = all_bouts(idx, 2);
        start_post = stop_idx + 1; end_post = stop_idx + pt_frames;
        if end_post > length(full_vec), end_post = length(full_vec); end
        if start_post <= length(full_vec)
            vec = full_vec(start_post:end_post); post_mat(k, 1:length(vec)) = vec;
        end
    end
end