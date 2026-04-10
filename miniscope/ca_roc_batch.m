% auROC calcium analysis - BATCH VERSION
% ZZ 05/19/21, updated 4/7/2026
% ROC and single unit classifier
% as implemented in Kingsbury...Hong (2020) Neuron
%
% DIRECTORY STRUCTURE EXPECTED:
%   root_dir/
%     ZZXXX_DX/
%       ZZXXX_DX_analyzed/
%         Behavior.mat
%       cleaned_cnmf_data.mat   (preferred, loads 'finalC')
%         OR minian_data_cnmf*.mat  (fallback, loads 'Cdata')
%       frtslu.mat
%
% BEHAVIORAL VECTORS LOADED DYNAMICALLY FROM:
%   Behavior.Freezing.Vector
%   Behavior.Temporal.[field].Vector         (all fields)
%   Behavior.Intersect.TemBeh.[field].Vector (all fields)

%% SETUP
root_dir = uigetdir([], 'Select root directory containing session folders');
if root_dir == 0; error('No directory selected.'); end

save_dir = uigetdir([], 'Select directory to save batch output');
if save_dir == 0; error('No save directory selected.'); end

perm      = 1000;   % number of circular shuffle permutations
n_samples = 100;    % number of points to sample along each ROC curve

use_C_sig = 0; % if false, uses S (deconvolved)

% Collect valid session subdirectories
all_entries  = dir(root_dir);
session_dirs = all_entries([all_entries.isdir] & ...
               ~strcmp({all_entries.name}, '.') & ...
               ~strcmp({all_entries.name}, '..'));

if isempty(session_dirs)
    error('No subdirectories found in %s', root_dir);
end

fprintf('Found %d session folder(s).\n', length(session_dirs));

all_results = struct();
warning('off', 'MATLAB:colon:nonIntegerIndex');

%% BATCH LOOP
for i_session = 1:length(session_dirs)

    sess_name = session_dirs(i_session).name;
    sess_path = fullfile(root_dir, sess_name);
    fprintf('\n========== [%d/%d] %s ==========\n', ...
            i_session, length(session_dirs), sess_name);

    try

        % ----------------------------------------------------------------
        %  1. LOAD BEHAVIOR
        % ----------------------------------------------------------------
        analyzed_candidates = dir(fullfile(sess_path, '*_analyzed'));
        analyzed_candidates = analyzed_candidates([analyzed_candidates.isdir]);
        if isempty(analyzed_candidates)
            warning('No *_analyzed folder in %s — skipping.', sess_name);
            continue
        end
        analyzed_path = fullfile(sess_path, analyzed_candidates(1).name);
        beh_file      = fullfile(analyzed_path, 'Behavior.mat');
        if ~exist(beh_file, 'file')
            warning('Behavior.mat missing in %s — skipping.', analyzed_path);
            continue
        end
        beh_data = load(beh_file, 'Behavior');
        Behavior = beh_data.Behavior;

        % ----------------------------------------------------------------
        %  2. BUILD EVENT VECTOR LIST DYNAMICALLY
        % ----------------------------------------------------------------
        event_vec_names = {};
        event_vectors   = [];   % will become [n_events x n_frames]

        % --- Behavior.Freezing.Vector ---
        if isfield(Behavior, 'Freezing') && isfield(Behavior.Freezing, 'Vector')
            vec = double(Behavior.Freezing.Vector(:)');
            vec = vec(2:end);                          % drop first frame (consistent with original)
            event_vec_names{end+1} = 'Freezing';
            event_vectors(end+1, 1:length(vec)) = vec;
        end

        % --- Behavior.Temporal.[field].Vector ---
        if isfield(Behavior, 'Temporal')
            t_fields = fieldnames(Behavior.Temporal);
            for i_f = 1:length(t_fields)
                fname = t_fields{i_f};
                if isfield(Behavior.Temporal.(fname), 'Vector')
                    vec = double(Behavior.Temporal.(fname).Vector(:)');
                    vec = vec(2:end);
                    event_vec_names{end+1} = fname;
                    event_vectors(end+1, 1:length(vec)) = vec;
                end
            end
        end

        % --- Post-CS vectors: 100 frames (5 s at 20 Hz) after each CS offset ---
        % Built from whichever of csp / csm were already loaded above
        post_cs_targets = {'csp', 'csm'};
        for i_t = 1:length(post_cs_targets)
            cs_name = post_cs_targets{i_t};
            cs_idx  = find(strcmp(event_vec_names, cs_name), 1);
            if ~isempty(cs_idx)
                cs_vec   = event_vectors(cs_idx, :);
                n_frames = length(cs_vec);
                post_vec = zeros(1, n_frames);
                % diff on [cs_vec 0] gives -1 at the last frame of each CS bout
                offsets  = find(diff([cs_vec, 0]) == -1);
                for i_off = 1:length(offsets)
                    start_f = offsets(i_off) + 1;
                    end_f   = min(offsets(i_off) + 100, n_frames);
                    if start_f <= n_frames
                        post_vec(start_f:end_f) = 1;
                    end
                end
                label = ['post_' cs_name];
                event_vec_names{end+1} = label;
                event_vectors(end+1, 1:n_frames) = post_vec;
            end
        end

        % --- Behavior.Intersect.TemBeh.[csp|csm].Freezing.BehInEventVector ---
        beh_in_event_targets = {
            'csp', 'csp_Freezing_BehInEvent';
            'csm', 'csm_Freezing_BehInEvent'
        };
        for i_t = 1:size(beh_in_event_targets, 1)
            cs_name  = beh_in_event_targets{i_t, 1};
            ev_label = beh_in_event_targets{i_t, 2};
            if isfield(Behavior, 'Intersect') && ...
               isfield(Behavior.Intersect, 'TemBeh') && ...
               isfield(Behavior.Intersect.TemBeh, cs_name) && ...
               isfield(Behavior.Intersect.TemBeh.(cs_name), 'Freezing') && ...
               isfield(Behavior.Intersect.TemBeh.(cs_name).Freezing, 'BehInEventVector')
                vec = double(Behavior.Intersect.TemBeh.(cs_name).Freezing.BehInEventVector(:)');
                vec = vec(2:end);
                event_vec_names{end+1} = ev_label;
                event_vectors(end+1, 1:length(vec)) = vec;
            end
        end
 
        if isempty(event_vec_names)
            warning('No event vectors found for %s — skipping.', sess_name);
            continue
        end
        fprintf('  Loaded %d event vector(s): %s\n', ...
                length(event_vec_names), strjoin(event_vec_names, ', '));
        % ----------------------------------------------------------------
        %  3. LOAD CALCIUM SIGNAL
        % ----------------------------------------------------------------
        cnmf_clean = fullfile(sess_path, 'cleaned_cnmf_data.mat');
        if exist(cnmf_clean, 'file')
            if use_C_sig
                sig_data = load(cnmf_clean, 'finalC');
                sig = double(sig_data.finalC);
                fprintf('  Signal loaded from cleaned_cnmf_data (finalC): %d neurons\n', size(sig,1));
            else
                sig_data = load(cnmf_clean, 'finalS');
                sig = double(sig_data.finalS);
                fprintf('  Signal loaded from cleaned_cnmf_data (finalS): %d neurons\n', size(sig,1));
            end
        else
            minian_candidates = dir(fullfile(sess_path, 'minian_data_cnmf*.mat'));
            if ~isempty(minian_candidates)
                sig_data = load(fullfile(sess_path, minian_candidates(1).name), 'Cdata');
                sig = double(sig_data.Cdata);
                fprintf('  Signal loaded from %s (Cdata): %d neurons\n', ...
                        minian_candidates(1).name, size(sig,1));
            else
                warning('No calcium signal file found for %s — skipping.', sess_name);
                continue
            end
        end

        % ----------------------------------------------------------------
        %  4. LOAD FRAME LOOKUP TABLE AND ALIGN SIGNAL
        % ----------------------------------------------------------------
        frtslu_file = fullfile(sess_path, 'frtslu.mat');
        if ~exist(frtslu_file, 'file')
            warning('frtslu.mat not found for %s — skipping.', sess_name);
            continue
        end
        frtslu_data = load(frtslu_file, 'frtslu');
        frtslu      = frtslu_data.frtslu;

        % Trim to shortest common length across signal, frtslu, and event vectors
        cutoff = min([size(event_vectors, 2), size(frtslu, 1), size(sig, 2)]);
        sig           = sig(:,          frtslu(1:cutoff, 3));
        event_vectors = event_vectors(:, 1:cutoff);

        % ----------------------------------------------------------------
        %  5. Z-SCORE SIGNAL
        % ----------------------------------------------------------------
        zsig = zscore(sig, 0, 2);
        nn   = size(zsig, 1);
        fprintf('  %d neurons, %d frames after alignment.\n', nn, size(zsig,2));

        % ----------------------------------------------------------------
        %  6. ROC ANALYSIS PER EVENT
        % ----------------------------------------------------------------
        out = struct();

        for i_event = 1:length(event_vec_names)

            ev_name  = event_vec_names{i_event};
            ev_field = matlab.lang.makeValidName(ev_name);   % safe struct fieldname
            fprintf('  ROC: %s ... ', ev_name);

            eventmat = event_vectors(i_event, :);

            if sum(eventmat) == 0
                fprintf('no events, skipping.\n');
                continue
            end

            % --- Real auROCs ---
            roc   = zeros(n_samples, 2, nn);
            auc_n = nan(1, nn);

            for i_n = 1:nn
                % Guard against flat/dead traces
                if var(zsig(i_n,:)) == 0
                    continue
                end
                [x, y, ~, AUC] = perfcurve(eventmat, zsig(i_n,:), 1);
                idx = round(linspace(1, length(x), n_samples));
                roc(:,:,i_n)  = [x(idx), y(idx)];
                auc_n(i_n)    = AUC;
            end

            % --- Permutation null distribution ---
            % parfor parallelizes over permutations (outer, slow dimension)
            % inner neuron loop stays serial — correct structure for parfor
            auc_perm = zeros(nn, perm);

            parfor i_perm = 1:perm
                i_start       = randi([2, length(eventmat)], 1);
                eventmat_shuf = [eventmat(i_start:end), eventmat(1:i_start-1)];
                auc_tmp       = zeros(1, nn);
                for i_n = 1:nn
                    if var(zsig(i_n,:)) == 0; continue; end
                    [~,~,~,AUC]  = perfcurve(eventmat_shuf, zsig(i_n,:), 1);
                    auc_tmp(i_n) = AUC;
                end
                auc_perm(:, i_perm) = auc_tmp';
            end

            % --- Percentile of real auROC vs null ---
            centile = zeros(nn, 1);
            for i_n = 1:nn
                nless         = sum(auc_perm(i_n,:) < auc_n(i_n));
                nequal        = sum(auc_perm(i_n,:) == auc_n(i_n));
                centile(i_n)  = 100 * (nless + 0.5*nequal) / perm;
            end

            n_suppressed = find(centile <= 2.5);
            n_excited    = find(centile >= 97.5);

            frac_excited    = length(n_excited)    / nn;
            frac_suppressed = length(n_suppressed) / nn;
            fprintf('%d excited (%.3f), %d suppressed (%.3f) of %d neurons.\n', ...
                    length(n_excited),    frac_excited, ...
                    length(n_suppressed), frac_suppressed, nn);

            % Store results
            out.(ev_field).event_vec       = eventmat;
            out.(ev_field).n_excited       = n_excited;
            out.(ev_field).n_suppressed    = n_suppressed;
            out.(ev_field).frac_excited    = frac_excited;
            out.(ev_field).frac_suppressed = frac_suppressed;
            out.(ev_field).n_neurons       = nn;
            out.(ev_field).roc             = roc;
            out.(ev_field).auc_neurons     = auc_n;
            out.(ev_field).centile         = centile;  % full distribution — useful downstream
        end

        % ----------------------------------------------------------------
        %  7. SAVE PER-SESSION OUTPUT
        % ----------------------------------------------------------------
        sess_save = fullfile(save_dir, [sess_name '_ca_roc_output.mat']);
        save(sess_save, 'out', 'sig', 'event_vec_names', 'event_vectors', '-v7.3');
        fprintf('  Saved: %s\n', sess_save);

        all_results.(matlab.lang.makeValidName(sess_name)) = out;

    catch ME
        warning('Error processing %s:\n  %s\n  Line %d: %s', ...
                sess_name, ME.message, ME.stack(1).line, ME.stack(1).name);
    end

end

%% SAVE AGGREGATE OUTPUT
batch_save = fullfile(save_dir, 'ca_roc_batch_all.mat');
save(batch_save, 'all_results', '-v7.3');
fprintf('\n\nBatch complete. Aggregate saved to:\n  %s\n', batch_save);
warning('on', 'MATLAB:colon:nonIntegerIndex');