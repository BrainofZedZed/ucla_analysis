function globalStimFunc(sig, stimframes_ms, fps, tprior, tpost, dosave, id, savepath)

%% gather peristim data, for all cells
tstim = round(mean(stimframes_ms(:,2)-stimframes_ms(:,1))/fps);
ln = fps*(tprior+tstim+tpost);

% create 3dim matrix pstim (peri-stim) holding responses, 
% row: trial, column: frame, page: cell
nn = size(sig,1);
nstim = size(stimframes_ms,1);

pstim_raw = zeros(nstim, ln, nn);
for i_c = 1:nn
    for i_s = 1:nstim
        f_start = stimframes_ms(i_s,1) - (tprior*fps);
        f_end = f_start + ln - 1;
        pstim_raw(i_s, :, i_c) = sig(i_c, f_start:f_end);
    end
end

%% normalize changes to baseline, take avg, and smooth
pre = 1;
stimon = tprior*fps;
pstim_delta = pstim_raw;

for i_c = 1:nn
    for i_s = 1:nstim
        pre_avg = mean(pstim_raw(i_s, pre:stimon, i_c));
    	pstim_delta(i_s, :, i_c) = pstim_delta(i_s, :, i_c) - pre_avg;
    end
end

pstim_avg_global = squeeze(mean(pstim_delta,3));
pstim_avg = squeeze(mean(pstim_avg_global,1));

smthf = 10; % # frames to smooth over
pstim_smth = smooth(pstim_avg,smthf);

%% plot and save
figure, stdshade(pstim_avg_global,.2,'black','','');
vline(tprior*fps);
vline((tprior+tstim)*fps);
title([id 'average global response']);
if dosave
    save([savepath 'globalStimResponse.mat'], 'pstim_raw', 'pstim_delta', 'pstim_avg_global', 'pstim_smth');
    savefig([savepath 'globalResponse.fig']);
end

end