% Specify the directory path
directory = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\miniscope cohort6\2023_04_18\10_11_08\My_V4_Miniscope\compress';

% Find all AVI files in the directory
aviFiles = dir(fullfile(directory, '*.avi'));

% Sort the AVI files in alphanumeric order
[~, sortedIndices] = sort({aviFiles.name});

% Create the struct to store the file information
files = struct('name', {});

% Assign the absolute paths of the AVI files to the struct
for i = 1:numel(aviFiles)
    files(i).name = fullfile(directory, aviFiles(sortedIndices(i)).name);
end

[Ycon, ln] = concatenate_files(files);