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
out = {};


%% loop through folders
for j = 1:length(P2.video_folder_list)
    % clear from previous round
    current_video = P2.video_folder_list(j);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    basedir = pwd;
    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');

    out{j,1} = P2.video_folder_list(j);
    out{j,2} = mean(cell2mat(Behavior.Intersect.TemBeh.CSp.Freezing.PerBehDuringCue(:)));
    out{j,3} = mean(cell2mat(Behavior.Intersect.TemBeh.CSm.Freezing.PerBehDuringCue(:)));
end
