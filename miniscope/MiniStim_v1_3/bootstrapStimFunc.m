% %'bootstrapStimFunc' takes average response of each cell around the stimulus, 
% compares it to a bootstrapped baseline distribution, and looks for significant 
% responses (based on numSD). 
% INPUTS: sig (signal matrix from min1pipe (cell x frame matrix)), 
% stimframes_ms (Nx2 matrix containing ON (col1) and OFF (col2) frames of 
% events relative to miniscope ('ms')), fps (frames per second of sigfn), 
% tprior (time (seconds) prior to event to exclude from baseline / include 
% in analysis),tpost (time (seconds) after event to exclude from baseline / include in
% analysis), dosave (1 or 0; recommend 1), id (char or string of experiment name),
% savepath (path to save output), numSD (number of standard deviations
% above baseline response for significance threshold)
% OUTPUTS: save .m file containing all calculations, as well as figures
% showing responses of significant cells.

% abbreviations used:  nn = number of neurons, i_c = ith cell, bs =
% baseline, ind = index, ms = miniscope


function bootstrapStimFunc(sig, stimframes_ms, fps, tprior, tpost, dosave, id, savepath, numSD)

%% create list of base times
tstim = round(mean(stimframes_ms(:,2)-stimframes_ms(:,1))/fps);
ln = fps*(tprior+tstim+tpost);

allframe = [1:size(sig,2)];
allframe = allframe(ln:end-ln);

% exclude stim frames
exclusionframes = [];
for i_s = 1:size(stimframes_ms,1)
    exclusionframes = [exclusionframes, (stimframes_ms(i_s,1)-(fps*(tpost+tstim+tprior))):(stimframes_ms(i_s,2)+(fps*tpost))];
end

baseframes = setdiff(allframe,exclusionframes);

%% bootstrap from base times
x = 10000;
sigfn_base = sig(:,baseframes);

nn = size(sig,1);
ln = fps*(tprior+tstim+tpost);
nstim = size(stimframes_ms,1);
randbase = zeros(x,ln,nn);

for i_c = 1:nn
    for i_x = 1:x
        randomIndex = randi(length(baseframes)-ln, 1);
        randbase(i_x,:,i_c) = sigfn_base(i_c,randomIndex:randomIndex+ln-1);
    end
end

% calculate mean and SD for bootstrapped data
bs_mean = zeros(nn,ln);
bs_sd = zeros(nn,ln);

for i_c = 1:nn
    bs_mean(i_c,:) = mean(randbase(:,:,i_c),1);
    bs_sd(i_c,:) = std(randbase(:,:,i_c),0,1);
end

bs_sd = bs_sd*numSD;

%% calculate average response to stim
allstim = zeros(size(stimframes_ms,1),ln,nn); %creates 3D matrix of # rows in stimframes_ms, frames encompassing each stimulation "event",and # of neurons

% remove last stim if cut off too close to end
if size(sig,2) < ((stimframes_ms(i_s,1)-(tprior*fps))+ln-1)
    stimframes_ms = stimframes_ms(1:end-1,:);
end

for i_c = 1:nn
    for i_s = 1:size(stimframes_ms,1)
        allstim(i_s,:,i_c) = sig(i_c, (stimframes_ms(i_s,1)-(tprior*fps)):(stimframes_ms(i_s,1)-(tprior*fps))+ln-1); 
    end
end

% calculate mean for stim data
stim_mean = zeros(nn,ln);
for i_c = 1:nn
    stim_mean(i_c,:) = mean(allstim(:,:,i_c),1);
end

%% find if any average responses exceed bootstrap base
c_sig = {};

% create list of cells with average responses that exceed baseline mean
for i_c = 1:nn
    t = find((stim_mean(i_c,(fps*tprior):end) > (bs_mean(i_c,(fps*tprior):end)+(bs_sd(i_c,(fps*tprior):end)))));
    c_sig = [c_sig; {t}];
end

% get the index of the responding cells
ind_sig = [];
for i_c = 1:nn
    if ~isempty(c_sig{i_c})
        ind_sig = [ind_sig; i_c];
    end
end

%% save
if dosave
    %% plot sig cell responses
    figure;
    for i_c = 1:size(ind_sig,1)
        hold on;
        plot(bs_mean(ind_sig(i_c),:), 'Color', 'k');
        plot(bs_sd(ind_sig(i_c),:), '--k');
        plot(stim_mean(ind_sig(i_c),:), 'Color', 'r');
        vline(tprior*fps);
        vline((tprior+tstim)*fps);
        legend('bootstrap mean', 'bootstrap SD', 'stim mean','location', 'northeast');
        savefig([savepath 'cell_' num2str(ind_sig(i_c)) '.fig']);
        clf
    end
    close;
    save([savepath 'stim_response.mat'], 'bs_sd', 'bs_mean', 'ind_sig', 'sig', 'nstim', 'numSD', 'stim_mean', 'stimframes_ms', 'allstim', 'tprior', 'tstim', 'tpost', 'id', 'dosave', 'fps');
    end

end
