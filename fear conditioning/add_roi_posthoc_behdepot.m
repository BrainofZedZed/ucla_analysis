    % roi name
    roi_name = 'reward';

    % Prompt the user to select a directory
    selectedDir = uigetdir('', 'Please select a directory for batch analysis');
    
    % Find all subdirectories within the selected directory
    subDirs = dir(selectedDir);
    subDirs = subDirs([subDirs.isdir]);
    subDirs = subDirs(~ismember({subDirs.name}, {'.', '..'}));
    
    % Iterate over each subdirectory
    for i = 1:numel(subDirs)
        subDirPath = fullfile(selectedDir, subDirs(i).name);
        
        % Find the file matching the pattern '*-*-*_*-*-*.mat' exp file
        expFile = dir(fullfile(subDirPath, '*-*-*_*-*-*.mat'));
        if isempty(expFile)
            warning('Warning: No matching file found in the directory');
            continue;  % Skip to the next subdirectory
        end

        % Find the avi file
        aviFile = dir(fullfile(subDirPath, '*.avi'));

        % Create a video object
        vidObj = VideoReader(fullfile(subDirPath, aviFile.name));
        
        % Read the first frame
        firstFrame = readFrame(vidObj);
        
        % Display the first frame
        imshow(firstFrame);
        title('Draw the ROI')
        hold on;
        roi = drawpolygon;
        roi_limits = roi.Position;
        close;

        % get name if not already assigned
        if ~exist('roi_name')
            prompt = {'Assign name to ROI'};  % give name to ROI
            dlgtitle = 'Input';
            dims = [1 40];
            definput = {''};
            roi_name = inputdlg(prompt,dlgtitle,dims,definput);
        end
        
        % Initialize the variables
        exp_ID = [];
        
        % Process each matching file in the subdirectory
        for j = 1:numel(expFile)
            
            % Find the '_analyzed' directory
            analyzedDir = dir(subDirPath);
            analyzedDir = analyzedDir([analyzedDir.isdir]);
            analyzedDir = analyzedDir(~ismember({analyzedDir.name}, {'.', '..'}));
            analyzedDir = analyzedDir(contains({analyzedDir.name}, '_analyzed'));
            
            if isempty(analyzedDir)
                warning('Warning: "_analyzed" directory not found');
                continue;  % Skip to the next matching file
            end
            
            analyzedDirPath = fullfile(subDirPath, analyzedDir.name);

            % Load Tracking.mat file from _analyzed dir
            trackingFilePath = fullfile(analyzedDirPath, 'Tracking.mat');
            if ~isfile(trackingFilePath)
                warning('Warning:  "Tracking.mat" file not found');
                continue;
            end
            load(trackingFilePath);

            % use between ears as location
            loc = Tracking.Smooth.Implant;

            % find when loc is within new roi, create output struct
            in_roi = inpolygon(loc(1,:), loc(2,:), roi_limits(:,1), roi_limits(:,2));  % find frames when location is within ROI boundaries
            PerTimeInROI = sum(in_roi) / length(in_roi);
            inROIvector = in_roi;
            Bouts = findStartStop(inROIvector);

            % load Behavior file, add new roi to Behavior.Spatial
            behaviorFilePath = fullfile(analyzedDirPath, 'Behavior.mat');
            if ~isfile(behaviorFilePath)
                warning('Warning:  "Tracking.mat" file not found');
                continue;
            end
            load(behaviorFilePath);
            Behavior.Spatial.(roi_name).PerTimeInROI = PerTimeInROI;
            Behavior.Spatial.(roi_name).inROIvector = inROIvector;
            Behavior.Spatial.(roi_name).Bouts = Bouts;
            save(behaviorFilePath,"Behavior");
        end
    end

    %%
    %% HELPER FXNS
    %%

    % OUTPUT: start_inds, stop_inds

function [varargout] = findStartStop(binary_vector)

    % Take differential of binary_vector
    diff_vector = diff(binary_vector);
    
    % Adjust diffential to match length & check if 1st frame is 1/0
    if binary_vector(1) == 1
        diff_vector = [1 diff_vector];
    elseif binary_vector(1) == 0
        diff_vector = [0 diff_vector];
    end

    % Adjust diffential if last frame is positive
    if binary_vector(end) == 1
        diff_vector = [diff_vector -1];
    end
    
    % Extract start and stop inds from diff_vector (start frame = 1; stop (+ 1) frame = -1)
    start_inds = find(diff_vector' == 1);
    stop_inds = find(diff_vector' == -1) - 1;
    
    nOutputs = nargout;
    varargout = cell(1, nOutputs);
    
    if nOutputs == 1 
        varargout{1} = [start_inds, stop_inds];
    elseif nOutputs == 2
        varargout{1} = start_inds;
        varargout{2} = stop_inds;
    end

end