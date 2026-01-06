function [mask, cluster_stats] = photometry_cluster_stats(mat1, mat2, is_paired, n_perm, time_vec)
% Performs cluster-based permutation testing and plots results.
%
% Inputs:
%    mat1, mat2 : [Animals x Time] matrices
%    is_paired  : Boolean (true for paired/within-subject, false for independent)
%    n_perm     : Number of permutations (e.g., 1000)
%    time_vec   : (Optional) [1 x Time] vector of timestamps    

% Get dimensions
    [n1, n_time] = size(mat1);
    n2 = size(mat2, 1);

    % --- 1. HANDLE TIME VECTOR ---
    if nargin < 5 || isempty(time_vec)
        time_vec = 1:n_time;
        xlab = 'Sample Number';
    else
        xlab = 'Time (s)';
    end

    % --- 2. STATISTICAL TESTING ---
    if is_paired
        if n1 ~= n2, error('For paired tests, matrices must be the same size.'); end
        [~, ~, ~, stats] = ttest(mat1, mat2);
        thresh = tinv(0.975, n1 - 1);
        diff_mat = mat1 - mat2; 
    else
        [~, ~, ~, stats] = ttest2(mat1, mat2);
        thresh = tinv(0.975, n1 + n2 - 2);
        combined_data = [mat1; mat2];
    end
    obs_t = stats.tstat;

    % Find observed clusters
    obs_clusters = find_clusters_internal(obs_t, thresh);

    % --- 3. PERMUTATION LOOP ---
    max_cluster_masses = zeros(1, n_perm);
    fprintf('Running %d permutations...\n', n_perm);
    
    for i = 1:n_perm
        if is_paired
            flip_vector = sign(randn(n1, 1)); 
            t_shuff = mean(diff_mat .* flip_vector) ./ (std(diff_mat .* flip_vector) / sqrt(n1));
        else
            perm_idx = randperm(n1 + n2);
            [~, ~, ~, s_perm] = ttest2(combined_data(perm_idx(1:n1), :), combined_data(perm_idx(n1+1:end), :));
            t_shuff = s_perm.tstat;
        end
        
        perm_clusters = find_clusters_internal(t_shuff, thresh);
        if ~isempty(perm_clusters)
            max_cluster_masses(i) = max([perm_clusters.mass]);
        end
    end

    % --- 4. DETERMINE SIGNIFICANCE & BUILD TABLE ---
    mask = zeros(1, n_time);
    n_found = length(obs_clusters);
    
    % Initialize table columns
    T_start = zeros(n_found, 1); T_end = zeros(n_found, 1);
    P_vals = zeros(n_found, 1); Is_Sig = false(n_found, 1);

    for c = 1:n_found
        p = mean(max_cluster_masses >= obs_clusters(c).mass);
        idx = obs_clusters(c).indices;
        T_start(c) = time_vec(idx(1));
        T_end(c) = time_vec(idx(end));
        P_vals(c) = p;
        if p < 0.05
            mask(idx) = 1;
            Is_Sig(c) = true;
        end
    end
    
    cluster_stats = table(T_start, T_end, (T_end - T_start), P_vals, Is_Sig, ...
        'VariableNames', {'StartTime', 'EndTime', 'Duration', 'P_Value', 'IsSignificant'});

    % --- 5. PLOTTING ---
    m1 = mean(mat1, 1); m2 = mean(mat2, 1);
    sem1 = std(mat1, 0, 1)/sqrt(n1); sem2 = std(mat2, 0, 1)/sqrt(n2);

    figure('Color', 'w'); hold on;
    
    % Get Y-limits for patches
    yl = [min([m1-sem1, m2-sem2]), max([m1+sem1, m2+sem2])];
    yl = [yl(1) - abs(yl(1)*0.1), yl(2) + abs(yl(2)*0.1)]; % Add 10% padding
    
    if any(mask)
        diff_mask = [0, mask, 0];
        starts = find(diff(diff_mask) == 1);
        ends = find(diff(diff_mask) == -1) - 1;
        for k = 1:length(starts)
            patch([time_vec(starts(k)) time_vec(ends(k)) time_vec(ends(k)) time_vec(starts(k))], ...
                  [yl(1) yl(1) yl(2) yl(2)], [0.9 0.9 0.9], 'EdgeColor', 'none', 'HandleVisibility', 'off');
        end
    end
    
    fill([time_vec, fliplr(time_vec)], [m1+sem1, fliplr(m1-sem1)], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    fill([time_vec, fliplr(time_vec)], [m2+sem2, fliplr(m2-sem2)], 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    plot(time_vec, m1, 'r', 'LineWidth', 1.5);
    plot(time_vec, m2, 'b', 'LineWidth', 1.5);
    
    xlabel(xlab); ylabel('\DeltaF/F');
    if is_paired, type_str = 'Paired'; else, type_str = 'Independent'; end
    title(['Cluster-based Permutation Test: ', type_str]);
    grid on; box off; ylim(yl);
end

function clusters = find_clusters_internal(t_stats, thresh)
    binary_map = abs(t_stats) > thresh;
    cc = bwconncomp(binary_map);
    clusters = struct('indices', {}, 'mass', {});
    for i = 1:cc.NumObjects
        idx = cc.PixelIdxList{i};
        clusters(i).indices = idx;
        clusters(i).mass = sum(abs(t_stats(idx)));
    end
end