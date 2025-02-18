% Define the grandparent directory
do_plots = true;
grandparent_dir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL\CSminus removed\normal gcamp';

% Get list of parent directories
parent_dirs = dir(grandparent_dir);
parent_dirs = parent_dirs([parent_dirs.isdir]); % Keep only directories
parent_dirs = parent_dirs(~ismember({parent_dirs.name}, {'.', '..'})); % Remove . and ..

% Initialize cell arrays to store data
data = {};
row = 1;

% Fields of interest
fields_of_interest = {'freeze', 'nontone_freeze', 'tone_freeze', 'tone_nonfreeze', 'CSp_onset', 'CSp_offset', 'CSp'};

% Loop through parent directories
for i = 1:length(parent_dirs)
    parent_path = fullfile(grandparent_dir, parent_dirs(i).name);
    
    % Get subdirectories
    sub_dirs = dir(parent_path);
    sub_dirs = sub_dirs([sub_dirs.isdir]);
    sub_dirs = sub_dirs(~ismember({sub_dirs.name}, {'.', '..'}));
    
    % Loop through subdirectories
    for j = 1:length(sub_dirs)
        sub_path = fullfile(parent_path, sub_dirs(j).name);
        mat_file = fullfile(sub_path, 'ca_roc_output.mat');
        
        % Check if mat file exists
        if exist(mat_file, 'file')
            % Load the mat file
            load(mat_file, 'out');
            
            % Store session ID
            data{row, 1} = sub_dirs(j).name;
            col = 2;
            
            % First, store all excited neuron IDs
            for k = 1:length(fields_of_interest)
                field = fields_of_interest{k};
                if isfield(out, field)
                    data{row, col} = out.(field).n_excited;
                else
                    data{row, col} = [];
                end
                col = col + 1;
            end
            
            % Then, store all suppressed neuron IDs
            for k = 1:length(fields_of_interest)
                field = fields_of_interest{k};
                if isfield(out, field)
                    data{row, col} = out.(field).n_suppressed;
                else
                    data{row, col} = [];
                end
                col = col + 1;
            end
            
            % Store excited fractions
            for k = 1:length(fields_of_interest)
                field = fields_of_interest{k};
                if isfield(out, field)
                    n_excited = length(out.(field).n_excited);
                    total_neurons = length(out.(field).auc_neurons);
                    data{row, col} = n_excited;
                    data{row, col+1} = n_excited / total_neurons;
                else
                    data{row, col} = 0;
                    data{row, col+1} = 0;
                end
                col = col + 2;
            end
            
            % Store suppressed fractions
            for k = 1:length(fields_of_interest)
                field = fields_of_interest{k};
                if isfield(out, field)
                    n_suppressed = length(out.(field).n_suppressed);
                    total_neurons = length(out.(field).auc_neurons);
                    data{row, col} = n_suppressed;
                    data{row, col+1} = n_suppressed / total_neurons;
                else
                    data{row, col} = 0;
                    data{row, col+1} = 0;
                end
                col = col + 2;
            end
            
            % Store combined fractions
            for k = 1:length(fields_of_interest)
                field = fields_of_interest{k};
                if isfield(out, field)
                    total_affected = length(out.(field).n_excited) + length(out.(field).n_suppressed);
                    total_neurons = length(out.(field).auc_neurons);
                    data{row, col} = total_affected;
                    data{row, col+1} = total_affected / total_neurons;
                else
                    data{row, col} = 0;
                    data{row, col+1} = 0;
                end
                col = col + 2;
            end
            
            row = row + 1;
        end
    end
end

% Create column names
colNames = {'SessionID'};

% Add excited ID columns
for i = 1:length(fields_of_interest)
    colNames = [colNames, [fields_of_interest{i} '_excited_ids']];
end

% Add suppressed ID columns
for i = 1:length(fields_of_interest)
    colNames = [colNames, [fields_of_interest{i} '_suppressed_ids']];
end

% Add excited count and fraction columns
for i = 1:length(fields_of_interest)
    colNames = [colNames, ...
                [fields_of_interest{i} '_n_excited'], ...
                [fields_of_interest{i} '_excited_frac']];
end

% Add suppressed count and fraction columns
for i = 1:length(fields_of_interest)
    colNames = [colNames, ...
                [fields_of_interest{i} '_n_suppressed'], ...
                [fields_of_interest{i} '_suppressed_frac']];
end

% Add combined count and fraction columns
for i = 1:length(fields_of_interest)
    colNames = [colNames, ...
                [fields_of_interest{i} '_n_total'], ...
                [fields_of_interest{i} '_total_frac']];
end

% Convert cell array to table
results_table = cell2table(data, 'VariableNames', colNames);

% Display the table
disp(results_table);

% Optionally, write to CSV file
writetable(results_table, 'neuron_analysis_results.csv');

%% 
if do_plots
    % Load the results table
    %results = readtable('neuron_analysis_results.csv');
    results = results_table;
    % Define the fields and modulation types
    fields_of_interest = {'nontone_freeze', 'tone_freeze', 'tone_nonfreeze', 'CSp_onset', 'CSp'};
    
    fields = fields_of_interest;
    mod_types = {'excited', 'suppressed', 'total'};
    days = {'D1', 'D28'}; % Define expected order of days
    
    % Create figure with subplots for each field
    figure('Position', [100 100 1200 800]);
    
    % Create a colormap for different animals
    unique_animals = {};
    for i = 1:height(results)
        % Extract animal ID (everything before the underscore)
        parts = split(results.SessionID{i}, '_');
        unique_animals{end+1} = parts{1};
    end
    unique_animals = unique(unique_animals);
    colors = lines(length(unique_animals));
    
    % Loop through each field
    for f = 1:length(fields)
        % Create subplots for each modulation type
        for m = 1:length(mod_types)
            subplot(length(fields), length(mod_types), (f-1)*length(mod_types) + m);
            hold on;
            
            % Process each animal
            for a = 1:length(unique_animals)
                animal = unique_animals{a};
                
                % Initialize data arrays
                day_data = nan(1, length(days));
                
                % Find all sessions for this animal
                animal_sessions = startsWith(results.SessionID, animal);
                animal_results = results(animal_sessions, :);
                
                % For each session, get the day and corresponding data
                for i = 1:height(animal_results)
                    session = animal_results.SessionID{i};
                    parts = split(session, '_');
                    day = parts{2};
                    
                    % Find the day index
                    day_idx = find(strcmp(days, day));
                    
                    if ~isempty(day_idx)
                        % Get the corresponding fraction column
                        col_name = [fields{f} '_' mod_types{m} '_frac'];
                        day_data(day_idx) = animal_results.(col_name)(i);
                    end
                end
                
                % Plot the data for this animal
                plot(1:length(days), day_data, 'o-', 'Color', colors(a,:), ...
                     'LineWidth', 1.5, 'MarkerSize', 6, ...
                     'DisplayName', animal);
            end
            
            % Customize plot
            title([fields{f} ' - ' mod_types{m}]);
            xlabel('Day');
            ylabel('Fraction of neurons');
            set(gca, 'XTick', 1:length(days));
            set(gca, 'XTickLabel', days);
            %ylim([0 max(0.5, max(get(gca, 'YLim')))]);  % Set minimum ylim to 0.5 or data max
            grid on;
            
            % Add legend to rightmost plots
            if m == length(mod_types)
                legend('Location', 'eastoutside');
            end
        end
    end

    % Adjust subplot spacing
    set(gcf, 'Units', 'normalized');
    set(gcf, 'Position', [0.1 0.1 0.8 0.8]);
    
    % Save the figure
    savefig('modulation_across_days.fig');
    print('modulation_across_days', '-dpdf', '-bestfit');
end


% Statistical analysis
fprintf('\nStatistical Analysis (Paired t-tests):\n');
fprintf('=====================================\n');

% Get the actual days present in the data
days = {'D1', 'D28'};
day1 = days{1};
day2 = days{2};
    
    % Initialize table for storing statistical results
    stat_results = table('Size', [length(fields)*length(mod_types), 5], ...
        'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
        'VariableNames', {'Field', 'ModType', 'Mean1', 'Mean2', 'PValue'});
    row = 1;
    
    for f = 1:length(fields)
        for m = 1:length(mod_types)
            % Get column name for this measurement
            col_name = [fields{f} '_' mod_types{m} '_frac'];
            
            % Initialize arrays for the two days
            vals_day1 = nan(length(unique_animals), 1);
            vals_day2 = nan(length(unique_animals), 1);
            
            % Collect data for each animal, ensuring paired data
            for a = 1:length(unique_animals)
                animal = unique_animals{a};
                
                % Get sessions for this animal
                animal_sessions = startsWith(results.SessionID, animal);
                animal_results = results(animal_sessions, :);
                
                % Get values for each day
                day1_idx = [];
                day2_idx = [];
                for i = 1:height(animal_results)
                    session = animal_results.SessionID{i};
                    parts = split(session, '_');
                    if strcmp(parts{2}, day1)
                        day1_idx = i;
                    elseif strcmp(parts{2}, day2)
                        day2_idx = i;
                    end
                end
                
                % Only include if we have data for both days
                if ~isempty(day1_idx) && ~isempty(day2_idx)
                    vals_day1(a) = animal_results.(col_name)(day1_idx);
                    vals_day2(a) = animal_results.(col_name)(day2_idx);
                end
            end
            
            % Remove any NaN values (animals missing data for either day)
            valid_idx = ~isnan(vals_day1) & ~isnan(vals_day2);
            vals_day1 = vals_day1(valid_idx);
            vals_day2 = vals_day2(valid_idx);
            
            % Perform paired t-test if we have matching data
            if ~isempty(vals_day1) && ~isempty(vals_day2)
                [~, p] = ttest(vals_day1, vals_day2);
                
                % Store results
                stat_results.Field(row) = fields{f};
                stat_results.ModType(row) = mod_types{m};
                stat_results.Mean1(row) = mean(vals_day1);
                stat_results.Mean2(row) = mean(vals_day2);
                stat_results.PValue(row) = p;
                
                row = row + 1;
            end
        end
    end
    
    % Display results
    fprintf('\nComparison between %s and %s:\n', day1, day2);
    disp(stat_results);
    
    % Save statistical results
    writetable(stat_results, fullfile('modulation_plots', 'statistical_results.csv'));