function subdirs = getSubDirs(directory)
    % This function returns all subdirectories within a given directory.
    %
    % INPUT: 
    %   directory - path to the directory
    %
    % OUTPUT: 
    %   subdirs - cell array of subdirectory paths

    % Check if the provided directory exists
    if ~isfolder(directory)
        error('The provided path is not a valid directory.');
    end

    % List all contents of the directory
    d = dir(directory);

    % Filter out files and keep only directories. Also remove '.' and '..'
    isSub = [d.isdir] & ~strcmp({d.name}, '.') & ~strcmp({d.name}, '..');

    % Extract subdirectory names
    subdirs = {d(isSub).name};

end
