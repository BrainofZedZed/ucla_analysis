%% 1. Parameters and Data Setup
% zall: NxM matrix (Rows = trials, Columns = time)
% Tone Onset: 500, Tone Offset: 2000
% Sampling Rate: 50 Hz

[N, M] = size(zall);
fs = 50;                        % Sampling frequency
onset = 250;                    % Tone onset index
offset = 1750;                  % Tone offset index
smooth_win = fs;                % 1-second window for smoothing (50 samples)
peak_search_sec = 2;            % Search for peak within 5s of onset
peak_samples = peak_search_sec * fs;

% Define indices for conditions
off_idx = 1:2:N;                % Odd rows
on_idx  = 2:2:N;                % Even rows
time_vec = (1:M) / fs;          % Time vector in seconds

%% 2. Precise Alignment (Baseline Subtraction)
% Define the 1-second window immediately preceding the tone
baseline_win = (onset - fs + 1):onset; 

% Subtract the mean of that 1-second window from each row
baseline_means = mean(zall(:, baseline_win), 2);
z_aligned = zall - baseline_means;

%% 3. Smoothing
% Apply a 1-second (50-sample) moving average across each trial
z_smoothed = smoothdata(z_aligned, 2, 'movmean', smooth_win);

%% 4. Extract Peak and AUC for Each Row
peaks = zeros(N, 1);
auc_vals = zeros(N, 1);
peak_range = onset:(onset + peak_samples);

for i = 1:N
    % Find max value in the 5s window following onset
    peaks(i) = max(z_smoothed(i, peak_range));
    
    % Calculate Area Under Curve for the duration of the tone
    auc_vals(i) = trapz(z_smoothed(i, onset:offset));
end

%% 5. Calculate Condition Statistics
% Means and SEM for the line plots
mean_off = mean(z_smoothed(off_idx, :), 1);
mean_on  = mean(z_smoothed(on_idx, :), 1);

sem_off = std(z_smoothed(off_idx, :), 0, 1) / sqrt(length(off_idx));
sem_on  = std(z_smoothed(on_idx, :), 0, 1) / sqrt(length(on_idx));

% Average Metrics for bar plots
avg_peak_off = mean(peaks(off_idx));
avg_peak_on  = mean(peaks(on_idx));

avg_auc_off = mean(auc_vals(off_idx));
avg_auc_on  = mean(auc_vals(on_idx));

%% 6. Visualization
figure('Color', 'w', 'Position', [100, 100, 1000, 450]);

% --- Subplot 1: Mean Traces (Line Plot) ---
subplot(1, 2, 1);
hold on;

% Shaded Error Bars (SEM)
fill([time_vec, fliplr(time_vec)], [mean_off + sem_off, fliplr(mean_off - sem_off)], ...
    'k', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
fill([time_vec, fliplr(time_vec)], [mean_on + sem_on, fliplr(mean_on - sem_on)], ...
    'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');

% Mean Lines
plot(time_vec, mean_off, 'k', 'LineWidth', 2, 'DisplayName', 'Laser Off');
plot(time_vec, mean_on, 'r', 'LineWidth', 2, 'DisplayName', 'Laser On');

% Tone Period Highlighter
y_lims = ylim;
patch([onset/fs offset/fs offset/fs onset/fs], [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], ...
    [0.8 0.8 0.8], 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
text(mean([onset, offset])/fs, y_lims(2), 'TONE', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

xlabel('Time (s)');
ylabel('Amplitude (Aligned & Smoothed)');
title('Mean Population Traces');
legend('show', 'Location', 'best');
grid on;

% --- Subplot 2: Metric Comparison (Bar Plots) ---
subplot(1, 2, 2);
% Plotting Peaks and AUC on different y-axes or side-by-side
data_to_plot = [avg_peak_off, avg_peak_on; avg_auc_off/100, avg_auc_on/100]; % Scaling AUC for visualization
b = bar(data_to_plot');
set(gca, 'XTickLabel', {'Laser Off', 'Laser On'});
legend({'Peak Response', 'AUC (scaled)'}, 'Location', 'best');
title('Comparison of Response Metrics');
ylabel('Magnitude');
grid on;

sgtitle('Analysis of Laser Effect on Tone Response');