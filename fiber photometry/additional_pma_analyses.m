%% Batch Setup
% Collect 'video_folder_list' from 'P.video_directory'
P2.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
P2.video_directory = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
cd(string(P2.video_directory));
directory_contents = dir;
directory_contents(1:2) = [];
ii = 0;

for i = 1:size(directory_contents, 1)
    current_structure = directory_contents(i);
    if current_structure.isdir
        ii = ii + 1;
        P2.video_folder_list(ii) = string(current_structure.name);
        disp([num2str(i) ' directory loaded'])
    end
end

ct = 0;
for j = 1:length(P2.video_folder_list)
     % clear from previous round
    clearvars -except 'P2' 'j' 'ct';

    % return to script dir
    cd(P2.script_dir);
   
    % Initialize 
    ct = ct+1; % increase count
    current_video = P2.video_folder_list(j);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
    basedir = pwd;

    % load fibpho analysis file
    exp_file = dir('*fibpho_analysis.mat');
    load(exp_file.name); % load experiment file

    % plot baseline trial, shock trial, first avoid trial
    figure;
    hold on;
    plot(zall(3,:));
    try
        plot(zall(shock_trials(1),:));
    catch
        plot(zall(4,:));
    end

    try
        plot(zall(nonshock_trials(1),:));
    catch
        plot(zall(5,:));
    end
    legend({'last baseline', 'first shock', 'first avoid', 'shock onset'});
    xticks([0 102*10 102*40 102*70 102*100]);
    xticklabels({'-10', '0','30', '60', '90'});
    xline(102*38);
    xlabel('time from tone onset (s)');
    ylabel('signal (zscore)');
    savefig('first_tone_shock_response.fig');
end
    % plot above as one continuous signal
    figure;
    hold on;
    plot(bhsig(bouts(8,1)-30*50:bouts(11,2)+30*50));

    t0 = bouts(8,1)-30*50;
    t1 = bouts(8,2)-t0;
    t2 = bouts(9,1)-t0;
    t3 = bouts(9,2)-t0;
    t4 = bouts(10,1)-t0;
    t5 = bouts(10,2)-t0;
    t6 = bouts(11,1)-t0;
    t7 = bouts(11,2)-t0;
    
    

    xline(tzero);
    xline(t1);
    xline(t2);
    xline(t3);
    xline(t4);
    xline(t5);
    xline(t6);
    xline(t7);
    
    xticks([t1 t3 t5 t7])
    xticklabels({'avoid tone (8)', 'shock tone (9)', 'shock tone (10)', 'avoid tone (11)'});
    ylabel('sig [au]')
    title('DP044 later tone signals')
    savefig('later_tones_shocks_continuous.fig');





t0 = P2.trange_peri_bout(1)*P2.fp_fps;
t1 = t0+30*P2.fp_fps;
t2 = t0+40*P2.fp_fps;
xline(t0);
xline(t1);
%xline(t1-204,':');
xticks([0 t0 t1 t2]);
xticklabels({'-10', '0', '30', '40'});
xlabel('time from tone onset (s)');
ylabel('sig (zscore)');
xlim([0 t2])
title('DP045 tone response for baseline tones (n=3)')

%%
% chunk tones into 3 and plot response
zall_og = zall;
bin{1} = zall_og(1:3,:);
bin{2} = zall_og(4:6,:);
bin{3} = zall_og(7:9,:);
bin{4} = zall_og(10:12,:);
bin{5} = zall_og(13:16,:);
%bin{6} = zall_og(17:18,:);

% get average of bins
for i = 1:5
    ibin = bin{i};
    meanbin = mean(ibin);
    binall(i,:) = meanbin;
end

% plot
figure;
plot(binall');

t0 = P2.trange_peri_bout(1)*P2.fp_fps;
t1 = t0+30*P2.fp_fps;
t2 = t0+40*P2.fp_fps;
xline(t0);
xline(t1);
%xline(t1-204,':');
xticks([0 t0 t1 t2]);
xticklabels({'-10', '0', '30', '40'});
xlabel('time from tone onset (s)');
ylabel('sig (zscore)');
xlim([0 t1])

legend({'1','2','3','4','5'});
%% avoids
avoids = find(on_platform_shock==1);
avoids = avoids(avoids>4);
zall = zall_og(avoids,:);

%% line plot
  % Subtract DC offset to get signals on top of one another
zall_offset = zall - mean(mean(zall));
mean_zall = mean(zall_offset);
std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));

% plot mean and sem
fig = figure;
y = mean(zall);
x = 1:numel(y);
curve1 = y + sem_zall;
curve2 = y - sem_zall;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
h = fill(x2, inBetween, 'r');
set(h, 'facealpha', 0.25, 'edgecolor', 'none');
hold on;
plot(x, y, 'r', 'LineWidth', 2);

t0 = P2.trange_peri_bout(1)*P2.fp_fps;
t1 = t0+30*P2.fp_fps;
t2 = t0+40*P2.fp_fps;
xline(t0);
xline(t1);
%xline(t1-204,':');
xticks([0 t0 t1 t2]);
xticklabels({'-10', '0', '30', '40'});
xlabel('time from tone onset (s)');
ylabel('sig (zscore)');
xlim([0 t2])

%% freezing analyses
frz_bouts = Behavior.Freezing.Bouts;
tmp = find(Behavior.Freezing.Length > 50);
frz_bouts = frz_bouts(tmp);
% zscore is minus baseline mean, divide by baseline SD

for i = 1:length(frz_bouts)
    % get mean of baseline
    ifb = frz_bouts(i,1);
    bl_mean = mean(bhsig(ifb-2*beh_fps:ifb-1*beh_fps));
    bl_sd = std(bhsig(ifb-2*beh_fps:ifb-1*beh_fps));
    zifb(i,:) = (bhsig(frz_bouts(i,1)-45:frz_bouts(i,1)+49)-bl_mean) / bl_sd;
end

zall = zifb;
zall_offset = zall - mean(mean(zall));
mean_zall = mean(zall_offset);
std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));

% plot mean and sem
fig = figure;
y = mean(zall);
x = 1:numel(y);
curve1 = y + sem_zall;
curve2 = y - sem_zall;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
h = fill(x2, inBetween, 'r');
set(h, 'facealpha', 0.25, 'edgecolor', 'none');
hold on;
plot(x, y, 'r', 'LineWidth', 2);

xticks([0 45 95]);
xticklabels({'-1', '0', '1'});
xline(45, ':');
xlabel('time from freeze detection (s)');
ylabel('sig (zscore)');

%legend({'sem','mean','freeze onset'})
title('DP051 freeze response (min freeze bout 1s) (n=230)')

t0 = bouts(4,1);

%%
% plot all shocks individually
s = find(on_platform_shock==0);
s = s(s>=4);
figure; plot(zall(s,:)');


%% for platform entries
  % Subtract DC offset to get signals on top of one another
zall_offset = zall - mean(mean(zall));
mean_zall = mean(zall_offset);
std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));

% plot mean and sem
fig = figure;
y = mean(zall);
x = 1:numel(y);
curve1 = y + sem_zall;
curve2 = y - sem_zall;
x2 = [x, fliplr(x)];
inBetween = [curve1, fliplr(curve2)];
h = fill(x2, inBetween, 'r');
set(h, 'facealpha', 0.25, 'edgecolor', 'none');
hold on;
plot(x, y, 'r', 'LineWidth', 2);

xline(400);
xline(P2.pre_pf_window)
legend({'sem','mean','platform entry'})
xlabel('frames at 50 fps')
ylabel('zscore')
