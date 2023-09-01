function vmat_total = VideoCombine(dir_f, vtype, t_downsample, sa, savetype)
% input: 
% VideoCombine(dir_f, vtype, sa, savetype)
% dir_f, directory of target video files, default .avi files named in order
% vtype, 'm' for miniscope, 'b' for behavior
% starting from 0. 
% vtype, 'mat' or 'avi'
% t_downsample, temporal downsample ratio, default 1(no downsample)
% sa, save or not, default false
% savetype, output file type, 'avi' or 'mat'

if nargin < 2
    vtype = 'm';
    sa = false;
    t_downsample = 1;
    savetype = 'avi';
elseif nargin < 3
    sa = false;
    t_downsample = 1;
    savetype = 'avi';
elseif nargin < 4
    sa = false;
    savetype = 'avi';
elseif nargin < 5
    savetype = 'avi';
end

if ~(strcmp(vtype, 'b') | strcmp(vtype, 'm'))
    error('invalid video type. b for behavior, m for miniscope');
end

if ~(strcmp(savetype, 'avi') | strcmp(savetype, 'mat'))
    error('invalid saving type');
end

if ispc
    separator = '\';
else
    separator = '/';
end


    %% set the useful constants
    cchannel = 3;
    %%
    all_v = dir(strcat(dir_f, separator,'*.avi')); % all_v is a numFile x 1 struct with field name, folder, date, bytes, isdir, datenum
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
    %% preallocate the array
    vs = cell(1, length(avi_names));
    total_frame = 0;
    for k = 1:length(avi_names)
       tempV = VideoReader(strcat(dir_f, separator, avi_names{k}));
       vs{k} = tempV;
       total_frame = total_frame + tempV.NumFrames;
       disp(k);
    end
    v = vs{1};
    total_f = 0;
    xwidth = v.Width;
    ywidth = v.Height;
    fr = round(v.FrameRate);
    vmat_total = zeros(ywidth, xwidth, total_frame, 'uint8');
    fprintf('combining %d video files...\n', length(avi_names));
    fprintf('allocated %d GBs of memory...\n', prod(size(vmat_total))/1024/1024/1024);
    for i = 1:length(vs)
       tic;
       v = vs{i};
       vmat = read(v);  % default last dimension is time 
       if strcmp(vtype, 'b')
           vmat_bw = squeeze(0.2989 * vmat(:,:,1,:) + 0.5870 * vmat(:,:,2,:) + 0.1140 * vmat(:,:,3,:));
       elseif strcmp(vtype, 'm')
           vmat_bw = squeeze(vmat(:,:,1,:));  % in this case, miniscope all 3 channels are the same 
       end
       vmat_total(:,:,total_f+1 : total_f+size(vmat_bw, 3)) = vmat_bw;
       total_f = total_f + size(vmat_bw, 3);
       fprintf('%s is processed\n', avi_names{i});
       fprintf('%d of %d files processed...\n', i, length(avi_names));
       fprintf('%.2f s remaining...\n', (length(avi_names) - i)*toc);
       delete(v);   
    end
    % temporal downsample
    
    if t_downsample > 1
        total_frame = size(vmat_total,3);
        frame_to_down_sample = total_frame - mod(total_frame, t_downsample);
        vmat_down = squeeze(uint8(mean(reshape(vmat_total(:,:,1:frame_to_down_sample), ywidth, xwidth, t_downsample, []),3)));
            % also downsample timeStamp file
        if isfile([dir_f,separator,'timeStamps.csv']) & sa
            tStamp = csvread([dir_f, separator, 'timeStamps.csv'],1);
            tStamp_ds = transpose(reshape(tStamp(1:frame_to_down_sample,2),2,[]));
            tStamp_ds = mean(tStamp_ds,2);
            to_write = [transpose(0:1:size(vmat_down,3)-1),tStamp_ds];
            to_write = array2table(to_write);
            to_write.Properties.VariableNames(1:2) = {'Frame Number','Time Stamp (ms)'};
            writetable(to_write,'timeStamps_ds.csv');
            fprintf('downsampled time stamp csv is stored as timeStamp_ds.csv! \n');
        end
        % also downsample headOrientation file
        if isfile([dir_f,separator,'headOrientation.csv']) & sa
            headori = csvread([dir_f,separator,'headOrientation.csv'],1);
            headori_ds = squeeze(mean(reshape(headori(1:frame_to_down_sample,:),2,[],size(headori,2)),1));
            headori_ds = array2table(headori_ds);
            headori_ds.Properties.VariableNames(1:5) = {'Time Stamp (ms)','qw','qx','qy','qz'};
            writetable(headori_ds,'headOrientation_ds.csv');
            fprintf('downsampled headOrientation csv is stored as headOrientation_ds.csv! \n');
            
        end
    end
    
    

        
    
    if sa
        if strcmp(savetype, 'mat')
            fprintf('saving to .mat file at %s...\n', dir_f);
            if strcmp(vtype, 'm')
                save(strcat(dir_f, separator, 'video_total.mat'), 'vmat_total');
            else
                save(strcat(dir_f, separator, 'behav_video.mat'),'vmat_total');
            end
        else
            fprintf('saving to .avi file at %s...\n', dir_f);
            if strcmp(vtype, 'm')
                viw = VideoWriter([dir_f, separator, 'msvideo.avi'], 'Grayscale AVI');
            else
                viw = VideoWriter([dir_f, separator, 'behav_video.avi'], 'Motion JPEG AVI');
            end
            if strcmp(vtype, 'b')
                viw.FrameRate = 30;
            else
                viw.FrameRate = 15;
            end
            open(viw);
            
            if t_downsample > 1
                for i = 1:size(vmat_down,3)
                    writeVideo(viw, vmat_down(:,:,i));
                end
                fprintf('downsampled concatenated video saved!\n');
            else
                for i = 1:size(vmat_total,3)
                    writeVideo(viw, vmat_total(:,:,i));
                end
                fprintf('original sized concatenated video saved!\n');
            end
            close(viw);
            delete(viw);
        end
    else
        fprintf('combined video not saved\n');
    end
end


