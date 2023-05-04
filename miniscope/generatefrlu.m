% USE: generate frame lookup (frlu) and frame timestamp lookup (frtslu) files
% SETUP: run file, select folder containing multiple days of miniscope
% recordings. Each day is assumed to have the structure [Day] > [Time] >
% [My_V4_Miniscope] and [My_Webcam]
% OUTPUT: saves two files, frlu.mat and frtslu.mat, in experiment folder

choice = uigetdir('','Select directory above all other batched directories to generate frame lookup table');
cd(choice);
top_dir = dir;%('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze

for i = 3:length(top_dir)
    cd(choice);
    iname = top_dir(i).name;
    cd(iname)
    idir = dir;
    for j = 3:length(idir)
        cd(idir(j).name);
        a = dir;
        %cd(a(3).name);
        %a = dir;
        %cd(a(3).name);
        cd('My_V4_Miniscope')
        mstbl = readmatrix('timeStamps.csv');
        mstbl = mstbl(2:end,:);
        cd ../;
        cd('My_WebCam')
        behtbl = readmatrix('timeStamps.csv');
        behtbl = behtbl(2:end,:);
        cd ../

        % for each behavior frame, finds closest miniscope frame 
        match = zeros(1,length(behtbl));
        for f = 1:size(behtbl,1)
            t = behtbl(f,2);
            [~,ind] = min(abs(mstbl(:,2) - t));
             match(f) = ind;
        end

        %disp(['Aligned timepoints for ' top_dir(i).name]);
    %% make a frame lookup (frlu) table, col1 is behavior frame, col2 is miniscope frame
    % make another version with the timestamp in there
        frlu = [];
        frlu(:,1) = behtbl(:,1);
        frlu(:,2) = match';
        frtslu = [behtbl(:,2),frlu];
        
        save('frlu.mat','frlu');
        save('frtslu.mat', 'frtslu');
        
        cd ../
    end
end