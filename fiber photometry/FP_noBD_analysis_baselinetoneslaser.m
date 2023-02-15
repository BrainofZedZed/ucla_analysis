% get all subfolders
currentDirectory = pwd;
allFolders = dir(currentDirectory);
allFolders = allFolders(arrayfun(@(x) x.isdir, allFolders));
allFolders = allFolders(~ismember({allFolders.name}, {'.', '..'}));
folderList = {allFolders.name};

% get TDT pattern
 pat = digitsPattern(6);


for i = 1:length(folderList)
    m = extract(folderList{i}, pat);
    if length(m) == 2
        tdt_f = i;
    end
end

% define pre and post times to visualize
t_pre = 5;
t_post = 5;
cs_dur = 30;
t_total = t_pre+t_post+cs_dur;
tvec = [0-t_pre t_total];

% get TDT data, filtered
tdt_dir = folderList{tdt_f};
data = TDTbin2mat(tdt_dir, 'TYPE', {'epocs', 'scalars', 'streams'});
datafilt = TDTfilter(data, 'PC0/','TIME', tvec);

tdt_fs = datafilt.streams.x465A.fs;

% load 465 from 405 signal
s465 = datafilt.streams.x465A.filtered;
s405 = datafilt.streams.x405A.filtered;

% Fitting 405 channel onto 465 channel to detrend signal bleaching
% Algorithm sourced from Tom Davidson's Github:
% https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m

% enforce same size 
for i = 1:length(s405)
    len(i) = length(s405{i});
end
for i = 1:length(s405)
    bls_all = polyfit(s405{i}(1:min(len)), s465{i}(1:min(len)), 1);
    Y_fit_all = bls_all(1) .* s405{i}(1:min(len)) + bls_all(2);
    sig(i,:) = s465{i}(1:min(len)) - Y_fit_all;
end


% zscore
for i = 1:size(sig,1)
    zb = mean(sig(i,1:(tdt_fs*t_pre))); % baseline period mean
    zsd = std(sig(i,1:(tdt_fs*t_pre))); % baseline period stdev
    zsig(i,:)=(sig(i,:) - zb)/zsd; % Z score per bin
end

% df/f
for i = 1:size(sig,1)
    zb = mean(sig(i,1:(tdt_fs*t_pre))); % baseline period mean
    dff(i,:) = (sig(i,:)-zb)/zb;
end


sig_nolaser = zsig([1 3 5 7],:);
sig_laser = zsig([2 4 6 8], :);

% plot
figure;
hold on;
for i = 1:size(sig_nolaser,1)
    plot(sig_nolaser(i,:));
end

plot(mean(sig_nolaser,1), 'LineWidth', 2, 'Color', 'black');
xline(tdt_fs*t_pre, 'r:');
xl2 = size(sig,2);
xl2 = xl2 - (tdt_fs*t_post);
xline(xl2, 'r:');
xtx = [0:5:40];
xtx2 = (xtx*tdt_fs);
xticks(xtx2);
xticklabels({'-5','0','5','10','15','20','25', '30', '35', '40'});
title('tone (CS+) response -- no laser')
legend('tone1', 'tone2', 'tone3', 'tone4', 'mean');
xlabel('time from tone onset')
savefig('D1_CSp_tonesResponse_noLaser.fig');

figure;
hold on;
for i = 1:size(sig_laser,1)
    plot(sig_laser(i,:));
end

plot(mean(sig_laser,1), 'LineWidth', 2, 'Color', 'black');
xline(tdt_fs*t_pre, 'r:');
xl2 = size(sig,2);
xl2 = xl2 - (tdt_fs*t_post);
xline(xl2, 'r:');
xtx = [0:5:40];
xtx2 = (xtx*tdt_fs);
xticks(xtx2);
xticklabels({'-5','0','5','10','15','20','25', '30', '35', '40'});
title('tone (CS+) response -- laser')
legend('tone1', 'tone2', 'tone3', 'tone4', 'mean');
xlabel('time from tone+laser onset')
ylabel('zscore');
savefig('D1_CSp_toneResponse_Laser.fig');

save('D1_CSp_toneResponse.mat')

%% code graveyard
% tdt_start = datevec(datafilt.info.utcStartTime);
% tdt_start = tdt_start(4:end);
% tdt_start(1) = tdt_start(1)-8;
% 
% pc0_on1 = datafilt.epocs.PC0_.onset(1);
% %time when PC0 onset starts
% tdt_on1 = [tdt_start(1) (tdt_start(2)+floor(pc0_on1/60)) (tdt_start(3)+mod(pc0_on1,60))];
% 
% ts_on1 = ts.csp_on(1,4:end);
