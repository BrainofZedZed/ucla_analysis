%% Framegrabber
% User is prompted for a video and a single frame X times a minute is saved
% as a tiff in a folder named after the video.
% Editable params:  fps (frames per second, default = 25) and frame_per_min (how many
% frames per minute to take, default = 1)
clear;
%% editable params
fps = 25; % fps of recording
frame_per_min = 1; %how many frames per minute to take

%%
[vid_file, vid_path] = uigetfile('*.*','Select vid to process');
cd(vid_path);
vidObj = VideoReader(vid_file);
mkdir([vid_file(1:end-4) '_Frames'])
cd([vid_file(1:end-4) '_Frames'])

disp('Calculating number of frames in video...')
frames = 1:(fps*60/frame_per_min):vidObj.NumFrames;
for i = 1:length(frames)
    f = read(vidObj,frames(i));
    fname = ['frame' num2str(frames(i)) '.tiff'];
    imwrite(f,fname);
end
disp('Finished');