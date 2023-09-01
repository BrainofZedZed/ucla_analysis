%% get ready
clear all;
F = struct();
MouseN = 2; % # in this pair, corresponding to the number in behavior annotation (usually 1 is the marked one if annotated by XZ)
F.MouseN = MouseN;
FPS = 15;
nVideo = 3;
No = transpose(1:nVideo);
MouseID = cell(nVideo,1); MouseID(:) = {'XZ86'}; 
date = cell(nVideo,1); date(:) = {'20210419'};
session = {'sep';'exp';'exp'};
time = {'14_09_49'; '14_22_31';'14_42_18'};
% path for timestamps
filePath = {'E:\MiniscopeData(processed)\NewCage_free_dual\mDLX_vs_mDLX\XZ86_XZ83(m)\2021_04_19\14_09_49_sep\Miniscope1_XZ86';...
    'E:\MiniscopeData(processed)\NewCage_free_dual\mDLX_vs_mDLX\XZ86_XZ83(m)\2021_04_19\14_22_31_exp\Miniscope1_XZ86';...
    'E:\MiniscopeData(processed)\NewCage_free_dual\mDLX_vs_mDLX\XZ86_XZ83(m)\2021_04_19\14_42_18_exp\Miniscope1_XZ86'};
% path for ms file and concatenated videos
% [~,ei] = regexp(filePath{1},'2021_\d*_\d*');
% msPath = filePath{1};
% msPath = [msPath(1:ei),'\',MouseID{1}];
msPath = 'E:\MiniscopeData(processed)\NewCage_free_dual\mDLX_vs_mDLX\XZ86_XZ83(m)\2021_04_19\XZ86_1';
fileName = {'msvideo_dFF.avi'; 'msvideo_dFF.avi';'msvideo_dFF.avi'};
F.ExperimentID = ['PairD2_',date{1},'_F']; % change Pair#
F.ExperimentID
tempstr = strsplit(F.ExperimentID,'_');

saveName = [tempstr{1},'_',MouseID{1},'_',tempstr{2},'_F.mat'];
Ts = cell(1,nVideo);
qt = cell(1,nVideo);
for i = 1:nVideo
    if exist([filePath{i},'\','timeStamps_ds.csv'])
        temp = csvread([filePath{i},'\','timeStamps_ds.csv'],1);
    else
        temp = csvread([filePath{i},'\','timeStamps.csv'],1);
    end
    if exist([filePath{i},'\','headOrientation_ds.csv'])
        headori = csvread([filePath{i},'\','headOrientation_ds.csv'],1);
    else
        headori = csvread([filePath{i},'\','headOrientation.csv'],1);
    end
    qt{i}.data = headori;
    temppath = strsplit(filePath{i},'\');
    behavpath = [strjoin(temppath(1:end-1), '\'),'\BehavCam_0'];
    bets = csvread([behavpath,'\timeStamps.csv'],1);
    Ts{i}.Bv = bets(:,2);
    Ts{i}.Ms = temp(:,2);
    Ts{i}.Qt = headori(:,1);
end


%% MS
MS = cell(1,nVideo);
startFrame = ones(nVideo,1);
endFrame = [];
for i = 1:nVideo
   switch i
       case 1
           load([msPath,'\ms_sep.mat']);
       case 2
           load([msPath,'\ms_exp_1.mat']);
       case 3
           load([msPath,'\ms_exp_2.mat']);
              end
   if isfield(ms,'cell_label')
       ms.goodCellVec = ms.cell_label;
       ms = rmfield(ms,'cell_label');
   end
   if isfield(ms,'vidObj')
       ms = rmfield(ms, 'vidObj');
   end
   MS{i} = ms;
   endFrame = [endFrame; size(ms.FiltTraces,1)];
end
F.MS = MS;
endFrame = cumsum(endFrame);
startFrame(2:end) = startFrame(2:end)+endFrame(1:end-1);
totalFrame = endFrame-startFrame+1;
duration = totalFrame/FPS;
%% videoInfo
F.videoInfo = table(No,MouseID,date,session,...
    time, filePath, fileName,startFrame,...
endFrame, totalFrame,duration);
%% align timestamps
F.TimeStamp.Ts = Ts;
mapTs = cell(1,nVideo);
for i = 1:nVideo
    [~, B2M] = TStampAlign(Ts{i}.Ms,Ts{i}.Bv);
    mapTs{i}.B2M = B2M;
    [~, M2B] = TStampAlign(Ts{i}.Bv, Ts{i}.Ms);
    mapTs{i}.M2B = M2B;
end
F.TimeStamp.mapTs = mapTs;
%% head orientation
F.HeadOrientation.qt = qt;
%% Behavior
Behavior = cell(1,nVideo);
A={};
for i = 1:nVideo
    temppath = strsplit(filePath{i},'\');
    behavpath = [strjoin(temppath(1:end-1), '\'),'\BehavCam_0'];
    if exist([behavpath,'\behavior.txt'])
        [B,A] = BehavStruExtract([behavpath,'\behavior.txt'], MouseN);
        Behavior{i} = B;
    end
end
F.Annotation.annBD = A;
F.Behavior = Behavior;
%% Event
F.Event.VideoEnd = endFrame;
F.Event.VideoStart = startFrame;
F.Event.VideoFrame = totalFrame;
F.Event.VideoDuration = totalFrame/FPS;
%% Event table
% Place Holder
%% save F structure
save(saveName,'F');

