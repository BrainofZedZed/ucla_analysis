
% 1. Get the directory of interest
parent_dir = uigetdir('', 'Select the Parent Directory containing Animal Subfolders');

if parent_dir == 0
    disp('User cancelled.');
    return;
end

% 2. Find all direct subdirectories
items = dir(parent_dir);
dirFlags = [items.isdir];
subDirs = items(dirFlags);
subDirs = subDirs(~ismember({subDirs.name}, {'.', '..'}));

% Initialize the accumulator
% This will become a (Num Animals) x 3000 matrix
accumulator_means = [];

fprintf('Found %d subdirectories. Starting processing...\n\n', length(subDirs));

%% Main Loop
for k = 1:length(subDirs)
    curr_sub_name = subDirs(k).name;
    curr_path = fullfile(parent_dir, curr_sub_name);
    
    % 3. Find file ending in '_analysis.mat'
    file_list = dir(fullfile(curr_path, '*_analysis.mat'));
    
    if isempty(file_list)
        fprintf('Skipping [%s]: No *_analysis.mat file found.\n', curr_sub_name);
        continue;
    end
    
    target_file = fullfile(curr_path, file_list(1).name);
    
    try
        % 4. Load 'zall'
        temp = load(target_file, 'zall');
        
        if isfield(temp, 'zall')
            zall = temp.zall;
            
            % 5. Enforce Length (1:3000)
            if size(zall, 2) >= 2250
                zall = zall(:, 1:2250);
            else
                fprintf('Skipping [%s]: zall is too short (%d frames). Needs >3000.\n', ...
                    curr_sub_name, size(zall, 2));
                continue;
            end
            
            % ---------------------------------------------------------
            % PROCESSING STEPS
            % ---------------------------------------------------------
            
            % Step A: Smooth each row (Window 25)
            % This smooths individual trials
            zall_smoothed = smoothdata(zall, 2, 'movmean', 25);
            
            % Step B: Average across rows (Trials) into a single vector
            % Result is a 1x3000 vector
            z_avg_vector = mean(zall_smoothed, 1, 'omitnan');
            
            % Step C: Smooth the vector (Window 25)
            % This smooths the resulting average trace
            z_avg_vector = smoothdata(z_avg_vector, 2, 'movmean', 25);
            
            % Optional: Baseline Correction (from previous prompt)
            baseline = mean(z_avg_vector(450:500));
            z_avg_vector = z_avg_vector - baseline;
            
            % ---------------------------------------------------------
            
            % 6. Add to Accumulator
            % We append the single 1x3000 vector to the master list
            accumulator_means = [accumulator_means; z_avg_vector];
            
            fprintf('Processed [%s]: Averaged %d trials.\n', curr_sub_name, size(zall, 1));
        else
            fprintf('Skipping [%s]: Variable ''zall'' not found.\n', curr_sub_name);
        end
        
    catch ME
        fprintf('Error processing [%s]: %s\n', curr_sub_name, ME.message);
    end
end

%% Final Summary
fprintf('\n------------------------------------------------\n');
fprintf('Processing Complete.\n');
fprintf('Final Accumulator Size: %d Animals x %d Frames\n', size(accumulator_means));

% Optional: Plot the group result
if ~isempty(accumulator_means)
    figure;
    plot(mean(accumulator_means, 1));
    title('Group Average of Individual Animal Means');
    xlabel('Frames'); ylabel('Signal');
end