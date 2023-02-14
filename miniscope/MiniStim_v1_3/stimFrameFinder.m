function [stimframes, stimframes_ms] = stimFrameFinder(ts, ds, mscamnum, stimcamnum, savepath)
% Goes through videos containing light flashes (mirroring light delivery to
% animal), creates reference frame of each video from median pixel values,
% then looks for changes in overall brightness. 
% Increased periods of brightness defined as a stimulus. 

% NB designed around 3s stim periods 7Hz, may not work well with extremely
% short or fast stim parameters
% NB designed for color video and blue light stim. Alter frame processing
% code if conditions differ

% OUTPUT:
% '_stimframes.mat' containing matrix with stimframes [start, stop]
% '_stimframes_raw_data.mat' containing brightness values

% get video info and format
disp('Looking for light periods. Select the first video of the series.')
[path_name, file_base, file_fmt] = vid_info;
file_base = char(file_base);
file_fmt = char(file_fmt);
dirst = dir([path_name, file_base, '*', '.avi']); % struct containing directory of all files

% brightness mean record matrix
bmean_rec = [];

% natural language sort file names
for i = 1:length(dirst)
    names(i) = {dirst(i).name};
end
names_natsort = natsortfiles(names);

%% go through vids, create reference, find blue brightness
for i = 1:size(dirst,1)
    
    filename = [dirst(i).folder '\' char(names_natsort(i))];
    v = VideoReader(filename); % open VideoReader object
    ct = 1; % count frames
    
    % grab frames, take blue channel, and create blue channel collection
    while hasFrame(v)
            frame = readFrame(v); 
            frame_blue = frame(:,:,3); 
            collection(:,:,ct) = frame_blue;
            ct = ct+1;
    end
    
    % take median of blue video to make reference
    collection = uint8(collection);
    reference = median(collection,3);
    
    % find difference between each frame and reference
    col2 = collection - reference;
    
    % reset collection for next video
    collection = zeros(size(col2,1), size(col2,2), size(col2,3));
    
    % take the mean brightness of each frame
    bmean = zeros(size(col2,3),1);
    for j = 1:size(col2,3)
        bmean(j) = mean(mean(col2(:,:,j)));
    end
    
    % create brightness mean record of all frames
    bmean_rec = [bmean_rec; bmean];
    disp(['Done with video ' num2str(i) ' of ' num2str(size(dirst,1))]);
end

%% look for periods of increased brightness
cutoff = 0.5; % relative value for brightness to be considered stim, based on max brightness
minframedist = 60;  % minimum distance between two different stim (in frames)

% binarize brightness values based on max differential brightness and
% cutoff for stim
bmean_rec2(bmean_rec > (max(bmean_rec)*cutoff)) = 1;
bmean_rec2(bmean_rec <= (max(bmean_rec)*cutoff)) = 0;

bmean_scaled = mat2gray(bmean_rec);

figure;
plot(bmean_rec2);
hold on;
plot(bmean_scaled);
title('Stimulus times')
legend('inferred stim times', 'raw brightness values');
% get indexes of stims, where they end and start
ind = find(bmean_rec2 == 1);
inddif = ind(1:end-1) - ind(2:end);

fins = find(abs(inddif) > minframedist);
fins = ind(fins);
fins = [fins ind(end)];

starts = find(abs(inddif) > minframedist);
starts = starts + 1;
starts = ind(starts);
starts = [ind(1) starts];

starts = starts';
fins = fins';

stimframes = [starts fins];

stimframes_ms = alignStimFunc(ts, ds, mscamnum, stimcamnum, stimframes);
%% save 
save([savepath '_stimframes.mat'], 'stimframes', 'stimframes_ms', 'bmean_rec', 'bmean_rec2');
disp('File saved')
end