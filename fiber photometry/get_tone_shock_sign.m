% GOAL:  get peak response of each tone across all days & get shock
% response to each shock across all days

clear;
%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
P1.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P1.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
cd(string(P1.video_directory));
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
    current_structure = directory_contents(i);
    if current_structure.isdir
        ii = ii + 1;
        P1.video_folder_list(ii) = string(current_structure.name);
        disp([num2str(i) ' directory loaded'])
    end
end

% initialize output variable
tone_response_out = cell(1,4);
shock_response_out = cell(1,5);
shock_response_out_labels = {'ID','shock number', 'peak (z)', 'latency (s)', '10s AUC'};
tone_response_out_labels = {'ID', 'tone number', 'peak (z)', 'latency (s)'};

for filenum = 1:length(P1.video_folder_list)
    % Initialize 
    tone_response_this = cell(1,4);
    shock_response_this = cell(1,5);
    current_video = P1.video_folder_list(filenum);    
    video_folder = strcat(P1.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    
    % load files params
    expf = dir('*-*-*_*-*-*.mat');
    load(expf.name); % load experiment file into E struct
    fibphof = dir('*fibpho_analysis.mat');
    load(fibphof.name);
        
    % equalize starting pre period
    zall_offset = zall - mean(zall(1:P2.pre_dur));
    
    % smooth data
    for i = 1:size(zall_offset,1)
        zall_offset(i,:) = smooth(zall_offset(i,:),25);
    end
    % get initial tone response period (5s, arbitrary)
    tone_response_dur = 5;
    tone_wnd = [P2.pre_dur+1, P2.pre_dur+1+P2.beh_fps*tone_response_dur];
    
    % find peak tone repsonse and save it
    for i = 1:size(zall_offset,1)
        tone_response_this(i,1) = cellstr(P2.exp_ID);
        tone_response_this(i,2) = num2cell(i);
        [pk, lat] = max(zall_offset(i,tone_wnd(1):tone_wnd(2)));
        lat = lat/50;
        tone_response_this(i,3) = num2cell(pk);
        tone_response_this(i,4) = num2cell(lat);
    end
    
    % find shock reponse AUC
    % first need to get more signal data and normalize
     % get signal for all trials from 5s before tone start to 30s after it ends
    zshock = zeros(size(zall,1),(P2.pre_dur + cs_dur*P2.beh_fps + 30*P2.beh_fps));
    
    % zscore
    for i = 1:size(zshock,1)
        bl = [cueframes.CSp(i,1) - P2.pre_dur, cueframes.CSp(i,1)-1];
        t0 = bl(1);
        t1 = bl(1) + P2.pre_dur + cs_dur*P2.beh_fps + 30*P2.beh_fps-1;
        zb = mean(bhsig(bl(1):bl(2))); % baseline period mean
        zsd = std(bhsig(bl(1):bl(2))); % baseline period stdev
        zshock(i,:)=(bhsig(t0:t1) - zb)/zsd; % Z score per bin
        zshock(i,:) = smooth(zshock(i,:),25); % smooth
    end
    try
        zshock = zshock(~on_platform_shock,:);
        zshock_offset = zshock - mean(zshock(1:P2.pre_dur));
        
        % get peak, latency, and 'AUC' (ie mean over time)
        shock_start = P2.pre_dur + (cs_dur*P2.beh_fps) - (us_dur*P2.beh_fps);
        for i = 1:size(zshock_offset,1)
            shock_response_this(i,1) = cellstr(P2.exp_ID);
            shock_response_this(i,2) = num2cell(i);
            [pk, lat] = max(zshock_offset(i,shock_start:shock_start+(10*P2.beh_fps)));
            lat = lat/50;
            shock_response_this(i,3) = num2cell(pk);
            shock_response_this(i,4) = num2cell(lat);
            avg = mean(zshock_offset(i,shock_start:shock_start+(12*P2.beh_fps)));
            shock_response_this(i,5) = num2cell(avg);
        end
    catch
        shock_response_this(1,1) = cellstr(P2.exp_ID);
    end

    tone_response_out = [tone_response_out; tone_response_this];
    shock_response_out = [shock_response_out; shock_response_this];
end

cd(string(P1.video_directory));
save('tone_shock_all_responses_group.mat',"shock_response_out_labels", "shock_response_out", "tone_response_out", "tone_response_out_labels");
writecell(tone_response_out,'tone_responses.csv');
writecell(shock_response_out, 'shock_responses.csv');