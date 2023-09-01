function convert_msCam1(filepath, outpath)
% make sure to setup the decoder path before using this function
% here is how: 
% 1. find ffmpegsetup.m, run it
% 2. in the pop up window, navigate to /ffmpeg-r8/ffmpeg-20200812-4ed6bca-win64-static/ffmpeg-20200812-4ed6bca-win64-static/bin
% 3. select ffmpeg.exe, click ok
% convert_msCam1({file_path})
% input is a cell containing all the root directories containing the avi
% files or the subfolders that contain avi files. the function does a 
% recursive search of all the subfolders, 2nd order subfolders and so on, 
% so if you want to convert a bunch of videos, best way is to navigate the 
% the very root directory, then run convert_msCam1({pwd})
% output videos will be saved at the /raw fold in the same folders of original
% videos



%% Convert FFV1 AVI to raw AVI, and rename files from multiple sessions to a single folder

for p = 1:length(filepath)
%     count = 0;
    msPath = [filepath{p}, '\**\'];
    aviFiles = dir([msPath, '*.avi']);
    for i = 1:length(aviFiles)
%         fileIn = [num2str(i-1), '.avi'];
        if and(nargin < 2, ~exist([aviFiles(i).folder,'\raw']))
            mkdir([aviFiles(i).folder,'\raw']);
        end
%         if ~strcmp(fileIn(1:5), 'msCam')
%             count = count + 1;
            pathIn  = [aviFiles(i).folder,'\', aviFiles(i).name];
            temp = split(aviFiles(i).name, '.');
            fname = temp{1};
            digit_i = regexp(fname, '\d*');
            fcount = fname(digit_i(end):end);
            fileOut = ['msCam', fcount, '.avi'];
            if nargin < 2
                pathOut = [aviFiles(i).folder,'\raw\', fileOut];
            else
                pathOut = [strrep(aviFiles(i).folder, filepath{p}, outpath{p}), '\', fileOut];
            end
            ffmpegtranscode(strrep(pathIn,'/','\'), strrep(pathOut,'/','\'), 'AudioCodec', 'none', 'VideoCodec', 'raw');
            fprintf(1, '%3d | %2d - %2d | %s -> %s\n', str2num(fcount), p, i, pathIn, pathOut);
%         end
    end
end

end