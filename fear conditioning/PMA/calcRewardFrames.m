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

% initialize output variable
reward_output = {};

for filenum = 1:length(P2.video_folder_list)
    % Initialize 
    current_video = P2.video_folder_list(filenum);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    
    % load files params
    expf = dir('*-*-*_*-*-*.mat');
    load(expf.name); % load experiment file into E struct
    reward_file = dir('*reward_data_*_*.txt');
    
    % read reward data
    rd = read_reward_data(reward_file.name);
    start_lag = cell2mat(rd(1,3));
    
    % indices of reward
    reward_ind = strcmp(rd(:, 1), 'reward_delivery') & cell2mat(rd(:, 2)) == 0;
    reward_ts_ms = cell2mat(rd(reward_ind,3));
    reward_ts_ms = reward_ts_ms - start_lag;
    
    % indices of beam break
    beam_ind = strcmp(rd(:,1), 'IR_beam_check') & cell2mat(rd(:,2)) == 0;
    
    
    % initialize array to track beam break rows immediately preceding reward
    exclude_rows = false(size(rd,1),1);
    
    % find beam rows immediately preceding reward rows
    for i = 1:numel(reward_ind)
        if reward_ind(i)
            exclude_rows(i-1) = true;
        end
    end
    
    % get non reward beam break rows
    nr_beam_ind = beam_ind & ~exclude_rows;
    nr_beam_ts_ms = cell2mat(rd(nr_beam_ind,3));
    nr_beam_ts_ms = nr_beam_ts_ms - start_lag;
    
    % translate arduino timestamp (ms since arduino start) to behavior frame
    fps = 50;
    
    reward_frames = round(reward_ts_ms / 1000 * fps); % 1000 ms/s, 50 frames/sec
    nonreward_beam_frames = round(nr_beam_ts_ms / 1000 * fps);

    reward_data = rd;
    save(expf.name,'reward_data', 'reward_frames', 'nonreward_beam_frames', '-append')

    id_out = {};
    id_out = repmat({exp_ID}, size(reward_frames));
    id_out = [id_out, num2cell(reward_frames)];

    reward_output = [reward_output; id_out];
end

cd(string(P2.video_directory));
writecell(reward_output, 'batch_reward_frames.csv');

%%%%%%%%%%%%%%%
% INTERNAL FXNS
%%%%%%%%%%%%%%%

function out = read_reward_data(filename)
    % Read the contents of the text file
    fileID = fopen(filename, 'r');
    fileContent = fscanf(fileID, '%c');
    fclose(fileID);
    
    % Find the required elements using regular expressions
    pinNameExp = '(?<="pin_name": ")[^"]*';
    stateExp = '(?<="state": )[0-9]*';
    timeExp = '(?<="time": )[0-9]*';
    
    pinNames = regexp(fileContent, pinNameExp, 'match');
    states = regexp(fileContent, stateExp, 'match');
    times = regexp(fileContent, timeExp, 'match');
    
    % Convert the extracted strings to appropriate types
    states = cellfun(@str2double, states);
    times = cellfun(@str2double, times);
    
    % Create the cell matrix
    out = [pinNames', num2cell(states)', num2cell(times)'];
end