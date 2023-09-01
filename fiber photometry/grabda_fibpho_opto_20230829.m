% Fibpho + opto GRABDA analysis
% LOAD INTO WORKSPACE:  _fibpho_analysis.mat file, Behavior struct


t_pre = 2; %seconds before period to visualize
t_post = 2; %seconds after period to visualize

bl = [0.5 0]; % seconds to baseline to relative to event onset for zscore

t_pre = t_pre*P2.beh_fps;
t_post = t_post*P2.beh_fps;
bl = bl*P2.beh_fps;

%% no tone laser on periods
no_tone_laser_frames = Behavior.Temporal.laser.Bouts(1:4,:);
%no_tone_laser_frames(:,1) = no_tone_laser_frames(:,1) - t_pre;
%no_tone_laser_frames(:,2) = no_tone_laser_frames(:,2) + t_post;

t_prelaser = min(no_tone_laser_frames(:,2)-no_tone_laser_frames(:,1));
no_tone_laser_baseline_frames = [no_tone_laser_frames(:,1)-t_prelaser, no_tone_laser_frames(:,1)];

no_tone_laser_sig = [];
no_tone_baseline_sig = [];

zall = [];
for i = 1:size(no_tone_laser_baseline_frames,1)
    zb = mean(bhsig((no_tone_laser_frames(i,1)-bl(1):no_tone_laser_frames(i,1)-bl(2)))); % baseline period mean
    zsd = std(bhsig((no_tone_laser_frames(i,1)-bl(1):no_tone_laser_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(no_tone_laser_frames(i,1)-t_pre:no_tone_laser_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    no_tone_laser_sig(i,:) = zall(i,:);
end

linePlot(no_tone_laser_sig,[t_pre, size(zall,2)-t_post], {'laser on', 'laser off'});
title('GRABDA laser, no tone')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_laser_no_tone.fig');

z = no_tone_laser_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.no_tone_laser_pk = peak;
quantification.no_tone_laser_latency = latency;
quantification.no_tone_laser_auc = mean(mean(z));

zall = [];
for i = 1:size(no_tone_laser_baseline_frames,1)
    zb = mean(bhsig((no_tone_laser_baseline_frames(i,1)-bl(1):no_tone_laser_baseline_frames(i,1)-bl(2)))); % baseline period mean
    zsd = std(bhsig((no_tone_laser_baseline_frames(i,1)-bl(1):no_tone_laser_baseline_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(no_tone_laser_baseline_frames(i,1)-t_pre:no_tone_laser_baseline_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    no_tone_baseline_sig(i,:) = zall(i,:);
end
linePlot(no_tone_baseline_sig, [t_pre size(zall,2)-t_post], {''});
title('GRABDA no tone, no laser')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_no_laser_no_tone.fig')

z = no_tone_baseline_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.no_tone_baseline_pk = peak;
quantification.no_tone_baseline_latency = latency;
quantification.no_tone_baseline_auc = mean(mean(z));


%% tones interleaved with laser
tone_frames = Behavior.Temporal.CSp.Bouts(1:8,:);
%tone_frames(:,1) = tone_frames(:,1) - t_pre;
%tone_frames(:,2) = tone_frames(:,2) + t_pre;

tone_baseline_frames = tone_frames(1:2:end,:);
tone_laser_frames = tone_frames(2:2:end,:);

zall = [];
for i = 1:size(no_tone_laser_baseline_frames,1)
    zb = mean(bhsig(tone_baseline_frames(i,1)-bl(1):tone_baseline_frames(i,1)-bl(2))); % baseline period mean
    zsd = std(bhsig((tone_baseline_frames(i,1)-bl(1):tone_baseline_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(tone_baseline_frames(i,1)-t_pre:tone_baseline_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    tone_baseline_sig(i,:) = zall(i,:);
end
linePlot(tone_baseline_sig, [t_pre size(zall,2)-t_post], {'tone on', 'tone off'});
title('GRABDA tone, no laser')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_tone_no_laser.fig');

z = tone_baseline_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.tone_baseline_pk = peak;
quantification.tone_baseline_latency = latency;
quantification.tone_baseline_auc = mean(mean(z));

zall = [];
for i = 1:size(no_tone_laser_baseline_frames,1)
    zb = mean(bhsig((tone_laser_frames(i,1)-bl(1):tone_laser_frames(i,1)-bl(2)))); % baseline period mean
    zsd = std(bhsig((tone_laser_frames(i,1)-bl(1):tone_laser_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(tone_laser_frames(i,1)-t_pre:tone_laser_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    tone_laser_sig(i,:) = zall(i,:);
end
linePlot(tone_laser_sig, [t_pre size(zall,2)-t_post], {'tone+laser on', 'tone+laser off'});
title('GRABDA tone+laser')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_tone_laser.fig');

z = tone_laser_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.tone_laser_pk = peak;
quantification.tone_laser_latency = latency;
quantification.tone_laser_auc = mean(mean(z));



%% tones with shock, interleaved with laser
tone_shock_frames = Behavior.Temporal.CSp.Bouts(9:16,:);
%tone_shock_frames(:,1) = tone_shock_frames(:,1) - t_pre;
%tone_shock_frames(:,2) = tone_shock_frames(:,2) + t_post;

tone_shock_baseline_frames = tone_shock_frames(1:2:end,:);
tone_shock_laser_frames = tone_shock_frames(2:2:end,:);

tone_shock_baseline_sig = [];
tone_shock_laser_sig = [];
zall = [];
for i = 1:size(tone_shock_baseline_frames,1)
    zb = mean(bhsig((tone_shock_baseline_frames(i,1)-bl(1):tone_shock_baseline_frames(i,1)-bl(2)))); % baseline period mean
    zsd = std(bhsig((tone_shock_baseline_frames(i,1)-bl(1):tone_shock_baseline_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(tone_shock_baseline_frames(i,1)-t_pre:tone_shock_baseline_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    tone_shock_baseline_sig(i,:) = zall(i,:);
end
linePlot(tone_shock_baseline_sig, [t_pre size(zall,2)-t_post], {'tone on', 'tone+shock off'});
title('GRABDA tone+shock')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_tone_shock_no_laser.fig')

z = tone_shock_baseline_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.tone_shock_baseline_pk = peak;
quantification.tone_shock_baseline_latency = latency;
quantification.tone_shock_baseline_auc = mean(mean(z));

zall = [];
for i = 1:size(tone_shock_laser_frames,1)
    zb = mean(bhsig((tone_shock_laser_frames(i,1)-bl(1):tone_shock_laser_frames(i,1)-bl(2)))); % baseline period mean
    zsd = std(bhsig((tone_shock_laser_frames(i,1)-bl(1):tone_shock_laser_frames(i,1)-bl(2)))); % baseline period stdev
    zall(i,:)=(bhsig(tone_shock_laser_frames(i,1)-t_pre:tone_shock_laser_frames(i,2)+t_post-1) - zb)/zsd; % Z score per bin
    zall(i,:)=smooth(zall(i,:),25);  % optional smoothing

    tone_shock_laser_sig(i,:) = zall(i,:);
end
linePlot(tone_shock_laser_sig, [t_pre size(zall,2)-t_post], {'tone+laser on', 'tone+laser+shock off'});
title('GRABDA tone+laser+shock')
ylabel('zscore')
xlabel('frames at 50fps')
savefig('grabda_tone_shock_laser.fig')

z = tone_shock_laser_sig;
[peak, latency] = max(mean(z(:,t_pre:length(z)-t_post)));
latency = mean(latency);
latency = latency/P2.beh_fps;
quantification.tone_shock_laser_pk = peak;
quantification.tone_shock_laser_latency = latency;
quantification.tone_shock_laser_auc = mean(mean(z));

save('grabda_fibpho_opto_workspace.mat', "quantification", '-append');
