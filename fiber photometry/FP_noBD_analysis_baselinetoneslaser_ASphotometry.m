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
cs_dur = 15;
t_total = t_pre+t_post+cs_dur;
tvec = [0-t_pre t_total];

% get TDT data, filtered
%tdt_dir = folderList{tdt_f};

tdt_dir = 'AS_MC-240229-155919';
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

% zero baseline
for i = 1:size(zsig,1)
    zb = mean(zsig(i,1:(tdt_fs*(t_pre/2)))); % baseline period mean
    zsig2(i,:)=(zsig(i,:) - zb); % Z score per bin
end


% plot
figure;
hold on;
for i = 1:size(zsig2,1)
    plot(zsig2(i,:));
end

plot(mean(sig_nolaser,1), 'LineWidth', 2, 'Color', 'black');
xline(tdt_fs*t_pre, 'r:');
xl2 = size(zsig,2);
xl2 = xl2 - (tdt_fs*t_post);
xline(xl2, 'r:');
xtx = [0:5:t_total];
xtx2 = (xtx*tdt_fs);
xticks(xtx2);
xticklabels({'-5','0','5','10','15','20'});
title('AS MC averaged photometry signal - 5mW laser');
legend('laser1','laser2','laser3','on','off');
xlabel('time from laser onset');
ylabel('zscore');



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
