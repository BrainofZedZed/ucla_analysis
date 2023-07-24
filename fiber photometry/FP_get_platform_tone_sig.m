% GOAL:  get tone response signal, divided into platform and nonplatform
% starts. For off-platform tone starts, is tone signal correlated with
% platform latency?

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
tone_pf_off_out = cell(1,6);
tone_pf_on_out = cell(1,6);
tone_pf_labels = {'ID', 'tone number', 'peak (z)', 'pk latency (s)', 'lat to pf (s)', 'mean sig until pf entry'};

for filenum = 1:length(P1.video_folder_list)
    % Initialize 
    tone_response_this = cell(1,6);
    current_video = P1.video_folder_list(filenum);    
    video_folder = strcat(P1.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    
    % load files params
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    cd(video_folder);
    fibphof = dir('*fibpho_analysis.mat');
    load(fibphof.name, 'bhsig', 'P2', 'bouts', 'zall');
    exp_file = dir('*-*-*_*-*-*.mat');
    load(exp_file.name, 'cs_dur','us_dur'); % load experiment file
    pf_vec = Behavior.Spatial.platform.inROIvector;
        
    % equalize starting pre period
    zall_offset = zall - mean(zall(1:P2.pre_dur));
    
    % smooth data
    for i = 1:size(zall_offset,1)
        zall_offset(i,:) = smooth(zall_offset(i,:),25);
    end

    %% figure out if animal was on platform on not when tone started
    % initialize outputs
    on_pf_tone_start = zeros(size(bouts,1),1);

    % find when platform and tone is true
    tone_vec = Behavior.Temporal.CSp.Vector;
    pf_tone_vec = zeros(size(tone_vec));
    tmp = find(pf_vec & tone_vec);
    pf_tone_vec(tmp) = 1;
    
    pf_lat = zeros(size(bouts,1),1);
    for i = 1:size(bouts,1)
        this = find(pf_tone_vec(bouts(i,1):bouts(i,2)), 1, 'first');
        if isempty(this)
            pf_lat(i) = cs_dur*P2.beh_fps;
        else
            pf_lat(i) = this;
        end
    end

    % if latency is less than 0.5s, assert 0
    pf_lat(pf_lat<P2.beh_fps/2) = 0;

    % if latency is more then 28s, assert 28s (cs_dur - us_dur)
    % this avoids capturing shock response
    pf_lat(pf_lat>P2.beh_fps*(cs_dur-us_dur)) = (cs_dur-us_dur)*P2.beh_fps;

    % seperate into on and off platform starts
    on_pf_tone_start(pf_lat == 0) = 1;
        
    % get initial tone response period (5s, arbitrary)
    tone_response_dur = 5;
    tone_wnd = [P2.pre_dur+1, P2.pre_dur+1+P2.beh_fps*tone_response_dur];
    
    % find peak tone repsonse and save it
    % add pf_latency and mean response until pf_lat
    for i = 1:size(zall_offset,1)
        tone_response_this(i,1) = cellstr(P2.exp_ID);
        tone_response_this(i,2) = num2cell(i);
        [pk, lat] = max(zall_offset(i,tone_wnd(1):tone_wnd(2)));
        lat = lat/50;
        tone_response_this(i,3) = num2cell(pk);
        tone_response_this(i,4) = num2cell(lat);
        tone_response_this(i,5) = num2cell(pf_lat(i)/P2.beh_fps);
        if pf_lat(i) > 0
            tone_response_this(i,6) = num2cell(mean(zall_offset(i,tone_wnd(1):tone_wnd(1)+pf_lat)));
        else
            tone_response_this(i,6) = num2cell(0);
        end
    end
    
    tone_pf_off_out = [tone_pf_off_out; tone_response_this(find(on_pf_tone_start==0),:)];
    tone_pf_on_out = [tone_pf_on_out; tone_response_this(find(on_pf_tone_start>0),:)];
end
cd(string(P1.video_directory));
save('pf_tone_responses.mat','tone_pf_on_out','tone_pf_off_out',"tone_pf_labels");