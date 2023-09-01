% Get a list of all files and folders in this folder.
files = dir([pwd,'\**\']);
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
% Extract only those that are directories.
subFolders = files(dirFlags);
Miniscope_folders_idx = [];
Miniscope_folder = {};
for i = 1:length(subFolders)
    if contains(subFolders(i).name, 'Miniscope')
        Miniscope_folders_idx = [Miniscope_folders_idx, i];
        Miniscope_folder = [Miniscope_folder, [subFolders(i).folder,'\',subFolders(i).name]];
    end
end
%%

for i = 1:length(Miniscope_folder)
   VideoCombine(Miniscope_folder{i},'m',true,'avi'); 
end