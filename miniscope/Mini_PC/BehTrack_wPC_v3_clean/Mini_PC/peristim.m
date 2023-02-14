 function [cc_out] = peristim(stimframes, spkfn, fps, tfile, tpath)
%% params to play with
window = 10;    % time in seconds to look at events peristim
binsz = .2;    % size of time bins for correlation activity

mscamnum = 0;
dummybehavcamnum = 1;
%% get stim frames, spk data, and fps
% [stimfile, stimpath] = uigetfile('Select OFOLM analysis file');
% load([stimpath stimfile], 'stimframes','spkfn', 'fps');

%% translate stim frames to from dummy beh cam to miniscope
% [tfile, tpath] = uigetfile('.dat','Select miniscope timestamp file');  % file with timestamps of mscam and fake behcam

tbl = readtable(strcat(tpath, tfile));
tbl = table2array(tbl);

msframes = [];
dummybehavframes = [];

for i = 1:size(tbl,1)
    if tbl(i,1) == mscamnum
        msframes = [msframes; tbl(i,:)];
    elseif tbl(i,1) == dummybehavcamnum
        dummybehavframes = [dummybehavframes; tbl(i,:)];
    end
end

msstimframes = [dummybehavframes(stimframes(:,1),3) dummybehavframes(stimframes(:,2),3)];

% find matching ms frame for dummy beh frame
match1 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,1);
    [~,ind] = min(abs(msframes(:,3) - t));
     match1(i) = ind;
end

match2 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,2);
    [~,ind] = min(abs(msframes(:,3) - t));
     match2(i) = ind;
end
match1 = match1';
match2 = match2';

window = window*fps;

pre = match1 - window;
post = match2 + window;
peristimframes = [pre match1 match2 post];

% HARDCODE FOR ANALYSES DONE AT REDUCED FPS (eg 30 down to 15)

if fps == 15 | fps == 10
    peristimframes = peristimframes / 2;
    peristimframes = round(peristimframes);
end


%% calculate event rate peristim

% first binarize the spkfn signal
spk = spkfn;
spk(spk > 0) = 1;
d = peristimframes(1,4) - peristimframes(1,1);
stim_spk = zeros(size(peristimframes,1),d);
mean_spk = zeros(size(spk,1),d);


% average over stim periods fore each cell
try
    for i = 1:size(spk,1)
       for j = 1:size(peristimframes,1)
           stim_spk(j,:) = spk(i,peristimframes(j,1):peristimframes(j,1)+d-1);
       end
       avg = mean(stim_spk,1);
       mean_spk(i,:) = avg;
    end
catch
    peristimframes = peristimframes(1:end-1,:);
    for i = 1:size(spk,1)
       for j = 1:size(peristimframes,1)
           stim_spk(j,:) = spk(i,peristimframes(j,1):peristimframes(j,1)+d-1);
       end
       avg = mean(stim_spk,1);
       mean_spk(i,:) = avg;
    end    
end

t1 = peristimframes(1,2) - peristimframes(1,1);
t2 = peristimframes(1,3) - peristimframes(1,1);
t3 = peristimframes(1,4) - peristimframes(1,1);

for i = 1:size(mean_spk,1)
    avgpre(i) = mean(mean_spk(i,1:t1));
    avgstim(i) = mean(mean_spk(i,t1+1:t2));
    avgpost(i) = mean(mean_spk(i,t2+1:t3));
end
   avgpre = avgpre';
   avgstim = avgstim';
   avgpost = avgpost';
   
   period_mean_spk = [avgpre avgstim avgpost];

%% do correlation coefficient matrix
% nonadjustable params

binsz = binsz*fps;  % convert to frames
numbins = round(length(spkfn)/binsz)-2; 

spkt = zeros(size(spkfn,1), numbins);

% binarize firing for each period
for i = 1:size(spkfn,1)
    for j = 1:(numbins-1)
        for k = 1:binsz
            if spkfn(i,(k+(j*binsz))) > 0
                spkt(i,j) = 1;
            end
        end
    end
end

% convert stimframes to stim bins
peristimbins = peristimframes / binsz;
peristimbins = floor(peristimbins);

% correlation coefficient function takes in variables (Cells) as columns
% and observations (timepoints) as rows
spkt = spkt.';

% create correlation coefficient matrices
nn = size(spkfn,1);
nstim = size(peristimbins,1);

Rprior = zeros(nn,nn,nstim);
Rstim = Rprior;
Rpost = Rprior;

try
    for i = 1:nstim
        Rprior(:,:,i) = corrcoef(spkt(peristimbins(i,1):peristimbins(i,2)-1,:));
        Rstim(:,:,i) = corrcoef(spkt(peristimbins(i,2):peristimbins(i,3),:));
        Rpost(:,:,i) = corrcoef(spkt(peristimbins(i,3)+1:peristimbins(i,4),:));
    end
catch
    peristimbins = peristimbins(1:end-1,:);
    nstim = size(peristimbins,1);
    for i = 1:nstim
        Rprior(:,:,i) = corrcoef(spkt(peristimbins(i,1):peristimbins(i,2)-1,:));
        Rstim(:,:,i) = corrcoef(spkt(peristimbins(i,2):peristimbins(i,3),:));
        Rpost(:,:,i) = corrcoef(spkt(peristimbins(i,3)+1:peristimbins(i,4),:));
    end
end

Rprior_abs = abs(Rprior);
Rstim_abs = abs(Rstim);
Rpost_abs = abs(Rpost);

%% average across trials (with abs)
Rprior_abs_mean = nanmean(Rprior_abs,3);
Rstim_abs_mean = nanmean(Rstim_abs,3);
Rpost_abs_mean = nanmean(Rpost_abs,3);

%% collect data under diagonal for avg corr coeff across all cells
%prior mean
for i = 2:length(Rprior_abs_mean)
    meanR_prior(i) = nanmean(Rprior_abs_mean(i, 1:(i-1)));
end
all_meanR_prior = nanmean(meanR_prior);

%stim mean
for i = 2:length(Rstim_abs_mean)
    meanR_stim(i) = nanmean(Rstim_abs_mean(i, 1:(i-1)));
end
all_meanR_stim = nanmean(meanR_stim);

%post mean
for i = 2:length(Rpost_abs_mean)
    meanR_post(i) = nanmean(Rpost_abs_mean(i, 1:(i-1)));
end
all_meanR_post = nanmean(meanR_post);

cc_out = struct;
cc_out.timestamps = tbl;
cc_out.peristimframes = peristimframes;
cc_out.peristimbins = peristimbins;
cc_out.meanspkprob = mean_spk;
cc_out.periodmeanspk = period_mean_spk;

cc_out.all_meanR_prior = all_meanR_prior;
cc_out.all_meanR_stim = all_meanR_stim;
cc_out.all_meanR_post = all_meanR_post;

cc_out.Rprior_abs_mean = Rprior_abs_mean;
cc_out.Rstim_abs_mean = Rstim_abs_mean;
cc_out.Rpost_abs_mean = Rpost_abs_mean;


 end