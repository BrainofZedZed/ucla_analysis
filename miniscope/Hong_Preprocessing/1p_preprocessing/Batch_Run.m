%% To use this batch processing script:
% all your avi files (make sure all are gray avis) are organized in
% experiment_directory/**/my_folder. my_folder can be any folder name, as long
% as it is consistant across experiments, and can be uniquely found. it can be in
% subfolder of any order, the script will do a recursive search and return 
% all directories matching the folder name. 




%% search folders
fname = 'Miniscope'; % change this to your folder name 
d = dir([pwd,'\**\']); % list all pathes under working directory
d = d([d(:).isdir]); % remove non-folder pathes
idx = [];
for i = 1:length(d)
    if contains(d(i).name, fname)
       idx = [idx,i];
    end
end

d = d(idx); % now d only contains target folders 

for i = 1:length(d)
    fprintf('%d, %s, %s \n', i, d(i).folder, d(i).name); % list all avi pathes, check before run!
end
%% if avi are RGB, convert to Gray first
for id = 1:length(d)
    full_path = [d(id).folder,'\',d(id).name];
    cd(full_path);
    pwd
    aviRGBtoGray(pwd, '', 'msCam', '');


end

%% Run batch preprocessing 
% if out of memory error, resume where the error happens

for id = 1:length(d) 
    full_path = [d(id).folder,'\',d(id).name];
    cd(full_path);
    pwd
    XZ_preprocessing_batch();
    close all;
    clearvars -except d id idx i full_path;
    pause(1) 
end
%% END %%
%% BEGIN ANOTHER BatchRun BY ASSIGNING TARGET DIRECTORIES
exp_directories = {
'D:\Xingjian\SH_hsyn_open\raw\SH21_HCexp4\H14_M17_S36';
'D:\Xingjian\SH_hsyn_open\raw\SH25_HCexp4\H14_M17_S34'
};
file_names = {
'msvideo.avi';
'msvideo.avi';
}
for id = 1:length(exp_directories)
    cd(exp_directories{id});
    pwd
    XZ_CNMFE_batch(exp_directories{id}, file_names{id});
    close all;
    clearvars -except exp_directories file_names id
    pause(1);
end