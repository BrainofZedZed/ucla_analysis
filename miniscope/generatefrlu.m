% USE: generate frame lookup (frlu) and frame timestamp lookup (frtslu) files
% SETUP: run file, select root folder. Script will recurse ALL subdirectories,
% find every valid session (containing both My_V4_Miniscope and My_WebCam),
% and generate frlu.mat / frtslu.mat in each one.

%% ---- USER SETTINGS ----
SKIP_EXISTING = true;  % true = skip folders where frlu.mat + frtslu.mat already exist
                       % false = regenerate all, overwriting existing files
%% -----------------------

choice = uigetdir('','Select root directory to batch process');

sessionDirs = findSessionDirs(choice);
fprintf('Found %d session(s) to process.\n', length(sessionDirs));

nSkipped   = 0;
nProcessed = 0;
nFailed    = 0;

for j = 1:length(sessionDirs)
    sessionPath = sessionDirs{j};
    fprintf('[%d/%d] %s\n', j, length(sessionDirs), sessionPath);

    % --- Skip check ---
    if SKIP_EXISTING
        frluExists   = isfile(fullfile(sessionPath, 'frlu.mat'));
        frtsluExists = isfile(fullfile(sessionPath, 'frtslu.mat'));
        if frluExists && frtsluExists
            fprintf('  -> Skipping (files already exist)\n');
            nSkipped = nSkipped + 1;
            continue
        end
    end

    try
        mstbl  = readmatrix(fullfile(sessionPath, 'My_V4_Miniscope', 'timeStamps.csv'));
        mstbl  = mstbl(2:end,:);

        behtbl = readmatrix(fullfile(sessionPath, 'My_WebCam', 'timeStamps.csv'));
        behtbl = behtbl(2:end,:);

        match  = zeros(1, size(behtbl,1));
        for f  = 1:size(behtbl,1)
            t        = behtbl(f,2);
            [~,ind]  = min(abs(mstbl(:,2) - t));
            match(f) = ind;
        end

        frlu   = [behtbl(:,1), match'];
        frtslu = [behtbl(:,2), frlu];

        save(fullfile(sessionPath, 'frlu.mat'),   'frlu');
        save(fullfile(sessionPath, 'frtslu.mat'), 'frtslu');
        fprintf('  -> Saved frlu + frtslu (%d behavior frames)\n', size(frlu,1));
        nProcessed = nProcessed + 1;

    catch ME
        fprintf('  -> FAILED: %s\n  %s\n', sessionPath, strrep(ME.message, '%', '%%'));
        nFailed = nFailed + 1;
    end
end

fprintf('\nAll done.  Processed: %d  |  Skipped: %d  |  Failed: %d\n', ...
    nProcessed, nSkipped, nFailed);

%% --- Helper function ---
function sessionDirs = findSessionDirs(rootDir)
    sessionDirs = {};

    contents = dir(rootDir);
    subDirs  = {contents([contents.isdir]).name};
    subDirs  = subDirs(~ismember(subDirs, {'.','..'}));

    hasMiniscope = ismember('My_V4_Miniscope', subDirs);
    hasWebcam    = ismember('My_WebCam',        subDirs);

    if hasMiniscope && hasWebcam
        sessionDirs{end+1} = rootDir;
    end

    skipFolders = {'My_V4_Miniscope', 'My_WebCam'};
    for i = 1:length(subDirs)
        if ismember(subDirs{i}, skipFolders)
            continue
        end
        childPath     = fullfile(rootDir, subDirs{i});
        childSessions = findSessionDirs(childPath);
        sessionDirs   = [sessionDirs, childSessions]; %#ok<AGROW>
    end
end