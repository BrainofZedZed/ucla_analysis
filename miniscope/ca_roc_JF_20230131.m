% auROC calcium analysis
% v1 ZZ 05/19/21
% ROC and single unit classifier
% as implemented in Kingsbury...Hong (2020) Neuron

%% SETUP
% Requires parallel computing toolbox

% LOAD INTO WORKSPACE:  
% 1) sig = signal matrix (sigfn, dff, or spkfn)[ref paper uses dff]
% NB: must load into workspace with name 'sig' 
% NB2: sig must be aligned to behavior frames (ie sig(1,2) is the activity 
% of the first neuron at the second behavior frame, sig(1,20) is activity
% at the 20th behavior frame, etc

% 2) for any time-locked event vectors, assign to event_vec vars
% NB: these vectors must be equal length to sig

%% EXPECTED BEHAVIOR
% After loading signal matrix and event vectors, code will perform an area
% under the ROC (auROC) curve analysis for each neuron and each event vector. To
% test significance, a circular shuffle is used to generate a null
% distribution of auROC. Default interpretations are if auROC is > 97.5% of
% shuffled auROCs then cell is excited during event, if auROC is < 2.5% of
% shuffled auROCs then cell is suppressed during event.

% Uncomment plots if wish to visualize ROC curves.

% Progress counter is broken due to stochastic nature of parfor loop.

%% OUTPUT
% Will save .mat file to save_dir with struct 'out'. Struct 'out' contains
% a field for each event_vec, and with each field are the identities of the
% excited and suppressed neurons, along with the ROC stats.

%%
% load Behavior, Behavior_Filter
event_vec1 = [];
event_vec2 = [];
event_vec3 = [];

% list of human legible names for the event vectors
event_vec_names = {'freeze', 'CSp', 'CSm', 'CSp_freeze', 'CSm_freeze'};
% concatenate event vectors
event_vectors = [freeze_vec, csp_vec, csm_vec, csp_frz_vec, csm_frz_vec];

% point to save directory
save_dir = 'C:\Users\Zach\Box\Zach_repo\Projects\Remote memory\Miniscope data\PL_TeA cohort1\batch for behdepot\ZZ087\D29';


%% zscore data
zsig = zscore(sig, 0, 2);  % zscore data to normalize
nn = size(zsig,1);  % Number of Neurons
nf = size(zsig,2);  % Number of Frames

%% generate ROC using matlab func perfcurve
%only take 100 samples to prevent: 1) step functions in ROC curve; 2)
%different sized ROC vectors curves
for i_event = 1:length(event_vec_names)
    disp(['now doing ' event_vec_names{i_event}])
    eventmat = event_vectors(:,i_event);
    
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

        %% plot ROCs to take a look at each one. Comment out if no plot desired
        %  for zz = 1:nn
        %      plot(roc(:,1,zz), roc(:,2,zz));
        %      pause;
        %  end

        %% generate null distribution of auROCs 
        % circularly shuffle event timing and recalculating ROCs
        % this takes a while (note the parfor loop)

        perm = 1000;
        auc_perm = zeros(nn,perm);
        % turn off annoying warning
        warning('off','MATLAB:colon:nonIntegerIndex');

        disp('counter broken with parallel computing and 6/3/2022 zach is too lazy to fix it')
        disp('¯\_(ツ)_/¯ ')
        parfor i_perm = 1:perm
            i_start = randi([2,length(eventmat)],1);
            eventmat_shuf = vertcat(eventmat(i_start:end), eventmat(1:i_start-1));

            for i_n = 1:nn
              [~,~,~,AUC] = perfcurve(eventmat_shuf,zsig(i_n,:),1);
              auc_perm(i_n,i_perm) = AUC;
            end

            % doesn't work with parfor loop
            if rem(i_perm,50)==0
                per_done = i_perm/perm*100;
                disp([num2str(per_done) '% done']);
            end
        end
        % 

        %% compute percentile of real auROCs
        centile = zeros(nn,1);
        for i_n = 1:nn
            nless = sum(auc_perm(i_n,:) < auc_n(i_n));
            nequal = sum(auc_perm(i_n,:) == auc_n(i_n));
            centile(i_n) = 100 * (nless + 0.5*nequal) / size(auc_perm,2);
        end

        n_suppressed = find(centile <= 2.5);
        n_excited = find(centile >= 97.5);

        %% plot sig ROCs to take a look at each one. 
        % Comment out if no plot desired
    %     figure;
    %     for zz = 1:length(n_excited)
    %          plot(roc(:,1,n_excited(zz)), roc(:,2,n_excited(zz)));
    %          title(['excited cell ID #' num2str(n_excited(zz))]);
    %          legend(['AUC = ' num2str(auc_n(n_excited(zz)))]);
    %          ylabel('True Positive Rate')
    %          xlabel('False Positive Rate')
    %          pause;
    %     end
    % 
    %     for zz = 1:length(n_suppressed)
    %          plot(roc(:,1,n_suppressed(zz)), roc(:,2,n_suppressed(zz)));
    %          title(['suppressed cell ID #' num2str(n_suppressed(zz))]);
    %          legend(['AUC = ' num2str(auc_n(n_suppressed(zz)))]);
    %          ylabel('True Positive Rate')
    %          xlabel('False Positive Rate')
    %          pause;
    %     end

        %% visualize histogram of real auROC (red line) vs null distribution
        %% Comment out if desired
        % nsig = length(n_suppressed) + length(n_excited);
        % sigcells = [n_excited; n_suppressed];
        % for zz = 1:nsig
        %     histogram(auc_perm(sigcells(zz),:),50);
        %     xline(auc_n(sigcells(zz)),'r');
        %     title(['histogram of shuffled auROCs - cell ID #' num2str(sigcells(zz))]);
        %     pause;
        %     clf;
        % end

        out.(event_vec_names{i_event}).event_vec = eventmat;
        out.(event_vec_names{i_event}).n_excited = n_excited;
        out.(event_vec_names{i_event}).n_suppressed = n_suppressed;
        out.(event_vec_names{i_event}).roc = roc;
        out.(event_vec_names{i_event}).auc_neurons = auc_n;
    else
        disp('nothing in this event vector. skipping');
    end


end

%% save
save([save_dir '\ca_roc_output.mat'], 'out');