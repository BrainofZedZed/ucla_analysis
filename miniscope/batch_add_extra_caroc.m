% Define the parent directory containing all animal IDs
parent_dir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\good\CSminus removed\ZZ206'; % Replace with actual path

% Get all subdirectories (animal IDs)
animal_dirs = dir(fullfile(parent_dir, 'ZZ*'));
animal_dirs = animal_dirs([animal_dirs.isdir]); % Only keep directories

for i_animal = 1:length(animal_dirs)
    animal_path = fullfile(parent_dir, animal_dirs(i_animal).name);
    
    % Check if ca_roc_output.mat exists in the animal directory
    if exist(fullfile(animal_path, 'ca_roc_output.mat'), 'file')
        disp(['Processing: ', fullfile(animal_path, 'ca_roc_output.mat')]);
        
        % Load the ca_roc_output.mat data
        load(fullfile(animal_path, 'ca_roc_output.mat'));
        
        % Save a copy of the original data with new filename
        save(fullfile(animal_path, 'ca_roc_output_og_v2.mat'), '-v7.3');
        
        % Get all session directories for this animal
        session_dirs = dir(fullfile(animal_path, 'ZZ*'));
        session_dirs = session_dirs([session_dirs.isdir]); % Only keep directories
        
        % Find the session directory that ends with _analyzed
        analyzed_idx = find(endsWith({session_dirs.name}, '_analyzed'));
        if ~isempty(analyzed_idx)
            session_path = fullfile(animal_path, session_dirs(analyzed_idx(1)).name);
            behavior_path = fullfile(session_path, 'Behavior.mat');
            
            if exist(behavior_path, 'file')
                load(behavior_path, 'Behavior');
                % Override freezing_vec with Behavior.Freezing.Vector
                freeze_vec = Behavior.Freezing.Vector;
            else
                warning(['Behavior.mat not found in: ', behavior_path]);
                continue;
            end
        else
            warning(['No _analyzed directory found in: ', animal_path]);
            continue;
        end
        
        % Calculate vectors
        tone_freeze_vec = csp_vec & freeze_vec;  % Freezing during tone
        tone_nonfreeze_vec = csp_vec & ~freeze_vec;  % Non-freezing during tone
        nontone_freeze_vec = ~csp_vec & freeze_vec;  % Freezing outside tone
        
        if exist('cutoff','var') && cutoff == 0
            cutoff = length(sig);
        end

        if exist('cutoff', 'var') && cutoff > 0
            tone_freeze_vec = tone_freeze_vec(1:cutoff);
            tone_nonfreeze_vec = tone_nonfreeze_vec(1:cutoff);
            nontone_freeze_vec = nontone_freeze_vec(1:cutoff);
        end

        new_event_vecs = [tone_freeze_vec; tone_nonfreeze_vec; nontone_freeze_vec];
        new_event_vec_names = {'tone_freeze', 'tone_nonfreeze', 'nontone_freeze'};
        event_vectors = [event_vectors; tone_freeze_vec; tone_nonfreeze_vec; nontone_freeze_vec];
        event_vec_names = [event_vec_names, "tone_freeze", "tone_nonfreeze", "nontone_freeze"];

        zsig = zscore(sig, 0, 2);  % zscore data to normalize
        nn = size(zsig,1);  % Number of Neurons
        nf = size(zsig,2);  % Number of Frames

        %% generate ROC using matlab func perfcurve
        for i_event = 1:length(new_event_vec_names)
            disp(['now doing ' new_event_vec_names{i_event}])
            eventmat = new_event_vecs(i_event,:);
            
            if sum(eventmat) ~= 0  % check to see if there's anything to align to, skip if not 
                % load event vec
                roc = zeros(100,2,nn);
                auc_n = zeros(1,nn);
                x = [];
                y = [];

                for i_n = 1:nn
                    [x,y,~,AUC] = perfcurve(eventmat,zsig(i_n,:),1);    
                    x_samples = x(1:length(x)/100:end);
                    y_samples = y(1:length(y)/100:end);
                    roc(:,:,i_n) = [x_samples,y_samples];
                    auc_n(i_n) = AUC;
                end

                %% generate null distribution of auROCs 
                % circularly shuffle event timing and recalculating ROCs
                perm = 1000;
                auc_perm = zeros(nn,perm);
                warning('off','MATLAB:colon:nonIntegerIndex');

                disp('Starting permutations...')
                parfor i_perm = 1:perm
                    i_start = randi([2,length(eventmat)],1);
                    eventmat_shuf = horzcat(eventmat(i_start:end), eventmat(1:i_start-1));

                    for i_n = 1:nn
                      [~,~,~,AUC] = perfcurve(eventmat_shuf,zsig(i_n,:),1);
                      auc_perm(i_n,i_perm) = AUC;
                    end

                    if rem(i_perm,50)==0
                        per_done = i_perm/perm*100;
                        disp([num2str(per_done) '% done']);
                    end
                end

                %% compute percentile of real auROCs
                centile = zeros(nn,1);
                for i_n = 1:nn
                    nless = sum(auc_perm(i_n,:) < auc_n(i_n));
                    nequal = sum(auc_perm(i_n,:) == auc_n(i_n));
                    centile(i_n) = 100 * (nless + 0.5*nequal) / size(auc_perm,2);
                end

                n_suppressed = find(centile <= 2.5);
                n_excited = find(centile >= 97.5);

                out.(new_event_vec_names{i_event}).event_vec = eventmat;
                out.(new_event_vec_names{i_event}).n_excited = n_excited;
                out.(new_event_vec_names{i_event}).n_suppressed = n_suppressed;
                out.(new_event_vec_names{i_event}).roc = roc;
                out.(new_event_vec_names{i_event}).auc_neurons = auc_n;
            else
                disp('nothing in this event vector. skipping');
            end
        end

        % Save the results back to the same file
        save(fullfile(animal_path, 'ca_roc_output.mat'), "out", "tone_freeze_vec", "tone_nonfreeze_vec", "nontone_freeze_vec", "event_vectors", "event_vec_names", '-append');
        
        disp(['Finished processing: ', fullfile(animal_path, 'ca_roc_output.mat')]);
        
        % Clear all variables except those needed for the loop
        clearvars('-except', 'parent_dir', 'animal_dirs', 'i_animal');
        
    else
        disp(['ca_roc_output.mat not found in: ', animal_path]);
    end
end

disp('Batch processing complete.');