    clear
    % Prompt the user to select a directory
    selectedDir = uigetdir('', 'Please select a directory for batch analysis');
    
    % Find all subdirectories within the selected directory
    subDirs = dir(selectedDir);
    subDirs = subDirs([subDirs.isdir]);
    subDirs = subDirs(~ismember({subDirs.name}, {'.', '..'}));
    
    % Iterate over each subdirectory
    for i = 1:numel(subDirs)
        subDirPath = fullfile(selectedDir, subDirs(i).name);
                
        % Find the file matching the pattern 'CSp_fibpho_analysis.mat' exp file
        expFile = dir(fullfile(subDirPath, '*CSp_fibpho_analysis.mat'));
        if isempty(expFile)
            warning('Warning: No matching file found in the directory');
            continue;  % Skip to the next subdirectory
        end

        load(fullfile(subDirPath, expFile.name),'zall', 'P2');
        P2.basedir = subDirPath;

        %zscore zall to [-5 0] seconds
        bl = [200 250];
        for t = 1:size(zall,1)
            sig = zall(t,:);
            zb = mean(sig(bl(1):bl(2)));
            zsd = std(sig(bl(1):bl(2)));
            zall(t,:) = (sig - zb)/zsd;
            %zall_new(t,:)=smooth(zall_new(t,:),25);  % optional smoothing
        end
        zall_1s = zall;
        save(fullfile(subDirPath, expFile.name), "zall_1s", "P2", '-append');

  
        % Find the '_analyzed' directory
        analyzedDir = dir(subDirPath);
        analyzedDir = analyzedDir([analyzedDir.isdir]);
        analyzedDir = analyzedDir(~ismember({analyzedDir.name}, {'.', '..'}));
        analyzedDir = analyzedDir(contains({analyzedDir.name}, '_analyzed'));
        
        if isempty(analyzedDir)
            warning('Warning: "_analyzed" directory not found');
            continue;  % Skip to the next matching file
        end
        
        analyzedDirPath = fullfile(subDirPath, analyzedDir.name);

        % Load Behavior.mat file from _analyzed dir
        behaviorFilePath = fullfile(analyzedDirPath, 'Behavior.mat');
        if ~isfile(behaviorFilePath)
            warning('Warning:  "Behavior.mat" file not found');
            continue;
        end
        load(behaviorFilePath);

        tone_on = Behavior.Temporal.CSp.Bouts(:,1);
        reward_vec = Behavior.Spatial.reward.inROIvector;
        pf_vec = Behavior.Spatial.platform.inROIvector;

        % initialize tone divisions
        reward_tones = zeros(size(tone_on));
        pf_tones = zeros(size(tone_on));
        other_tones = zeros(size(tone_on));

        % match tones with location
        for j = 1:length(tone_on)
            if reward_vec(tone_on(j))
                reward_tones(j)=1;
            elseif pf_vec(tone_on(j))
                pf_tones(j)=1;
            else
                other_tones(j)=1;
            end
        end

        % make struct to save data
        tone_onset_in_space = struct;
        tone_sig_by_onset_space.reward_onset = zall(find(reward_tones),:);
        tone_sig_by_onset_space.pf_onset = zall(find(pf_tones),:);
        tone_sig_by_onset_space.other_onset = zall(find(other_tones),:);

        save(fullfile(subDirPath, expFile.name), "tone_sig_by_onset_space", "-append")


        % make plots
        for k = 1:3
            if k == 1
                zallz = tone_sig_by_onset_space.reward_onset;
                bouts_name = 'Reward At Tone Onset';
            elseif k == 2
                zallz = tone_sig_by_onset_space.pf_onset;
                bouts_name = 'Platform At Tone Onset';
            else
                zallz = tone_sig_by_onset_space.other_onset;
                bouts_name = 'NonReward NonPF At Tone Onset';
            end
        
            if ~isempty(zallz)
                %% plot heatmap of tones
                go_heatmap(zallz, bouts_name, [P2.pre_dur, P2.tone_dur+P2.pre_dur], P2);
        
                %% do lineplot of tones
                go_lineplot(zallz, bouts_name, [P2.pre_dur, P2.tone_dur+P2.pre_dur], P2)
            end

        end
       
    end


    %%
    %% HELPER FXN
    %%

    function go_heatmap(zall, bouts_name, vertLines, P2)
    % Plot heat map over trials
    fig = figure;
    imagesc(zall)
    colormap('parula'); 
    c1 = colorbar; 
    title(sprintf('Z-Score Heat Map, %d %s%s', size(zall,1), bouts_name));
    ylabel('Trials', 'FontSize', 12);
    hold on;
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end

    % get FP fps (downsample adjusted) to label xaxis
    xlabel(sprintf('frames (@ %d frames per second)', P2.beh_fps));

    filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'HeatMap_1sBL.fig'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function go_lineplot(zall, bouts_name, vertLines, P2)

    % Subtract DC offset to get signals on top of one another and adjust
    % baseline to be zeroed
    zall_offset = zall - mean(mean(zall));
    for i = 1:size(zall,1)
        zall_offset(i,:) = zall_offset(i,:) - mean(zall_offset(1:50));
        zall_offset(i,:) = smooth(zall_offset(i,:),25);
    end
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
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end

    %labels
    n1 = sprintf('%s%s', P2.exp_ID);
    n2 = sprintf('%s%s', bouts_name);
    n3 = sprintf('%d', size(zall,1));
    ttl = [n1 ' average ' n2 ' response with SEM, ' n3 ' Trials'];
    title (ttl);
    xlabel(sprintf('frames (@ %d frames per second)', round(P2.beh_fps)));
    ylabel('zscore')
    axis tight

    %save
    filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'LinePlot_1sBL.fig'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;

    % do same, with each trial plotted individually
    fig = figure;
    plot(zall_offset');
    % Plot vertical line at epoch onset, time = 0
    for i = 1:length(vertLines)
        xline(vertLines(i), ':', 'LineWidth', 2);
    end
    %labels
    num_t = size(zall,1);
    leg = {};
    for i = 1:num_t
        i_t = ['trial ' num2str(i)];
        leg = [leg {i_t}];
    end
    leg = [leg {'tone on'} {'tone off'}];
    legend(leg)
    n1 = sprintf('%s%s', P2.exp_ID);
    n2 = sprintf('%s%s', bouts_name);
    n3 = sprintf('%d', size(zall,1));
    ttl = [n1 ' average ' n2 ' response, ' n3 ' Trials'];
    title (ttl);
    xlabel(sprintf('frames (@ %d frames per second)', round(P2.beh_fps)));
    ylabel('zscore')
    axis tight
    %save
     filename = sprintf(['%s%s' '_' '%s%s'], P2.exp_ID, bouts_name);
    filename = [filename 'LinePlot_IndvLines_1sBL.fig'];
    filename = [P2.basedir '\' filename];
    saveas(fig, filename);
    close;
    clear fig;
 end