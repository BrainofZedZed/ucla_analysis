%grandparent_dir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL\CSminus removed\normal gcamp';
grandparent_dir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\good\CSminus removed';
session_id = 'D28';

batch_venn_diagram(grandparent_dir, session_id)


function batch_venn_diagram(grandparent_dir, session_id)
    % Initialize counters
    total_csp_all = 0;
    total_freeze_all = 0;
    total_both_all = 0;
    total_csp_excited = 0;
    total_freeze_excited = 0;
    total_both_excited = 0;
    total_csp_suppressed = 0;
    total_freeze_suppressed = 0;
    total_both_suppressed = 0;
    total_neurons = 0;
    
    % Get list of animal directories
    animal_dirs = dir(grandparent_dir);
    animal_dirs = animal_dirs([animal_dirs.isdir]);
    animal_dirs = animal_dirs(~ismember({animal_dirs.name}, {'.', '..'}));
    
    for i = 1:length(animal_dirs)
        animal_id = animal_dirs(i).name;
        session_dir = fullfile(grandparent_dir, animal_id, [animal_id '_' session_id]);
        
        % Check if the session directory exists
        if ~exist(session_dir, 'dir')
            fprintf('Session directory not found for animal %s\n', animal_id);
            continue;
        end
        
        % Look for ca_roc_output.mat in the session directory
        data_file = fullfile(session_dir, 'ca_roc_output.mat');
        if ~exist(data_file, 'file')
            fprintf('ca_roc_output.mat not found for animal %s, session %s\n', animal_id, session_id);
            continue;
        end
        
        % Load the data
        load(data_file, 'out');
        
        % Calculate modulated neurons for this session
        csp_all = unique([out.CSp.n_excited; out.CSp.n_suppressed]);
        freeze_all = unique([out.freeze.n_excited; out.freeze.n_suppressed]);
        both_all = intersect(csp_all, freeze_all);
        
        csp_excited = out.CSp.n_excited;
        freeze_excited = out.freeze.n_excited;
        both_excited = intersect(csp_excited, freeze_excited);
        
        csp_suppressed = out.CSp.n_suppressed;
        freeze_suppressed = out.freeze.n_suppressed;
        both_suppressed = intersect(csp_suppressed, freeze_suppressed);
        
        % Update total counters
        total_csp_all = total_csp_all + length(csp_all);
        total_freeze_all = total_freeze_all + length(freeze_all);
        total_both_all = total_both_all + length(both_all);
        
        total_csp_excited = total_csp_excited + length(csp_excited);
        total_freeze_excited = total_freeze_excited + length(freeze_excited);
        total_both_excited = total_both_excited + length(both_excited);
        
        total_csp_suppressed = total_csp_suppressed + length(csp_suppressed);
        total_freeze_suppressed = total_freeze_suppressed + length(freeze_suppressed);
        total_both_suppressed = total_both_suppressed + length(both_suppressed);
        
        total_neurons = total_neurons + length(unique([csp_all; freeze_all]));
        
        fprintf('Processed animal %s, session %s\n', animal_id, session_id);
    end
    
    % Create figure with 3 subplots
    figure('Position', [100, 100, 1200, 400]);
    
    % 1. All modulated neurons
    subplot(1, 3, 1);
    plot_venn(total_csp_all, total_freeze_all, total_both_all, 'All Modulated Neurons');
    
    % 2. Excited neurons only
    subplot(1, 3, 2);
    plot_venn(total_csp_excited, total_freeze_excited, total_both_excited, 'Excited Neurons Only');
    
    % 3. Suppressed neurons only
    subplot(1, 3, 3);
    plot_venn(total_csp_suppressed, total_freeze_suppressed, total_both_suppressed, 'Suppressed Neurons Only');
    
    % Add overall title
    sgtitle(sprintf('Neuron Modulation Analysis - Session: %s', session_id), 'FontSize', 16);
    
    % Print overall total neurons
    fprintf('\nTotal neurons across all categories: %d\n', total_neurons);
end

function plot_venn(n_csp, n_freeze, n_overlap, subtitle_text)
    % Calculate total neurons for this specific Venn diagram
    total_neurons = n_csp + n_freeze - n_overlap;
    
    % Create custom Venn diagram
    hold on;
    
    % Draw circles
    theta = linspace(0, 2*pi, 100);
    r = 0.8;
    x1 = r * cos(theta) - 0.4;
    y1 = r * sin(theta);
    x2 = r * cos(theta) + 0.4;
    y2 = r * sin(theta);
    
    fill(x1, y1, [1 0.8 0.8], 'FaceAlpha', 0.5);  % Light red for CSp
    fill(x2, y2, [0.8 0.8 1], 'FaceAlpha', 0.5);  % Light blue for freeze
    
    % Add labels
    text(-0.7, 0, sprintf('CSp\n(%d)', n_csp - n_overlap), 'HorizontalAlignment', 'center');
    text(0.7, 0, sprintf('Freeze\n(%d)', n_freeze - n_overlap), 'HorizontalAlignment', 'center');
    text(0, 0.2, sprintf('Overlap\n(%d)', n_overlap), 'HorizontalAlignment', 'center');
    
    % Set subtitle
    title(subtitle_text);
    
    % Add percentages
    text(-0.7, -1.1, sprintf('%.1f%%', 100 * (n_csp - n_overlap) / total_neurons), 'HorizontalAlignment', 'center');
    text(0.7, -1.1, sprintf('%.1f%%', 100 * (n_freeze - n_overlap) / total_neurons), 'HorizontalAlignment', 'center');
    text(0, -1.1, sprintf('%.1f%%', 100 * n_overlap / total_neurons), 'HorizontalAlignment', 'center');
    text(0, -1.3, sprintf('Total neurons: %d', total_neurons), 'HorizontalAlignment', 'center');
    
    % Adjust subplot properties
    axis equal;
    axis off;
    
    % Print results to console
    fprintf('\n%s:\n', subtitle_text);
    fprintf('Total neurons in this category: %d\n', total_neurons);
    fprintf('Neurons modulated by CSp only: %d (%.1f%%)\n', n_csp - n_overlap, 100 * (n_csp - n_overlap) / total_neurons);
    fprintf('Neurons modulated by Freeze only: %d (%.1f%%)\n', n_freeze - n_overlap, 100 * (n_freeze - n_overlap) / total_neurons);
    fprintf('Neurons modulated by both CSp and Freeze: %d (%.1f%%)\n', n_overlap, 100 * n_overlap / total_neurons);
end