function aviRGBtoGray(dir_f, tar_dir, prefr, prefw)
% aviRGBtoGray(dir_f, tar_dir, prefr, prefw)
% input: 
% dir_f, directory of target video files, default .avi files named in order
% tar_dir, director to save the converted grayscale videos. 
% prefr, read prefix
% prefw, prefix of write avi files
if nargin < 1
    dir_f = pwd;
    tar_dir = strcat(dir_f, '/ms/');
    prefr = '';
    prefw = 'msCam';
elseif nargin < 2
    tar_dir = strcat(dir_f, '/ms/');
    prefr = '';
    prefw = 'msCam';
elseif nargin < 3
    prefr = '';
    prefw = 'msCam';
elseif nargin < 4
    prefw = 'msCam';
end

if isempty(tar_dir)
    tar_dir = strcat(dir_f, '/ms/');
end

if ~exist(tar_dir)
    mkdir(tar_dir)
end



    %% set the useful constants
    %%
    all_v = dir([dir_f, '/',prefr,'*.avi']); % all_v is a numFile x 1 struct with field name, folder, date, bytes, isdir, datenum
    % sort files by name, 0, 1, 2, 3, etc.
    avi_cell = struct2cell(all_v); % convert to cell, 6 x numFile
    avi_names = avi_cell(find(strcmp(fields(all_v), 'name')), :);
    avi_id_list = [];
    for i = 1:length(avi_names)
       temp = split(avi_names{i}, '.');
       fname = temp{1};
       digit_i = regexp(fname, '\d*');
       avi_id_list = [avi_id_list, str2num(fname(digit_i(end):end))];
    end
    [~, forder] = sort(avi_id_list);
    all_v = all_v(forder); % reorder the struct to the video order
    avi_names = avi_names(forder);
    %% start read each avi by order and combine them into 1 giant .mat file
    for i = 1:length(avi_names)
        fprintf('now converting file %s', avi_names{i});
        tic;
        vid = VideoReader([dir_f,'/',avi_names{i}]);
        this_v = zeros(vid.Height, vid.Width, vid.NumFrames);
        vidw = VideoWriter(strcat(tar_dir, prefw, avi_names{i}), 'Grayscale AVI');
        open(vidw);
        for j = 1:vid.NumFrames
            frame = rgb2gray(readFrame(vid));
            this_v(:,:,j) = frame;
        end
        this_v = this_v/255;
        writeVideo(vidw, this_v);
        delete(vid);
        close(vidw);
        delete(vidw);
        t = toc;
        fprintf('video %s finished \n', avi_names{i});
        fprintf('%d seconds left \n', t *(length(avi_names) - i));
    end
end











        
        