function corrStimFunc(stimframes, spk, dur, fps, binsz_orig, Rwnd_orig, savepath, dosave)
%% corrStimFunc:
% takes in stimframes and signal, computes
% cross-cell correlations of activity by defining pre, stim, and post time
% bins, chunking frame-based data into larger time bins (binsz_orig), 
% binarizing activity, then taking average across a sliding window
% (Rwnd_orig), and then averaging over all stimuli
% NB:  looks at absolute value of correlations, and in order to avoid
% averaging across different stim periods, ignores that last Rwnd
% period of each pre, stim, and post period (because cannot average over a
% smaller window)

%% gather data for peri stim periods  
% format data
spk(spk > 0) = 1;
binsz_frm = round(binsz_orig*fps);
Rwnd = floor(Rwnd_orig * (fps/binsz_frm));
      
corrframes = stimframes;
corrframes(:,1) = corrframes(:,1) - (fps*dur);
corrframes(:,2) = corrframes(:,2) + (fps*dur);

% initialize  matrices
thisstim = nan(size(spk,1), max(corrframes(1,2) - corrframes(1,1)));

% get start and stop points for each stim, calculate peristim times, then
% collect spk data from that period, iterating over stims and cells

try
    for st = 1:size(corrframes,1)
        for i_c = 1:size(spk,1)
            thisstim(i_c,1:length(spk(i_c,corrframes(st,1):(corrframes(st,2)-1)))) = spk(i_c,corrframes(st,1):(corrframes(st,2)-1));
        end
        allstimspk(:,:,st) = thisstim;
        thisstim = nan(size(spk,1), (corrframes(1,2) - corrframes(1,1)));
    end
% JF commented all of this (ln39-ln49 out 3.11.21 because stim frames @ end of
% recording have already been removed by this point of analysis.
% catch 
% catch statement in case last stim lands too close to end of recording 
%     allstimspk = [];
%     corrframes = corrframes(1:end-1,:);
%     for st = 1:size(corrframes,1)
%         for i_c = 1:size(spk,1)
%             thisstim(i_c,1:length(spk(i_c,corrframes(st,1):corrframes(st,2)-1))) = spk(i_c,corrframes(st,1):(corrframes(st,2)-1));
%         end
%         allstimspk(:,:,st) = thisstim;
%         thisstim = nan(size(spk,1), (corrframes(1,2) - corrframes(1,1)));
%     end
 end

% convert stimframes to stim bins, relative to start of period
% identify pre, stim on, stim off, and end bins

nbins = floor(size(allstimspk,2) / binsz_frm);
stimbinon = floor((fps*dur) / binsz_frm);
stimbinoff = floor(nbins - stimbinon);

peristimbins = [1, stimbinon, stimbinoff, nbins];

                
%% create binned activity periods
numbins = peristimbins(4);
nn = size(allstimspk,1);
nstim = size(allstimspk,3);
spkt = zeros(nn, numbins, nstim);

% binarize firing for each bin period for each cell for each stim
% ugly nest of for loops but it works ¯\_(?)_/¯
for st = 1:nstim
    for i = 1:nn
        for j = 1:numbins
            for k = 1:binsz_frm
                    if allstimspk(i,(k+(j*binsz_frm)-binsz_frm),st) > 0
                        spkt(i,j,st) = 1;  % contains binned and binarized activity
                    end
                end
            end
        end
end


% correlation coefficient function takes in variables (Cells) as columns
% and observations (timepoints) as rows, so we need to transpose data
allstimspkT = [];
for st = 1:nstim;
    spkt2 = spkt(:,:,st);
    spkt2 = spkt2';
    allstimspkT(:,:,st) = spkt2;
end
            
% separate data
pre = allstimspkT(peristimbins(1):peristimbins(2),:,:);
stim = allstimspkT(peristimbins(2):peristimbins(3),:,:);
post = allstimspkT(peristimbins(3):peristimbins(4),:,:);
            
%% create correlation coefficient matrices
%% for pre data
thisRpre = [];
thisRmeanpre = [];
stimRpre = [];
allstimRpre = [];

for st = 1:nstim
    for bn = 1:(size(pre,1)-Rwnd)
        thisRpre = corrcoef(pre(bn:(bn+Rwnd),:,st));
        thisRpre = abs(thisRpre);  % NOTE: TAKING THE ABS
        for i = 2:length(thisRpre)
            thisRmeanpre(i-1) = nanmean(thisRpre(i, 1:(i-1))); 
        end
        stimRpre(bn) = nanmean(thisRmeanpre);
    end
    allstimRpre(st,:) = stimRpre;
    stimRpre = [];
    thisRpre = [];
    thisRmeanpre = [];
end

%% for stim data
thisRstim = [];
thisRmeanstim = [];
stimRstim = [];
allstimRstim = [];

for st = 1:nstim
    for bn = 1:(size(stim,1)-Rwnd)
        thisRstim = corrcoef(stim(bn:(bn+Rwnd),:,st));
        thisRstim = abs(thisRstim);
        for i = 2:length(thisRstim)
            thisRmeanstim(i-1) = nanmean(thisRstim(i, 1:(i-1)));
        end
        stimRstim(bn) = nanmean(thisRmeanstim);
    end
    allstimRstim(st,:) = stimRstim;
    stimRstim = [];
    thisRstim = [];
    thisRmeanstim = [];
end

%% for post data
thisRpost = [];
thisRmeanpost = [];
stimRpost = [];
allstimRpost = [];

for st = 1:nstim
    for bn = 1:(size(post,1)-Rwnd)
        thisRpost = corrcoef(post(bn:(bn+Rwnd),:,st));
        thisRpost = abs(thisRpost);
        for i = 2:length(thisRpost)
            thisRmeanpost(i-1) = nanmean(thisRpost(i, 1:(i-1)));
        end
        stimRpost(bn) = nanmean(thisRmeanpost);
    end
    allstimRpost(st,:) = stimRpost;
    stimRpost = [];
    thisRpost = [];
    thisRmeanpost = [];
end
            
allR = [allstimRpre, allstimRstim, allstimRpost];    

%% normalize and visualize data

% normalize data to pre period
for i = 1:size(allstimRpre,1)
    avg_pre = nanmean(allstimRpre(i,:));
    allR_norm(i,:) = allR(i,:) - avg_pre;
end


% plot changes in correlation coefficient
figure, hold on, stdshade(allR_norm,.2,'black','','');
vline(peristimbins(2)-Rwnd); vline(peristimbins(3)-Rwnd);
title('Change in global correlation coefficient')
xlabel(['time bin of ' num2str(binsz_orig)  ' (s) [note discontinuity at vertical lines denoting stim on and off]']);
ylabel('Change in global correlation coefficient from baseline');

if dosave
    savefig([savepath 'moving_corrcoeff_plot.fig']);
end




% adjust peristimbins to account for loss of Rwnd during correlation
peristimbins_corr = peristimbins;
peristimbins_corr(2) = peristimbins_corr(2) - Rwnd;
peristimbins_corr(3) = peristimbins_corr(3) - Rwnd*2;
peristimbins_corr(4) = peristimbins_corr (4)- Rwnd*3;

pre_m = mean(allR_norm(:,peristimbins_corr(1):peristimbins_corr(2)-1),2);
stim_m = mean(allR_norm(:,peristimbins_corr(2):peristimbins_corr(3)),2);
post_m = mean(allR_norm(:,peristimbins_corr(3)+1:peristimbins_corr(4)),2);

x = categorical({'Pre', 'Stim', 'Post'});
x = reordercats(x,{'Pre', 'Stim', 'Post'});
data = [mean(pre_m) mean(stim_m) mean(post_m)];

sem_pre = std(pre_m)/sqrt(length(pre_m));
sem_stim = std(stim_m)/sqrt(length(stim_m));
sem_post = std(post_m)/sqrt(length(post_m));

errhigh = [sem_pre, sem_stim, sem_post];
errlow = [sem_pre, sem_stim, sem_post];

figure; 
bar(x,data);

hold on

er = errorbar(x,data,errlow,errhigh);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  

title('Average change in correlation coefficient');
ylabel('Change in global correlation coefficient');


% % quantify changes by measuring area under curve for pre, stim, post 
% % NB: because this is summating, only compares equal durations of
% % pre:stim:post.  This is an alternative to taking the mean
% bin_comp = peristimbins(3) - peristimbins(2) - Rwnd;
% for st = 1:size(allR_norm,1)
%     preAUC(st) = cumtrapz(allR_norm(st, ((peristimbins_corr(2) - bin_comp - 1) : (peristimbins_corr(2)-1))));
%     stimAUC(st) = cumtrapz(allR_norm(st, peristimbins_corr(2) : peristimbins_corr(3)));
%     postAUC(st) = cumtrapz(allR_norm(st, peristimbins(3)+1 : (peristimbins(3) + bin_comp + 1)));
% end

if dosave
    savefig([savepath 'bar_plots.fig']);
    save([savepath 'corrcoef.mat'], 'spkt', 'allstimspkT', 'allR', 'allR_norm', 'peristimbins', 'peristimbins_corr');
end
end