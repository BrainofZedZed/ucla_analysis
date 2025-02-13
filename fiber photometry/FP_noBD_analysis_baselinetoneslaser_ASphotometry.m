
% define pre and post times to visualize
t_pre = 10;
t_post = 10;
cs_dur = 30;
t_total = t_pre+t_post+cs_dur;
tvec = [0-t_pre t_total];

% get TDT data, filter for just the periods around the TTLs
tdt_dir = 'AS_FE-240229-164815';
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

% smooth
for i = 1:size(zsig2,1)
    zsig2_smth(i,:) = smooth(zsig2(i,:),tdt_fs/4);
end

% plot
figure;
hold on;
for i = 1:size(zsig2_smth,1)
    plot(zsig2_smth(i,:));
end

plot(mean(zsig2_smth,1), 'LineWidth', 2, 'Color', 'black');
xline(tdt_fs*t_pre, 'r:');
xl2 = size(zsig2_smth,2);
xl2 = xl2 - (tdt_fs*t_post);
xline(xl2, 'r:');
xtx = [0:10:t_total];
xtx2 = (xtx*tdt_fs);
xticks(xtx2);
xticklabels({'-10','0','10','20','30','+10'});
title('AS FE Ctxt A yoked signal');
%legend('laser1','laser2','laser3','on','off');
xlabel('time from laser onset');
ylabel('zscore');


mean_pre = mean(zsig2_smth(:,1:tdt_fs*t_pre),2);
mean_laser = mean(zsig2_smth(:,tdt_fs*t_pre:tdt_fs*(t_pre+cs_dur)),2);
mean_post = mean(zsig2_smth(:,tdt_fs*(t_pre+cs_dur):end),2);


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
%  bls_all = polyfit(s405, s465, 1);
% Y_fit_all = bls_all(1) .* s405 + bls_all(2);
% sig(i,:) = s465 - Y_fit_all;


% plot
figure;
hold on;
for i = 1:14:size(zsig,1)
    plot(zsig(i,:));
end