 P2.trange_peri_bout = [4 4];
   P2.baseline_per = [4 3.5];
    pf_bout_dur = Behavior.Spatial.platform.Bouts(:,2) - Behavior.Spatial.platform.Bouts(:,1);     
    
    pf_time = P2.trange_peri_bout(2); % seconds after platform encounter to visualize
    pre_pf_time = P2.trange_peri_bout(1); % seconds before platform encounter to visualize
    pre_pf_baseline = abs(P2.baseline_per(1)); % seconds before pre_pf to use as baseline
    % calc baseline frames
    bl = [P2.baseline_per(1)*P2.beh_fps, P2.baseline_per(2)*P2.beh_fps];

    % only do platform bouts > 4s
    pf_idx = find(pf_bout_dur>(4*P2.beh_fps));

    pf_entry = Behavior.Spatial.platform.Bouts(:,1);
    pf_exit = Behavior.Spatial.platform.Bouts(:,2);
    total_length = floor((pf_time+pre_pf_time)*P2.beh_fps);

    % test to see if entry happens immediately following or during a shock,
    % reject platform entry if so
    us_vec = Behavior.Temporal.US.Vector;
    pf_idx_reject = [];
    for i = 2:length(pf_idx)
        if sum(us_vec(pf_entry(pf_idx(i))-(2*P2.beh_fps):pf_entry(pf_idx(i)))) > 0
            pf_idx_reject(i) = i;
        end
    end
    pf_idx_reject = pf_idx_reject(find(pf_idx_reject));
    pf_idx(pf_idx_reject) = [];

    % test to see if there's platform entries. exit if not
    if isempty(pf_idx)
        disp('no platform entries. skipping platform heatmap');
        zall_pf_entry = []; 
        zall_pf_exit = [];
    else
        % test if first or end point will exceed recording limit
        omega = pf_exit(pf_idx(end)) + total_length;
        if omega > length(bhsig)
            pf_idx = pf_idx(1:end-1);
        end
    
        alpha = pf_entry(pf_idx(1)) - (pre_pf_time+pre_pf_baseline)*P2.beh_fps;
        if alpha < 1
            pf_idx = pf_idx(2:end);
        end
    
        % get signal for all trials and zscore for entry
        zall_pf_entry = zeros(size(pf_idx,1),total_length);
    
        bl = floor(bl);
        
        for i = 1:size(zall_pf_entry,1)
            bl_pf = bhsig(pf_entry(pf_idx(i)) - bl(1) : pf_entry(pf_idx(i)) - bl(2));
            zb = mean(bl_pf); % baseline period mean
            zsd = std(bl_pf); % baseline period stdev
            s1 = floor(pf_entry(pf_idx(i)) - (P2.trange_peri_bout(1)*P2.beh_fps));
            s2 = floor(pf_entry(pf_idx(i)) + (P2.trange_peri_bout(2)*P2.beh_fps));
            zall_pf_entry(i,:)=((bhsig(s1:s2-1)- zb) / zsd);
            zall_pf_entry(i,:)=smooth(zall_pf_entry(i,:),25);
            %zall_pf_entry(i,:) = zall_pf_entry(i,:) - mean(zall_pf_entry(i,1:pre_pf_baseline*P2.beh_fps));
        end
     
     
        % get signal for all trials and zscore for exit
        zall_pf_exit = zeros(size(pf_idx,1),total_length);
        
        for i = 1:size(zall_pf_exit,1)
            bl_pf = bhsig(pf_exit(pf_idx(i)) - ((pre_pf_time+pre_pf_baseline)*P2.beh_fps) : pf_exit(pf_idx(i)) - ((pre_pf_baseline)*P2.beh_fps));
            zb = mean(bl_pf); % baseline period mean
            zsd = std(bl_pf); % baseline period stdev
            s1 = pf_exit(pf_idx(i)) - (pre_pf_time*P2.beh_fps);
            s2 = pf_exit(pf_idx(i)) + (pf_time*P2.beh_fps);
            zall_pf_exit(i,:)=((bhsig(s1:s2-1)- zb) / zsd);
            zall_pf_exit(i,:)=smooth(zall_pf_exit(i,:),25);
            %zall_pf_exit(i,:) = zall_pf_exit(i,:) - mean(zall_pf_exit(i,1:pre_pf_baseline*P2.beh_fps));
        end
    end

    linePlot(zall_pf_entry,200,{'pf entry'});
    linePlot(zall_pf_exit,200,{'pf exit'});
    save('pf_data_20240220.mat');