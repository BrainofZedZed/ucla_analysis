function renameAVIs(new_name, data_directory)
%Renames all .avi files in data_directory with new_name (appends new_name
%to old video name; e.g. 0.avi --> your_vid_name0.avi

cd(data_directory)
d = dir('*.avi');
path = d.folder;

for i = 1:length(d)
    o_name = d(i).name;
    n_name = [new_name, o_name];
    movefile(fullfile(path, o_name), fullfile(path,n_name), 'f');
end
    