%% home
xz_folder = 'D:/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% lab
xz_folder = 'C:/Users/HonglabUser/Dropbox/XZ_projects/ToolBoxes';
sep = '/';
%% behavior analysis
addpath(genpath(xz_folder));
%% utility funcs home
addpath(genpath('D:/Matlab Repo/XZ_funkies'));
%% utility funcs lab
addpath(genpath('D:/Xingjian/Repositories/XZ_funkies'));
%% combine into 1 video file
VideoCombine(pwd, 'b',1, true, 'avi');

%% convert avi to seq

seqName = 'behavior.seq';
aviName = 'behav_video.avi';
seqIo([seqName],'frImgs',struct('codec','png'),'aviName',[aviName]);

%% annotate behavior
behavior_annotator;

%% construct behavior struct
annot_f = 'behavior.txt';

A = behaviorData('load', annot_f);

%% construct experiment struct
expInfo = {'XZ70_HCexp2','XZ71_HCexp2'};
ms_f1 = 'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\04_02_21\14_16_01_04_02_21_exp\Miniscope1_XZ70\processed\ms.mat';
ms_f2 = 'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\04_02_21\14_16_01_04_02_21_exp\Miniscope2_XZ71\processed\ms_cleaned.mat';
E_struct = ExpstructGen(expInfo, ms_f1, ms_f2, A);
save('E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\04_02_21\14_16_01_04_02_21_exp\E_struct.mat','E_struct');
%% Plot all cells with behavior patched
PlotSelectedCells(E_struct{1}, 1:100, 'attack', false)
PlotSelectedCells(E_struct{2}, 1:100, 'attack', false)