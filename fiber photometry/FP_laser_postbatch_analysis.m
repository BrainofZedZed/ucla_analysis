clear;

info.do_csp = 1; % either must be true
info.do_csm = 0;

% Collect 'video_folder_list' from 'P.video_directory'
info.script_dir = pwd; % directory with script files (avoids requiring changes to path)
disp('Select directory containing other directories for analysis'); % point to folder for analysis
info.parent_dir = uigetdir('','Select the directory containing folders for analysis'); %Directory with list of folders containing videos + tracking to analyze
info.folder_list = getSubDirs(info.parent_dir);

%% initialize vars
auc_laseron_out = {}; 
auc_laseroff_out = {}; 
peaks_laseroff_out = {}; 
peaks_laseron_out = {};
%% loop through folders
cd(info.parent_dir);
for i = 1:length(info.folder_list)
    % clear from previous round
    clearvars -except 'i' 'info' 'auc_laseron_out' 'auc_laseroff_out' 'peaks_laseroff_out' 'peaks_laseron_out';
    % Initialize 
    cd(info.parent_dir);
    this_folder = info.folder_list{i};    

    %% load data
    cd(this_folder) %Folder with data files   
    exp_file = dir('*-*-*_*-*-*.mat');
    load(exp_file.name); % load experiment file

    bdf = dir('*_analyzed'); % behdepot folder
    cd([bdf.folder '\' bdf.name]); % move to behdepot output folder
    load('Behavior.mat');
    load('Params.mat');

    cd ../

    if info.do_csp
        fibpho_file = dir('*CSp_fibpho_analysis.mat');
    else
        fibpho_file = dir('*CSm_fibpho_analysis.mat');
    end
    load([fibpho_file.folder '\' fibpho_file.name]);

    cs = bouts_name;
    id = [exp_ID '_' cs];

    %% calculate signal
    P2.beh_fps*P2.trange_peri_bout(1);
    t0 = P2.beh_fps*P2.trange_peri_bout(1);
    t1 = P2.beh_fps*P2.trange_peri_bout(2);
    t1 = length(zall)-t1;

    laser_off = [1:2:length(bouts)];
    laser_on = [2:2:length(bouts)];
    zsig_laseroff = zall(1:2:end,:);
    zsig_laseron = zall(2:2:end,:);
    zsig_laseron = zsig_laseron - mean(zsig_laseron(:,1:t0),2);
    zsig_laseroff = zsig_laseroff - mean(zsig_laseroff(:,1:t0),2);

    avg_off = mean(zsig_laseroff,1);
    avg_on = mean(zsig_laseron,1);
    
    %% make average plot
    figure; 
    hold on;
    
    plot(avg_on,'Color', 'r');
    plot(avg_off, 'Color', 'k');
    
    % plot(zall(1,:), 'Color', 'k'); hold on;
    % plot(zall(3,:), 'Color', [0.5, 0.5, 0.5]); %gray
    % plot(zall(2,:), 'Color', 'r');  % red
    % plot(zall(4,:), 'Color', [1, 0.5, 0.5']); % light red
    xline([t0, t1], ':', 'LineWidth', 2);
    legend('Laser On', 'Laser Off', 'Tone On', 'Tone Off');
    xlabel('frames at 50 fps');
    ylabel('avg sig (zscore)');
    hold off;
    title(id);
    savefig(['avg_', cs, '_response_laser.fig']);

    %% peaks
    peaks_laser_on = max(zsig_laseron(:,t0:t0+2*P2.beh_fps)');
    peaks_laser_off = max(zsig_laseroff(:,t0:t0+2*P2.beh_fps)');
    
    ntrials = length(peaks_laser_on);
    
    figure;
    scatter(ones([1,ntrials]),peaks_laser_off,'black', 'filled'); hold on;
    scatter((ones([1,ntrials])*2),peaks_laser_on,'red','filled');
    xlim([0 3]);
    xticks([1,2]);
    xticklabels({'Laser Off', 'Laser On'});
    ylabel('Peak response (zscore)');
    title(id);
    savefig(['peak_response_laser' cs '.fig']);

    peaks_laseron_out{i,1} = exp_ID;
    peaks_laseron_out{i,2} = mean(peaks_laser_on);

    peaks_laseroff_out{i,1} = exp_ID;
    peaks_laseroff_out{i,2} = mean(peaks_laser_off);

    %% AUC
    laser_off_auc = trapz(avg_off(t0:t1));
    laser_off_auc_10 = trapz(avg_off(t0:t0+P2.beh_fps*10));
    laser_on_auc = trapz(avg_on(t0:t1));
    laser_on_auc_10 = trapz(avg_on(t0:t0+P2.beh_fps*10));

    auc_laseron_out{i,1} = exp_ID;
    auc_laseron_out{i,2} = laser_on_auc;
    auc_laseron_out{i,3} = laser_on_auc_10;

    auc_laseroff_out{i,1} = exp_ID;
    auc_laseroff_out{i,2} = laser_off_auc;
    auc_laseroff_out{i,3} = laser_off_auc_10;

    close all
end

    %% save
    cd(info.parent_dir);
    save([cs '_laser_posthoc_analysis.mat'], 'info', 'auc_laseron_out', 'auc_laseroff_out', 'peaks_laseroff_out', 'peaks_laseron_out');