%% Fiber Photometry posthoc analysis
% to be used in conjunction with BehDEPOT output and FCXD.
% Intended to be used to examine fiber photometry response to event bouts
% of the same length. NB -- events must be same (approximate) length (eg
% tones). Events of different durations (freezing, platform time) will be
% inaccurate. 
% Run script and point to grandparent folder, which holds indiviudal
% subject folders. Within each subject folder should be the experiment
% file, the BehDEPOT analysis output, and the TDT recording folder. 
%% To use:
% Choosing which analyses / plots to perform.
% single animals data (including signal (sig),
% signal-aligned-to-behavior-frames (bhsig), behavior bouts (bouts), and
% behavior vector (beh_vec) will be saved.
% Batch output of AUC / peak values will also be saved.
%%
clear;

%% USER DEFINED PARAMS FOR SIGNAL ANALYSIS
P2.fp_ds_factor = 10; % factor by which to downsample FP recording (eg 10 indicates 1:10:end)
P2.trange_peri_bout = [5 5]; % [sec_before, sec_after] event to visualize
P2.baseline_per = [-2 -0]; % baseline period relative to epoc onset for normalizing

P2.remove_last_trials = 0; % true if remove last trial from analysis (helpful for looking at dynamics long after cues end)
P2.t0_as_zero = false; % true to set signal values at t0 (tone onset) as 0
P2.reward_t = 5; % (seconds) time after reward initiation to visualize signal

bouts_name = 'CSm'; % char name of bouts (for labeling and saving)(must be exactly as in BehDEPOT)
%% REGISTER TDT TTL AND BEHDEPOT CUE NAME
% identify PC trigger names with BehDEPOT events as 1x2 cell. first is name
% of TDT input (eg PC0_, PC2_, PC3_, etc) and second is name of BehDEPOT
% event (eg 'tone', 'CSp')
% NB: these must be the exact names and spelling of
P2.cue = {'PC0_', 'CSp'};

%% USER DEFINED PLOTTING & ANALYSIS
P2.do_lineplot = true;
P2.do_heatmap = true;
P2.do_vectorplot = false; % DOESNT WORK

P2.do_peak = true;
P2.do_auc = true;
P2.save_analysis = true; % true if save details of analysis
P2.skip_prev_analysis = false; % true if not redo previous analysis

% PMA specific analyses
P2.do_platform_heatmap = false;
P2.do_auc_shocktrials = false;
P2.do_platform = false;
P2.remove_nonshock_tones = 0; % applies only to vector plot for PMA, removes first three tones from visualization 
P2.do_reward = false; % averages over reward frames % DOESNT WORK

%% USER DEFINED BOUTS FOR ANALYSIS


%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
P2.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P2.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
cd(string(P2.video_directory));
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
    current_structure = directory_contents(i);
    if current_structure.isdir
        ii = ii + 1;
        P2.video_folder_list(ii) = string(current_structure.name);
        disp([num2str(i) ' directory loaded'])
    end
end

%% initialize vars
ct = 0;
auc_fc_abs = {};
auc_names_fc = {'ID','0-10s auc', '10-20s auc', '20-30s auc', '0-30s auc', '7-12s auc (shock)'};
peaks = {};
peak_names = {'ID','peak value', 'latency'};


%% loop through folders
for j = 1:length(P2.video_folder_list)
    % clear from previous round
    clearvars -except 'P2' 'ct' 'auc_fc' 'auc_names_fc' 'peaks_shock_all' 'peaks_nonshock_all' 'peak_names' 'j' 'auc_shock_all' 'auc_nonshock_all' 'auc_shock_names' ' peaks_baseline_all' 'auc_baseline_all' 'peaks' 'auc_fc_ind' 'auc_fc_ind_abs' 'auc_fc_abs' 'bouts_name';
    % Initialize 
    ct = ct+1; % increase count
    current_video = P2.video_folder_list(j);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   

    basedir = pwd;

    if P2.skip_prev_analysis
        if ~isempty(dir('*fibpho_analysis*'))
            continue
        end
    end
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    load('Params.mat');
    cd(basedir);
    exp_file = dir('*-*-*_*-*-*.mat');
    load(exp_file.name); % load experiment file


    bouts = Behavior.Temporal.(bouts_name).Bouts;

    if P2.remove_last_trials
        bouts = bouts(1:end-1,:);
    end

    %% load stuff from current folder
    basedir = pwd;
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    load('Params.mat');
    cd(basedir);

    id = exp_ID; % load ID
    numFrames = Params.numFrames;
    %% load TDT data
    % get list of folders
    files = dir(basedir);
    dirFlags = [files.isdir];
    folders = files(dirFlags);
    subfolderNames = {folders.name};

    % look for two 6-digit patterns to identify TDT folder
    pat = digitsPattern(6);
    for i = 1:length(subfolderNames)
        m = extract(subfolderNames{i}, pat);
        if length(m) == 2
            tdt_f = i;
        end
    end
    tdt_dir = [folders(tdt_f).folder '\' folders(tdt_f).name];
    data = TDTbin2mat(tdt_dir, 'TYPE', {'epocs', 'scalars', 'streams'});

    %% create frame lookup translating FP to behavior frames
    beh2fp = beh2FPfrlu(cueframes, data, P2.cue, numFrames);

    %% load, clean, transfor, align FP data
    % output is zscore based on overall signal

    % load 465 from 405 signal and downsample
    s465 = data.streams.x465A.data;
    s405 = data.streams.x405A.data;

    % downsample
    s465 = s465(1:P2.fp_ds_factor:end);
    s405 = s405(1:P2.fp_ds_factor:end);
    beh2fp = round(beh2fp / P2.fp_ds_factor);

    % Fitting 405 channel onto 465 channel to detrend signal bleaching
    % Algorithm sourced from Tom Davidson's Github:
    % https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m
    bls_all = polyfit(s405(1:end), s465(1:end), 1);
    Y_fit_all = bls_all(1) .* s405 + bls_all(2);
    sig = s465 - Y_fit_all;

    beh2fp = hardCodebeh2fpClean(id, beh2fp);
    bhsig = sig(beh2fp);

    %% Calculate signal over epocs
    % Create the time vector for each stream store

    beh_fps = Params.Video.frameRate;
    % hardcode adjustment for 50fps lag
    if beh_fps == 50
        beh_fps = 49.97;
    end

        ts1 = round(bouts(:,1) - (P2.trange_peri_bout(1)*beh_fps));
        ts2 = round(bouts(:,2) + (P2.trange_peri_bout(2)*beh_fps));
    
        % enforce same length
        tmp_dur = ts2-ts1;
        beh_ts = [ts1, ts1+min(tmp_dur)];
    
        % get fp frames corresponding to beh frames, enforce same length
        if P2.remove_last_trials
            beh_ts = beh_ts(1:end-1,:);
            bouts = bouts(1:end-1,:);
        end
        fp_ts = round(beh2fp(beh_ts));
        tmp_dur = fp_ts(:,2) - fp_ts(:,1);
        fp_ts = [fp_ts(:,1), fp_ts(:,1)+min(tmp_dur)];
        epoc_length = min(tmp_dur)+1;
    
        % get baseline frames, enforce same length
        bl_beh = round([beh_ts(:,1)+(P2.baseline_per(1)*beh_fps), beh_ts(:,1)+(P2.baseline_per(2)*beh_fps)]);
        bl_fp = beh2fp(bl_beh);
        tmp_dur = bl_fp(:,2) - bl_fp(:,1);
        bl_fp = [bl_fp(:,1), bl_fp(:,1)+min(tmp_dur)];
        bl_length = min(tmp_dur);
    
    
        % get signal for all trials and zscore
        zall = zeros(size(bouts,1),epoc_length);
    
        % zscore
        for i = 1:size(zall,1)
            zb = mean(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period mean
            zsd = std(sig(bl_fp(i,1):bl_fp(i,2))); % baseline period stdev
            zall(i,:)=(sig(fp_ts(i,1):fp_ts(i,2)) - zb)/zsd; % Z score per bin
        end




        % get pre fp frame length for plotting
        pre_dur = beh2fp(bouts(1,1))- fp_ts(1,1);
        post_dur = beh2fp(beh_ts(1,2)) - beh2fp(bouts(1,2));
        
    
        % get fp fps
        fp_fps = data.streams.x465A.fs;
        fp_fps = round(fp_fps/P2.fp_ds_factor);
    
        % set t0 to 0
        if P2.t0_as_zero
            t0 = round(P2.trange_peri_bout(1)*fp_fps);
            for i = 1:size(zall,1)
                tmp_smth = smooth(zall(i,:),round(fp_fps/4));
                zall(i,:) = zall(i,:)-tmp_smth(t0);
            end
        end
        %% specific analyses
          %% calculate value and latency of peak average score
        if P2.do_peak
            t0 = round(P2.trange_peri_bout(1)*fp_fps);
            first_5s = zall(:,t0:(t0+round((5*fp_fps))));
            [peak, latency] = max(mean(first_5s));
            %[peak, latency] = max(first_5s,[],2);
            %peak = mean(peak);
            latency = mean(latency);
            latency = latency/fp_fps;
            peaks{ct,1} = exp_ID;
            peaks{ct,2} = peak;
            peaks{ct,3} = latency;

        end
    
        %% calculate auc 
    
        if P2.do_auc
            t0 = round(P2.trange_peri_bout(1)*fp_fps);
            meanz = mean(zall);
            auc_offset = mean(meanz(1:t0));
            meanz = meanz-auc_offset;
            auc_fc_abs{ct,1} = exp_ID;
            auc_fc_abs{ct,2} = trapz(abs(meanz(t0:t0+(round(10*fp_fps)))));

            try
                auc_fc_abs{ct,3} = trapz(abs(meanz(t0+round(10*fp_fps):t0+round(20*fp_fps))));
            catch
                auc_fc_abs{ct,3} = '';
            end

            try
                auc_fc_abs{ct,4} = trapz(abs(meanz(t0+round(20*fp_fps):t0+round(30*fp_fps))));
            catch
                auc_fc_abs{ct,4} = '';
            end

            try
                auc_fc_abs{ct,5} = trapz(abs(meanz(t0:t0+round(30*fp_fps))));
            catch
                auc_fc_abs{ct,5} = '';
            end


            % AUC calculated over indiviudual trials, abs
            auc_fc_ind_abs{ct,1} = exp_ID;
            auc_fc_ind_abs{ct,2} = trapz(abs(zall(:,t0:t0+(round(10*fp_fps)))),2);
            auc_fc_ind_abs{ct,2} = mean(auc_fc_ind_abs{ct,2});

            try
                auc_fc_ind_abs{ct,3} = trapz(abs(zall(:,t0+round(10*fp_fps):t0+round(20*fp_fps))),2);
                auc_fc_ind_abs{ct,3} = mean(auc_fc_ind_abs{ct,3});

            catch
                auc_fc_ind_abs{ct,3} = '';
            end

            try
                auc_fc_ind_abs{ct,4} = trapz(abs(zall(:,t0+round(20*fp_fps):t0+round(30*fp_fps))),2);
                auc_fc_ind_abs{ct,4} = mean(auc_fc_ind_abs{ct,4});

            catch
                auc_fc_ind_abs{ct,4} = '';
            end

            try
                auc_fc_ind_abs{ct,5} = trapz(abs(zall(:,t0:t0+round(30*fp_fps))),2);
                auc_fc_ind_abs{ct,5} = mean(auc_fc_ind_abs{ct,5});
            catch
                auc_fc_ind_abs{ct,5} = '';
            end

           % AUC calculated over indiviudual trials, not abs
            auc_fc_ind{ct,1} = exp_ID;
            auc_fc_ind{ct,2} = trapz(zall(:,t0:t0+(round(10*fp_fps))),2);
            auc_fc_ind{ct,2} = mean(auc_fc_ind{ct,2});

            try
                auc_fc_ind{ct,3} = trapz(zall(:,t0+round(10*fp_fps):t0+round(20*fp_fps)),2);
                auc_fc_ind{ct,3} = mean(auc_fc_ind{ct,3});

            catch
                auc_fc_ind{ct,3} = '';
            end

            try
                auc_fc_ind{ct,4} = trapz(zall(:,t0+round(20*fp_fps):t0+round(30*fp_fps)),2);
                auc_fc_ind{ct,4} = mean(auc_fc_ind{ct,4});

            catch
                auc_fc_ind{ct,4} = '';
            end

            try
                auc_fc_ind{ct,5} = trapz(zall(:,t0:t0+round(30*fp_fps)),2);
                auc_fc_ind{ct,5} = mean(auc_fc_ind{ct,5});
            catch
                auc_fc_ind{ct,5} = '';
            end


                
        end
%%
        if P2.do_heatmap
            % Plot heat map

            fig = figure;
            imagesc(zall)
            colormap('parula'); 
            c1 = colorbar; 
            title(sprintf('Z-Score Heat Map, %d Trials, %s%s', size(bouts,1), bouts_name));
            ylabel('Trials', 'FontSize', 12);
            hold on;
            xline(pre_dur, ':', 'LineWidth', 2);
            xline(epoc_length-post_dur, ':', 'LineWidth', 2);
    
            % get FP fps (downsample adjusted) to label xaxis
            xlabel(sprintf('frames (@ %d frames per second)', fp_fps));
    
            filename = sprintf(['%s%s' '_' '%s%s'], exp_ID, bouts_name);
            filename = [filename 'HeatMap'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;

            % custom PMA graph. Overlays detection of shock delivery.
            % Requires 'on_platform_shock' loaded from experiment file,
            % from plotPeriTones_batch script
            if exist('on_platform_shock','var')
                fig = figure;
                imagesc(zall, [-5 5])
                colormap('parula'); 
                c1 = colorbar; 
                title(sprintf('Z-Score Heat Map, %d Trials, %s%s', size(bouts,1), bouts_name));
                ylabel('Trials', 'FontSize', 12);
                hold on;
                xline(pre_dur, ':', 'LineWidth', 2);
                xline(epoc_length-post_dur, ':', 'LineWidth', 2);
        
                % add text
                for s = 1:length(on_platform_shock)
                    if on_platform_shock(s)
                        text(0,s,'P-NS', 'FontSize',6);
                    else
                        text(0,s,'NP-S', 'FontSize',6);
                    end
                end
                % get FP fps (downsample adjusted) to label xaxis   
                xlabel(sprintf('frames (@ %d frames per second)', fp_fps));
        
                filename = sprintf(['%s%s' '_' '%s%s'], exp_ID, bouts_name);
                filename = [filename 'HeatMap_shockIndicator'];
                filename = [basedir '\' filename];
                saveas(fig, filename);
                close;
                clear fig;
            end
        end
   %%     
        if P2.do_platform_heatmap
            %% platform entrie
            pf_time = 4; % seconds after platform entry to visualize
            pre_pf_time = 2; % seconds before platform to visualize
            pre_pf_baseline = 2; % seconds before pre_pf to use as baseline
            fps = 50;
            
            pf_bout_dur = Behavior.Spatial.platform.Bouts(:,2) - Behavior.Spatial.platform.Bouts(:,1);
            pf_idx = find(pf_bout_dur>(pf_time*fps));
            pf_entry = Behavior.Spatial.platform.Bouts(:,1);
            total_length = (pf_time+pre_pf_time)*fps+1;

            % test to see if there's platform entries. exit if not
            if isempty(pf_idx)
                disp('no platform entries. skipping platform heatmap');
            else
    
    
                % test if first or end point will exceed recording limit
                omega = pf_entry(pf_idx(end)) + total_length;
                if omega > length(bhsig)
                    pf_idx = pf_idx(1:end-1);
                end
    
                alpha = pf_entry(pf_idx(1)) - (pre_pf_time+pre_pf_baseline)*fps;
                if alpha < 1
                    pf_idx = pf_idx(2:end);
                end
                % get signal for all trials and zscore
                zall2 = zeros(size(pf_idx,1),total_length);
                
                for i = 1:size(zall2,1)
                    bl = bhsig(pf_entry(pf_idx(i)) - ((pre_pf_time+pre_pf_baseline)*fps) : pf_entry(pf_idx(i)) - ((pre_pf_baseline)*fps));
                    zb = mean(bl); % baseline period mean
                    zsd = std(bl); % baseline period stdev
                    s1 = pf_entry(pf_idx(i)) - (pre_pf_time*fps);
                    s2 = pf_entry(pf_idx(i)) + (pf_time*fps);
                    zall2(i,:)=((bhsig(s1:s2)- zb) / zsd);
                end
                
                % make heatmap
                fig = figure;
                imagesc(zall2, [-5 5])
                colormap('parula'); 
                c1 = colorbar; 
                title(sprintf('Z-Score Heat Map, %d Platform Entires at dashed line', size(pf_idx,1)));
                ylabel('Entires', 'FontSize', 12);
                hold on;
                xline(pre_pf_time*fps, ':', 'LineWidth', 2);
                xlabel(sprintf('frames (@ %d frames per second)', fps));
                
                filename = sprintf(['%s%s' '_'], exp_ID);
                filename = [filename 'PlatformEntires_HeatMap'];
                filename = [basedir '\' filename];
                saveas(fig, filename);
                close;
                clear fig;
    
                %% platform exits
                pf_time = 4; % seconds after platform entry to visualize
                pre_pf_time = 2; % seconds before platform to visualize
                pre_pf_baseline = 2; % seconds before pre_pf to use as baseline
                fps = 50;
                
                pf_bout_dur = Behavior.Spatial.platform.Bouts(:,2) - Behavior.Spatial.platform.Bouts(:,1);
                pf_idx = find(pf_bout_dur>(pf_time*fps));
                pf_exit = Behavior.Spatial.platform.Bouts(:,2);
                total_length = (pf_time+abs(pre_pf_time))*fps+1;
                
                % test if first or end point will exceed recording limit
                omega = pf_exit(pf_idx(end)) + total_length;
                if omega > length(bhsig)
                    pf_idx = pf_idx(1:end-1);
                end
    
                alpha = pf_exit(pf_idx(1)) - (pre_pf_time+pre_pf_baseline)*fps;
                if alpha < 1
                    pf_idx = pf_idx(2:end);
                end
                
                % get signal for all trials and zscore
                zall3 = zeros(size(pf_idx,1),total_length);
                
                
                for i = 1:size(zall3,1)
                    bl = bhsig(pf_exit(pf_idx(i)) - ((pre_pf_time+pre_pf_baseline)*fps) : pf_exit(pf_idx(i)) - ((pre_pf_baseline)*fps));
                    zb = mean(bl); % baseline period mean
                    zsd = std(bl); % baseline period stdev
                    s1 = pf_exit(pf_idx(i)) - (pre_pf_time*fps);
                    s2 = pf_exit(pf_idx(i)) + (pf_time*fps);
                    zall3(i,:)=((bhsig(s1:s2)- zb) / zsd);
                end
                
                % make heatmap
                fig = figure;
                imagesc(zall, [-5 5])
                colormap('parula'); 
                c1 = colorbar; 
                title(sprintf('Z-Score Heat Map, %d Platform EXITS at dashed line', size(pf_idx,1)));
                ylabel('Exits', 'FontSize', 12);
                hold on;
                xline(pre_pf_time*fps, ':', 'LineWidth', 2);
                xlabel(sprintf('frames (@ %d frames per second)', fps));
                
                filename = sprintf(['%s%s' '_'], exp_ID);
                filename = [filename 'PlatformExits_HeatMap'];
                filename = [basedir '\' filename];
                saveas(fig, filename);
                close;
                clear fig;
            end
        end

        %% line plot
        if P2.do_lineplot
            % make overlay signal
            % copied from TDT ocmmunity example EpocAveragingDR
    
            % Subtract DC offset to get signals on top of one another
            zall_offset = zall - mean(mean(zall));
            mean_zall = mean(zall_offset);
            std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
            sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));
    
            % plot mean and sem
            fig = figure;
            y = mean(zall);
            x = 1:numel(y);
            curve1 = y + sem_zall;
            curve2 = y - sem_zall;
            x2 = [x, fliplr(x)];
            inBetween = [curve1, fliplr(curve2)];
            h = fill(x2, inBetween, 'r');
            set(h, 'facealpha', 0.25, 'edgecolor', 'none');
            hold on;
            plot(x, y, 'r', 'LineWidth', 2);
    
            % Plot vertical line at epoch onset, time = 0
            xline(pre_dur, ':', 'LineWidth', 2);
            xline(epoc_length-post_dur, ':', 'LineWidth', 2);
    
            %labels
            n1 = sprintf('%s%s', exp_ID);
            n2 = sprintf('%s%s', bouts_name);
            n3 = sprintf('%d', size(bouts,1));
            ttl = [n1 ' average ' n2 ' response with SEM, ' n3 ' Trials'];
            title (ttl);
            xlabel(sprintf('frames (@ %d frames per second)', round(fp_fps)));
            ylabel('zscore')
            axis tight
    
            %save
            filename = sprintf(['%s%s' '_' '%s%s'], exp_ID, bouts_name);
            filename = [filename 'LinePlot'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;

            % do same, with each trial plotted individually
            fig = figure;
            plot(zall_offset');
            xline(pre_dur, ':', 'LineWidth', 2);
            xline(epoc_length-post_dur, ':', 'LineWidth', 2);
            %labels
            num_t = size(zall,1);
            leg = {};
            for i = 1:num_t
                i_t = ['trial ' num2str(i)];
                leg = [leg {i_t}];
            end
            leg = [leg {'tone on'} {'tone off'}];
            legend(leg)
            n1 = sprintf('%s%s', exp_ID);
            n2 = sprintf('%s%s', bouts_name);
            n3 = sprintf('%d', size(bouts,1));
            ttl = [n1 ' average ' n2 ' response with SEM, ' n3 ' Trials'];
            title (ttl);
            xlabel(sprintf('frames (@ %d frames per second)', round(fp_fps)));
            ylabel('zscore')
            axis tight
            %save
             filename = sprintf(['%s%s' '_' '%s%s'], exp_ID, bouts_name);
            filename = [filename 'LinePlot_IndvLines'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;




        end

     if P2.do_reward
        %% reward consumption
        reward_time = P2.reward_t;
        pre_reward_time = 2; % seconds before platform to visualize
        pre_reward_baseline = 2; % seconds before pre_pf to use as baseline
        fps = 50;
        
        reward_bout_dur = rewardframes(:,2) - rewardframes(:,1);
        reward_idx = 1:size(rewardframes,1);
        reward_entry = rewardframes(:,1);
        total_length = (reward_time+pre_reward_time)*fps+1;

        % test to see if there's platform entries. exit if not
        if isempty(rewardframes) || length(reward_bout_dur)<2
            disp('no reward entries. skipping reward heatmap');
        else


            % test if first or end point will exceed recording limit
            omega = reward_entry(end) + total_length;
            if omega > length(bhsig)
                reward_entry = reward_entry(1:end-1);
            end

            alpha = reward_entry(1) - (pre_reward_time+pre_reward_baseline)*fps;
            if alpha < 1
                reward_entry = reward_entry(2:end);
            end
            % get signal for all trials and zscore
            zall4 = zeros(length(reward_entry),total_length);
            
            for i = 1:size(zall4,1)
                bl = bhsig(reward_entry(i) - ((pre_reward_time+pre_reward_baseline)*fps) : reward_entry(i) - ((pre_reward_baseline)*fps));
                zb = mean(bl); % baseline period mean
                zsd = std(bl); % baseline period stdev
                s1 = reward_entry(i) - (pre_reward_time*fps);
                s2 = reward_entry(i) + (reward_time*fps);
                zall4(i,:)=((bhsig(s1:s2)- zb) / zsd);
            end
            
            % make heatmap
            fig = figure;
            imagesc(zall4, [-5 5])
            colormap('parula'); 
            c1 = colorbar; 
            title(sprintf('Z-Score Heat Map, %d Reward Consumption Entry at dashed line', size(reward_idx,1)));
            ylabel('Entires', 'FontSize', 12);
            hold on;
            xline(pre_pf_time*fps, ':', 'LineWidth', 2);
            xlabel(sprintf('frames (@ %d frames per second)', fps));
            
            filename = sprintf(['%s%s' '_'], exp_ID);
            filename = [filename 'RewardConsumption_HeatMap'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;

         %% reward entry but not consumption
        reward_time = P2.reward_t;
        pre_reward_time = 2; % seconds before platform to visualize
        pre_reward_baseline = 2; % seconds before pre_pf to use as baseline
        fps = 50;

        clearvars rewardframes reward_bout_dur reward_idx reward_entry total_length

        rewardframes = rewardframes_all(find(rewardframes_all(:,3)==0),1:2);
        rewardframes = rewardframes(find(rewardframes(:,1)),:);
        reward_bout_dur = rewardframes(:,2) - rewardframes(:,1);
        reward_idx = 1:size(rewardframes,1);
        reward_entry = rewardframes(:,1);
        total_length = (reward_time+pre_reward_time)*fps+1;

          % test if first or end point will exceed recording limit
            omega = reward_entry(end) + total_length;
            if omega > length(bhsig)
                reward_entry = reward_entry(1:end-1);
            end

            alpha = reward_entry(1) - (pre_reward_time+pre_reward_baseline)*fps;
            if alpha < 1
                reward_entry = reward_entry(2:end);
            end
            % get signal for all trials and zscore
            zall5 = zeros(length(reward_entry),total_length);
            
            for i = 1:size(zall5,1)
                bl = bhsig(reward_entry(i) - ((pre_reward_time+pre_reward_baseline)*fps) : reward_entry(i) - ((pre_reward_baseline)*fps));
                zb = mean(bl); % baseline period mean
                zsd = std(bl); % baseline period stdev
                s1 = reward_entry(i) - (pre_reward_time*fps);
                s2 = reward_entry(i) + (reward_time*fps);
                zall5(i,:)=((bhsig(s1:s2)- zb) / zsd);
            end
            
            % make heatmap
            fig = figure;
            imagesc(zall5, [-5 5])
            colormap('parula'); 
            c1 = colorbar; 
            title(sprintf('Z-Score Heat Map, %d Reward Port Entry at dashed line', size(reward_idx,1)));
            ylabel('Entires', 'FontSize', 12);
            hold on;
            xline(pre_pf_time*fps, ':', 'LineWidth', 2);
            xlabel(sprintf('frames (@ %d frames per second)', fps));
            
            filename = sprintf(['%s%s' '_'], exp_ID);
            filename = [filename 'RewardEntry_HeatMap'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;
        end
     end
    
        %% create behavior and signal plot
        % using whole data vector, limiting axis to break up data
    
        if P2.do_vectorplot
            beh_vec = zeros(size(beh2fp));
            for bt = 1:size(bouts,1)
                beh_vec(bouts(bt,1):bouts(bt,2)) = 1;
            end
            bhsig = sig(beh2fp);

            if P2.remove_nonshock_tones
                beh_vec = beh_vec(bouts(4,1)-1500:end);
                bhsig = bhsig(bouts(4,1)-1500:end);
            end
            zsig = (bhsig - mean(bhsig)) / std(bhsig);
            t_display = 240; % seconds to display in a row
            disp_length = round(t_display * beh_fps);
            num_rows = ceil(length(beh_vec)/disp_length); % number of rows to break data into
            ct = 0;

            fig = figure;

            for i = 1:num_rows
                s_frame = (i-1)*disp_length + 1;
                ct = ct+1;
                m = ['ax' num2str((i*2)-1)];
    
                %plot beh vec
                axes.(m) = subplot(num_rows*2,1,(i*2)-1);
                imagesc(axes.(m), beh_vec);
                xlim(axes.(m),[s_frame s_frame+disp_length]);
                axes.(m).Colormap('hot');
                axes.(m).FontSize = 5;
    
                %plot sig vec
                ct = ct+1;
                n = ['ax' num2str((i*2))];
                axes.(n) = subplot(num_rows*2,1,i*2);
                imagesc(axes.(n), bhsig); 
                xlim(axes.(n),[s_frame s_frame+disp_length]);
                axes.(n).Colormap('parula');
                axes.(n).FontSize = 5;
    
                %link axes
                linkaxes([axes.(m) axes.(n)], 'xy');
            end
            %save
            filename = sprintf(['%s%s' '_' '%s%s'], exp_ID, bouts_name);
            filename = [filename 'VectorPlot_Tone3up'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;
        end
        
      
        %% calculate AUC for shock trials
        auc_shock = {};
        auc_shock_names = {'ID', 'trial', '28s', '30s', '60s', '2s shock', '10s postshock'};
        if P2.do_auc_shocktrials
            % get shocked trials, ignoring first 3
            shock_trials = find(on_platform_shock==0);
            shock_trials = shock_trials(shock_trials>=4);


            % remove last trials if excluded
            if P2.remove_last_trials
                shock_trials = shock_trials(shock_trials<=16);
            end

            % do auc. get 10, 40, 80 sec
            auc_shock = {};
            for i = 1:length(shock_trials)
                trial_start = round(fp_fps*P2.trange_peri_bout(1));
                i_trial = zall(shock_trials(i),:);
                i_offset = mean(i_trial(1:trial_start));
                i_trial = i_trial - i_offset;

                auc_shock{i,1} = exp_ID;
                auc_shock{i,2} = num2str(shock_trials(i));
                auc_shock{i,3} = trapz(i_trial(trial_start:trial_start+fp_fps*28));
                auc_shock{i,4} = trapz(i_trial(trial_start:trial_start+fp_fps*30));
                auc_shock{i,5} = trapz(i_trial(trial_start:trial_start+fp_fps*59));
                auc_shock{i,6} = trapz(i_trial(trial_start+fp_fps*28:(trial_start+fp_fps*30)));
                auc_shock{i,7} = trapz(i_trial((trial_start+fp_fps*30):(trial_start+fp_fps*40)));
            end
            auc_shock_all{ct} = auc_shock;
            

            % do peak for shocked
            %% calculate value and latency of peak average score
            peaks_shock = {};
            %resitrct to just tone period including shock
            for i = 1:length(shock_trials)
                trial_start = round(fp_fps*P2.trange_peri_bout(1));
                i_trial = zall(shock_trials(i),:);
                i_offset = mean(i_trial(1:trial_start));
                i_trial = i_trial - i_offset;
                
                [peak, latency] = max(i_trial(trial_start:trial_start+fp_fps*30));
                peaks_shock{i,1} = exp_ID;
                peaks_shock{i,2} = num2str(shock_trials(i));
                peaks_shock{i,3} = peak;
                peaks_shock{i,4} = latency;
            end
            peaks_shock_all{ct} = peaks_shock;
        end
        
        %% calculate AUC for nonshock trials
        auc_nonshock = {};
        peaks_shock = {};
        peaks_nonshock = {};
        if P2.do_auc_shocktrials
            % get shocked trials, ignoring first 3
            nonshock_trials = find(on_platform_shock==1);
            nonshock_trials = nonshock_trials(nonshock_trials>=4);

            % remove last trials if excluded
            if P2.remove_last_trials
                nonshock_trials = nonshock_trials(nonshock_trials<=16);
            end
            % do auc. get 10, 40, 80 sec
            auc_nonshock = {};
            for i = 1:length(nonshock_trials)
                trial_start = round(fp_fps*P2.trange_peri_bout(1));
                i_trial = zall(nonshock_trials(i),:);
                i_offset = mean(i_trial(1:trial_start));
                i_trial = i_trial - i_offset;
                
                trial_start = (fp_fps*P2.trange_peri_bout(1));
                auc_nonshock{i,1} = exp_ID;
                auc_nonshock{i,2} = num2str(nonshock_trials(i));
                auc_nonshock{i,3} = trapz(i_trial(trial_start:trial_start+fp_fps*28));
                auc_nonshock{i,4} = trapz(i_trial(trial_start:trial_start+fp_fps*30));
                auc_nonshock{i,5} = trapz(i_trial(trial_start:trial_start+fp_fps*59));
                auc_nonshock{i,6} = trapz(i_trial(trial_start+fp_fps*28:(trial_start+fp_fps*30)));
                auc_nonshock{i,7} = trapz(i_trial((trial_start+fp_fps*30):(trial_start+fp_fps*40)));
            end
            auc_nonshock_all{ct} = auc_nonshock;

            %% calculate value and latency of peak average score
            peaks_nonshock = {};
            for i = 1:length(nonshock_trials)
                trial_start = round(fp_fps*P2.trange_peri_bout(1));
                i_trial = zall(nonshock_trials(i),:);
                i_offset = mean(i_trial(1:trial_start));
                i_trial = i_trial - i_offset;
                [peak, latency] = max(i_trial(trial_start:trial_start+fp_fps*30));
                peaks_nonshock{i,1} = exp_ID;
                peaks_nonshock{i,2} = num2str(nonshock_trials(i));
                peaks_nonshock{i,3} = peak;
                peaks_nonshock{i,4} = latency;
            end
            peaks_nonshock_all{ct} = peaks_nonshock;

            %% do baseline trials
            auc_baseline = {};
            peaks_baseline = {};
            for i = 1:3
                i_trial = zall(i,:);
                [peak, latency] = max(i_trial(trial_start:trial_start+fp_fps*30));
                peaks_baseline{i,1} = exp_ID;
                peaks_baseline{i,2} = num2str(i);
                peaks_baseline{i,3} = peak;
                peaks_baseline{i,4} = latency;
            end
            peaks_baseline_all{ct} = peaks_baseline;

            for i = 1:3
                trial_start = round(fp_fps*P2.trange_peri_bout(1));
                i_trial = zall(i,:);
                i_offset = mean(i_trial(1:trial_start));
                i_trial = i_trial - i_offset;
                
                trial_start = (fp_fps*P2.trange_peri_bout(1));
                auc_baseline{i,1} = exp_ID;
                auc_baseline{i,2} = num2str(i);
                auc_baseline{i,3} = trapz(i_trial(trial_start:trial_start+fp_fps*28));
                auc_baseline{i,4} = trapz(i_trial(trial_start:trial_start+fp_fps*30));
                auc_baseline{i,5} = trapz(i_trial(trial_start:trial_start+fp_fps*59));
                auc_baseline{i,6} = trapz(i_trial(trial_start+fp_fps*28:(trial_start+fp_fps*30)));
                auc_baseline{i,7} = trapz(i_trial((trial_start+fp_fps*30):(trial_start+fp_fps*40)));
            end
            auc_baseline_all{ct} = auc_baseline;
            
        end

        %% do platform bouts
        if P2.do_platform
            bouts_pf_og = Behavior.Spatial.platform.Bouts;
            bout_dur = bouts_pf_og(:,2)-bouts_pf_og(:,1);
            
            min_dur = 250;  % dur in behavior frames
            long_bouts = find(bout_dur>min_dur);
            bouts_pf = bouts_pf_og(long_bouts,:);
            
            tone_vec = Behavior.Temporal.CSp.Vector;
            
            % ask if movement bout is during tone or not
            move_in_tone = zeros(size(bouts_pf,1),1);

            % get which platform entry occurs during a tone
            for i = 1:size(bouts_pf,1)
                if tone_vec(bouts_pf(i,1))
                    move_in_tone(i) = 1;
                end
            end

            % find which in tone entries were successful avoids
            ops2 = on_platform_shock;
            ops(1:4) = 0; % hardcode change to exclude baseline tones
            tone_avoid_vec = zeros(size(tone_vec));
            for i = 1:length(ops2)
                if ops2(i)
                    tone_avoid_vec(bouts(i,1):bouts(i,2)) = 1;
                end
            end

            % tone avoid vec codes tones which were successful avoids
            % now need use bouts for pf, intersect with tone avoid vec
            avoid_pf_entry = zeros(size(move_in_tone));
            for i = 1:size(bouts_pf,1)
                tmp = sum(tone_avoid_vec(bouts_pf(i,1):bouts_pf(i,2)));
                if tmp > 0
                    avoid_pf_entry(i) = 1;
                else
                    avoid_pf_entry(i) = 0;
                end
            end

            pre_pf_bl = [300 150]; % pre platform time in beh frames to baseline to
            P2.pre_pf_window = 250; % time pre platform entry to gather in beh frames

            % get signal for all trials and zscore
            zall_pf = zeros(size(bouts_pf,1),min_dur+P2.pre_pf_window);
    

            for i = 1:size(zall_pf,1)
                zb = mean(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period mean
                zsd = std(bhsig(bouts_pf(i,1)-pre_pf_bl(1):bouts_pf(i,1)-pre_pf_bl(2))); % baseline period stdev
                zall_pf(i,:)=(bhsig((bouts_pf(i,1)-P2.pre_pf_window):bouts_pf(i,1)+min_dur-1) - zb)/zsd; % Z score per bin
            end

            % get just entries during tonem excluding baseline
            zall_pf_tone = zall_pf(find(move_in_tone),:);

            %
            % get just entries NOT during tone
            zall_pf_nontone = zall_pf(find(move_in_tone==0),:);

            % get entries just during tones with successful avoids
            zall_pf_avoid = zall_pf(find(avoid_pf_entry),:);

            
            fig = linePlot(zall_pf_nontone,P2.pre_pf_window,{'platform entry'});

            %labels
            n1 = sprintf('%s%s', exp_ID);
            n2 = sprintf('%s%s', bouts_name);
            n3 = sprintf('%d', size(zall_pf_nontone,1));
            ttl = [n1 ' nontone platform entries n=' n3];
            title (ttl);
            xlabel(sprintf('frames (@ %d frames per second)', round(beh_fps)));
            ylabel('zscore')
            axis tight
    
            %save
            filename = sprintf(['%s%s' '_'], exp_ID);
            filename = [filename '_linePlot_nonTonePlatformEntries'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;

            %% do avoids
            fig = linePlot(zall_pf_avoid,P2.pre_pf_window,{'platform entry'});

            %labels
            n1 = sprintf('%s%s', exp_ID);
            n2 = sprintf('%s%s', bouts_name);
            n3 = sprintf('%d', size(zall_pf_avoid,1));
            ttl = [n1 ' successful avoid platform entries n=' n3];
            title (ttl);
            xlabel(sprintf('frames (@ %d frames per second)', round(beh_fps)));
            ylabel('zscore')
            axis tight
    
            %save
            filename = sprintf(['%s%s' '_' '%s%s'], exp_ID);
            filename = [filename '_linePlot_avoidPlatformEntries'];
            filename = [basedir '\' filename];
            saveas(fig, filename);
            close;
            clear fig;
        end



        %% Save individual animal data
        bhsig = sig(beh2fp);
        if ~exist('peaks','var')
            peaks = {};
        end

        if ~exist('shock_trials', 'var')
            shock_trials = [];
        end
        if ~exist('nonshock_trials', 'var')
            nonshock_trials = [];
        end
        if ~exist('on_platform_shock','var')
            on_platform_shock = [];
        end
        if ~exist('zall_pf','var')
            zall_pf = [];
        end
        if ~exist('zall_pf_avoid', 'var')
            zall_pf_avoid = [];
        end
        if ~exist('zall_pf_nontone','var')
            zall_pf_nontone = [];
        end
        if~exist('zall_pf_tone','var')
            zall_pf_tone=[];
        end
        if ~exist('peaks_baseline','var')
            peaks_baseline=[];
        end
        if ~exist('auc_baseline','var')
            auc_baseline=[];
        end
        if ~exist('pre_dur', 'var')
            pre_dur = [];
        end
        if ~exist('epoc_length', 'var')
            epoc_length = [];
        end

        P2.fp_fps = fp_fps;
        P2.event_on = pre_dur;
        P2.event_off = epoc_length;
        savename = [basedir '\' exp_ID '_' bouts_name '_fibpho_analysis.mat'];
        if P2.save_analysis
          save(savename, 'data', 'bouts', 'bouts_name', 'zall', 'peaks', 'peak_names', 'auc_fc_abs', 'auc_names_fc', 'sig', 'bhsig', 'P2', 'auc_shock', 'auc_shock_names', 'auc_nonshock', 'peaks_shock', 'peaks_nonshock', 'shock_trials', 'nonshock_trials', 'on_platform_shock', 'beh2fp', 'peaks_baseline', 'auc_baseline', 'zall_pf', 'zall_pf_avoid','zall_pf_nontone','zall_pf_tone');
        end
end
    
    %save compiled data
    cd(string(P2.video_directory));
    
    % make params struct for records

    if ~exist("bouts_name",'var')
        bouts_name = date;
    end

    Params.fp_ds_factor = P2.fp_ds_factor; % factor by which to downsample FP recording (eg 10 indicates 1:10:end)
    Params.trange_peri_bout = P2.trange_peri_bout; % [sec_before, sec_after] event to visualize
    Params.baseline_per = P2.baseline_per; % baseline period relative to epoc onset
    Params.do_lineplot = P2.do_lineplot;
    Params.do_heatmap = P2.do_heatmap;
    Params.do_vectorplot = P2.do_vectorplot;
    Params.do_peak = P2.do_peak;
    Params.do_auc = P2.do_auc;
    Params.bouts_name = bouts_name; % char name of bouts (for labeling and saving)
    

    if ~exist('peaks_shock_all','var')
        peaks_shock_all = [];
    end
    if ~exist('peaks_nonshock_all','var')
        peaks_nonshock_all = [];
    end
    if ~exist('peak_names','var')
        peak_names = [];
    end
    if ~exist('auc_shock_all','var')
        auc_shock_all = [];
    end
    if ~exist('auc_shock_names', 'var')
        auc_shock_names = [];
    end
    if ~exist('auc_nonshock_all', 'var')
        auc_nonshock_all = [];
    end
    if ~exist('auc_baseline_all', 'var')
        auc_baseline_all = [];
    end
    if~exist('peaks_baseline_all','var')
        peaks_baseline_all = [];
    end
    if ~exist('auc_fc_abs','var')
        auc_fc_abs = [];
    end
    if ~exist('auc_fc_ind_abs','var')
        auc_fc_ind_abs = [];
    end
    if ~exist('auc_fc_ind','var')
        auc_fc_ind = [];
    end
    
    if P2.save_analysis
        save(['fibpho_analysis5_' bouts_name '.mat'], 'auc_fc_ind', 'auc_fc_ind_abs', 'auc_fc_abs', 'auc_names_fc', 'peaks', 'peaks_shock_all', 'peaks_nonshock_all', 'peak_names', 'Params', 'auc_shock_all', 'auc_shock_names', 'auc_nonshock_all', 'auc_baseline_all', 'peaks_baseline_all');
    end
    
%% internal functions
function beh2fp = beh2FPfrlu(cueframes_in, TDTdata, cue, numFrames)
% GOAL: Create a frame lookup table to translate fiber photometry frames
% to Behavior frames (using Fear Conditioning Experiment Designer and 
% BehDEPOT output). 
% INPUT:  cueframes_in, TDTdata (output from TDTbin2mat), PC0name (string; name of PC0
% signal in exp_file, eg "tone" or "csp")
% OUTPUT:  frame lookup table translating TDT fiber photometry frames to
% behavior frames. Example:  beh2fp(1) = N, where 1 is behavior frame 1
% which corresponds to FP frame N

% get cueframes from experiment file and PC0 timing from TDT
cueframes = cueframes_in.(cue{2});
fp.pc_times = [TDTdata.epocs.(cue{1}).onset, TDTdata.epocs.(cue{1}).offset]; 

% hardcode to adjust bug in final event acquisition
if fp.pc_times(end,2) == Inf
    fp.pc_times = fp.pc_times(1:end-1,:);
end

fp.fps = TDTdata.streams.x465A.fs;
fp.pc0_frames = fp.pc_times * fp.fps;

% find length of behavior, insensitive to fieldnames 
behsz = numFrames;

beh_frames = cueframes;
fp_frames = fp.pc0_frames;

temp_BEHs = []; % initialize BEHs var
for iii=1:size(beh_frames,1)
    temp_BEHs=[temp_BEHs,round(beh_frames(iii,:))]; % calc behavior indices based on tone onset/offset
end

temp_FPs=[]; % initialize FPs variable
for iii=1:size(fp_frames,1) 
    temp_FPs=[temp_FPs,round(fp_frames(iii,:))]; % calc FP indices based on tone onset/offset
end

% make a linear model to predict all beh frame FP values
mdl = fitlm(temp_BEHs',temp_FPs',"quadratic");
ynew = 1:numFrames;
ypred = predict(mdl,ynew');
beh2fp=round(ypred); % round resultant intperolation so the indices are integers
beh2fp=beh2fp';
end

function beh2fp = hardCodebeh2fpClean(id, beh2fp)
    if isequal(id,'zz170_D2_recall')
        beh2fp(1:1000)=1;
    end
    if isequal(id, 'zz171_D1_conditioning')
        beh2fp(1:500)=1;
    end
    if isequal(id, 'zz172_D1_conditioning')
        beh2fp(1:300)=1;
    end
    if isequal(id, 'zz173_D1_conditioning')
        beh2fp(1:500)=1;
    end
end
