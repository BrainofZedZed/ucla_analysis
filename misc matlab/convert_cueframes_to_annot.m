% Script to convert FCXD cue frames to Bento .annot format
% Also interpolates calcium data (miniscope or photometry) to match video
% length for display purposes
% NOTE: assumes that calcium and video data begin together and end
% together. If calcium data starts/ends outside video time, manually trim
% calcium variable so start and end match video

cueframes_file = 'cueframes.mat'; % file holding cueframes
video_file = 'concat_beh.avi'; % file of behavior video
calcium_file = 'cnmf_c.mat'; % file holding calcium data with solo variable
do_interp_calcium = true; % to do calcium alignment to video

% Load the data from cueframes.mat
load(cueframes_file);

% Get length of video for annotation start and end time
v = VideoReader(video_file);

% Get full video file path
vid_path = which(video_file);

% align calcium
if do_interp_calcium
    tmp = load(calcium_file);
    fieldName = fieldnames(tmp);
    cnmf_c = tmp.(fieldName{1}); % Extract the variable
    calcium_length = length(cnmf_c);
    vid_frames = v.NumFrames;
    newX = linspace(1, calcium_length, vid_frames);
    for i = 1:size(cnmf_c, 1)
        cnmf_c_aligned(i, :) = interp1(1:calcium_length, cnmf_c(i, :), newX, 'linear');
    end

    cnmf_c_aligned = (cnmf_c_aligned - min(cnmf_c_aligned, [], 2)) ./ (max(cnmf_c_aligned, [], 2) - min(cnmf_c_aligned, [], 2));

    save('cnmf_c_aligned.mat',"cnmf_c_aligned");
end

% Define output file name
outputFileName = 'converted_data.annot';

% Assuming annotation start time, stop time, and frame rate are known or extracted
annotationStartTime = 0;
annotationStopTime = v.Duration;
frameRate = v.FrameRate;

% Open file for writing
fileID = fopen(outputFileName, 'w');

% Write metadata to the file
fprintf(fileID, 'Bento annotation file\n');
fprintf(fileID, 'Movie file(s):  %s\n\n', vid_path); % Keeping movie file path blank
fprintf(fileID, 'Stimulus name: \n');
fprintf(fileID, 'Annotation start time: %e\n', annotationStartTime);
fprintf(fileID, 'Annotation stop time: %d\n', annotationStopTime);
fprintf(fileID, 'Annotation framerate: %f\n\n', frameRate);

% Write channels
fprintf(fileID, 'List of channels:\nch1\n\n');

% Write list of annotations based on cueframes
fields = fieldnames(cueframes);
fprintf(fileID, 'List of annotations:\n');
for i = 1:length(fields)
    fprintf(fileID, '%s\n', fields{i});
end

% Write space and channel name
fprintf(fileID, '\nch1----------')

% For each cue, write its events
for i = 1:length(fields)
    cueData = cueframes.(fields{i});
    fprintf(fileID, '\n>%s\nStart\t Stop\t Duration \n', fields{i});
    for j = 1:size(cueData, 1)
        startFrame = floor(cueData(j, 1));
        stopFrame = floor(cueData(j, 2));
        duration = stopFrame - startFrame;
        fprintf(fileID, '%d\t%d\t%d\n', startFrame, stopFrame, duration);
    end
end
fprintf(fileID,'\n\n');

% Close the file
fclose(fileID);

