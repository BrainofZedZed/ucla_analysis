% Specify the directory path
directory = '/path/to/your/directory/';

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