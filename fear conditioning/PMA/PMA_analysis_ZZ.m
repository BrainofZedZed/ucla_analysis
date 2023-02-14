%% Make Analysis Directory (only do once per group)
source_dir = cd; %allows user to pick the folder to create the file in
group = 'Jaws'; %change for each group
mkdir(source_dir,['Analysis_', group]);

%% Load Behavioral Depot data (must be in analyzed folder)

animal_id = 'DP008'; %name of animal, goes in file name. VERY IMPORTANT TO UPDATE BEFORE RUNNING TO AVOID OVERWRITTING DATA
folder = uigetdir(); %allows user to pick the folder to create the file in
load([folder '\Behavior_Filter.mat'])
% folder = [source_dir,'/Analysis'];
sample_rate = 50; % sample rate of camera  %%in params.mat
bin_size = 3; %seconds you want your bin to be
bout_length = 30; % stimulus length in seconds

%% Analysis Code
%Latency to enter platform for Each Bout of Cue
on_plat = Behavior_Filter.Spatial.platform.inROIvector';
tone_bout = Behavior_Filter.Temporal.CSp.EventBouts;

first_plat=[];first_plat_time=[];
for jjj = 1:length(tone_bout)
    first_plat_temp = find(on_plat(tone_bout(jjj,1):tone_bout(jjj,2)), 1)-1;
    if isempty(first_plat_temp)
        first_plat(jjj) = bout_length;
    else
        first_plat(jjj) = first_plat_temp;
    end
end


    first_plat_time = first_plat/sample_rate;
    
Analysis.OnPlat.Latency = first_plat_time;

% INDIVIDUAL Animal Platform Assessment with Temporal Binning
%creates a matrix that determines if the mouse was on the platform
%for a defined number of bins within a bout of the cue throughout the
%experiment

tone_on = Behavior_Filter.Temporal.CSp.EventVector;
% on_plat = Behavior_Filter.Spatial.platform.inROIvector';

intersect = tone_on.*on_plat; %vector when the animal is on the platform during the tone

% tone_bout = Behavior_Filter.Temporal.CSp.EventBouts;

num_tone_bouts = length(tone_bout); % this was for when I had dropped frames
bad_index=[];yyy=1;
for ooo=2:length(tone_bout)
    if tone_bout(ooo,2)-tone_bout(ooo,1)~=tone_bout(1,2)-tone_bout(1,1)
        fprintf('Bout %i bad :(\n',ooo)
        bad_index(yyy)=ooo;yyy=yyy+1;
    end
end
tone_bout(bad_index,:)=[];

onPlatByCue = zeros(length(tone_bout),(tone_bout(1,2)-tone_bout(1,1)+1)); %creating a zero matrix where rows are equal to the length of tone_bout (ex:6) and 
%the columns the # of frames in each tone bout

for i = 1:length(tone_bout)
    onPlatByCue(i,:) = intersect(tone_bout(i,1):tone_bout(i,2));
end

threshON = []; %jxk matrix


bout_time= (tone_bout(1,2)-tone_bout(1,1))/sample_rate;
bin_frames = ((tone_bout(1,2)-tone_bout(1,1))*bin_size)/bout_time; %calc # of frames in bin_size
threshold = 0.1;

PerBinsOnPlatCue = zeros(length(tone_bout),floor(bout_time/bin_size));
for j = 1:length(tone_bout)
    for k = 1:floor(bout_time/bin_size) % will increment through max # of bins depending on bout time and bin size
    data_bin(k) = sum(onPlatByCue(j,1+(k-1)*bin_frames:k*bin_frames)); % sum of # of frames where the animal was on platform in the kth bin
    fractionON = data_bin(k)/bin_frames; % time spent on platform in the kth bin
    PerBinsOnPlatCue(j,k) = fractionON; %matrix displaying percent on platform for each bin in cue
    if(fractionON)>threshold;
        threshON(j,k)=1;
    else
        threshON(j,k)=0;
    end
    end
end

threshON_temp=threshON; % this was for when I had dropped frames
if isempty(bad_index)
else 
    for yyy=1:length(bad_index)
        if bad_index(yyy) == num_tone_bouts
            AA=threshON_temp(1:bad_index(yyy)-1,:);
            threshON_temp=[AA; NaN+zeros(1,floor(bout_time/bin_size))];
        else
            AA=threshON_temp(1:bad_index(yyy)-1,:);
            BB=threshON_temp(bad_index(yyy):end,:);
            threshON_temp=[AA; NaN+zeros(1,floor(bout_time/bin_size)); BB];
        end
    end
end
Analysis.OnPlat.PerOnPlat = Behavior_Filter.Intersect.ROIduringCue_PerTime.CSp_platform;
BooleanBinsOnPlatCue = threshON_temp;
Analysis.OnPlat.Bins.Boolean = BooleanBinsOnPlatCue;
Analysis.OnPlat.Bins.PerOnPlatCue = PerBinsOnPlatCue;

% INDIVIDUAL Animal Freezing on Platform Assesment with Temporal Binning
%creates a matrix tat determine if a mouse was freezing on the platform
%during the tone for a defined number of bins within a bout of the cue
%throughout the experiment 
clear('threshON_temp');

freeze_onROI = Behavior_Filter.Intersect.SpaTemBeh.Freezing_platform_CSp_Vector;
tone_bout = Behavior_Filter.Temporal.CSp.EventBouts;

num_tone_bouts = length(tone_bout); % this was for when I had dropped frames
bad_index=[];yyy=1; % tell you if one of your tone bouts is a different size than the first one
for ooo=2:length(tone_bout)
    if tone_bout(ooo,2)-tone_bout(ooo,1)~=tone_bout(1,2)-tone_bout(1,1)
        fprintf('Bout %i bad :(\n',ooo)
        bad_index(yyy)=ooo;yyy=yyy+1;
    end
end
tone_bout(bad_index,:)=[];
        
FreezeonPlatByCue = zeros(length(tone_bout),(tone_bout(1,2)-tone_bout(1,1)+1));

for i = 1:length(tone_bout) %boolean matrix for freezing on platform for whole bout
    FreezeonPlatByCue(i,:) = freeze_onROI(tone_bout(i,1):tone_bout(i,2));
    %vector displaying percent time freezing on platform for each bout
    PerFreezeonROItone(i) = sum(FreezeonPlatByCue(i,:))/length(FreezeonPlatByCue(i,:));
end


%Same thing but with bins
bout_time= (tone_bout(1,2)-tone_bout(1,1))/sample_rate;
bin_frames = ((tone_bout(1,2)-tone_bout(1,1))*bin_size)/bout_time; %calc # of frames in bin_size
threshold = 0.1;

PerFreezeonROItonePerBin = zeros(length(tone_bout),floor(bout_time/bin_size));
for j = 1:length(tone_bout)
    for k = 1:floor(bout_time/bin_size) % will increment through max # of bins depending on bout time and bin size
    data_bin(k) = sum(FreezeonPlatByCue(j,1+(k-1)*bin_frames:k*bin_frames)); % sum of # of frames where the animal was on platform in the kth bin
    fractionON = data_bin(k)/bin_frames; % time spent on platform in the kth bin
    PerFreezeonROItonePerBin(j,k) = fractionON; % matrix displaying percent freezing on plat for each bin and bout
    if(fractionON)>threshold;
        threshON_freeze(j,k)=1;
    else
        threshON_freeze(j,k)=0;
    end
    end
end

%
threshON_temp=threshON_freeze; % this was for when I had dropped frames
if isempty(bad_index)
else 
    for yyy=1:length(bad_index)
        if bad_index(yyy) == num_tone_bouts
            AA=threshON_temp(1:bad_index(yyy)-1,:);
            threshON_temp=[AA; NaN+zeros(1,floor(bout_time/bin_size))];
        else
            AA=threshON_temp(1:bad_index(yyy)-1,:);
            BB=threshON_temp(bad_index(yyy):end,:);
            threshON_temp=[AA; NaN+zeros(1,floor(bout_time/bin_size)); BB];
        end
    end
end

BooleanBinsFreeze = threshON_freeze;
Analysis.FreezingOnPlat.PerFreeze = PerFreezeonROItone;
Analysis.FreezingOnPlat.Bins.Boolean = BooleanBinsFreeze;
Analysis.FreezingOnPlat.Bins.PerOnPlatCue = PerFreezeonROItonePerBin;

% Boolean vector looking at whether animal is on platform during the last 2s cue bout

end_threshON = []; 

end_size = 2; %seconds at the end of a bout you want
end_frames = (sample_rate*end_size+1); %calc # of frames in end_size
threshold_end = 0.1; 

for j = 1:length(tone_bout)
    data_end = sum(onPlatByCue(j,end-end_frames:end)); % sum of # of frames where the animal was on platform in the last 'end_size' times
    fractionON_end = data_end/end_frames; % time spent on platform in the last 'end_size'
    if(fractionON_end)>threshold_end;
        end_threshON(j)=1;
    else
        end_threshON(j)=0;
    end
end

Analysis.OnPlat.EndofBout = end_threshON;

Analysis.Summary.FracOnPlat = Behavior_Filter.Spatial.platform.PerTimeInROI;
Analysis.Summary.FracFreezeOnPlat = Behavior_Filter.Spatial.platform.Freezing.PerBehaviorInROI;
Analysis.Summary.FracFreezeCue = Behavior_Filter.Temporal.CSp.Freezing.PerBehInEvent;
Analysis.Summary.AvgFreezeOnPlatCue = mean(PerFreezeonROItone);

assignin('base',['Analysis_',animal_id],Analysis);

filename = ['Analysis_',animal_id,'.mat'];

save(fullfile(folder,filename),'Analysis');

%Will plot the fraction of time on the platform during the whole session with the tones highlighted
% you can visualize when each animal enters the platform during a session
% saves to analysis folder

exp_time = length(on_plat)/sample_rate;
bin_frames = floor((length(on_plat)*bin_size)/exp_time);

for iii = 1:floor(exp_time/bin_size)
    data_bin(iii) = sum(on_plat(1+(iii-1)*bin_frames:iii*bin_frames));
    FractionON = data_bin(iii)/bin_frames;
    FracOnPlatBin(iii) = FractionON;
end

tone_bout_sec=tone_bout./sample_rate;
tone_bout_bin=tone_bout_sec./bin_size;

fig_onplat = figure(1);clf;
area(1:length(FracOnPlatBin),FracOnPlatBin,'FaceAlpha',.8);
hold on;

ylim([0,1.1]);

% CHANGED FACE COLOR OF TONE TIME TO MAKE MORE TRANSPARENT
for iii=1:length(tone_bout_bin)
	rectangle('Position',[tone_bout_bin(iii,1),1.01,tone_bout_bin(iii,2)-tone_bout_bin(iii,1),0.01],'FaceColor',[1,0,0,.1],'EdgeColor','none');

end

title(animal_id,'Fraction time on platform in 5s bins');xlabel('Time (min)');ylabel('Fraction time on platform');
xticks = get(gca,'xtick'); 
scaling  = 5/60; 
newlabels = arrayfun(@(x) sprintf('%.1f', scaling * x), xticks, 'un', 0);
set(gca,'xticklabel',newlabels);

% Heatmap for Avg time spent on Platform during Cue data
heatmap_onplat = figure(2);clf;heatmap(PerBinsOnPlatCue,'CellLabelColor','none')
colormap parula
grid off
title([animal_id,': Avg time on Platform']);
xlabel('Bin');ylabel('Cue')

fig_filename = ['On_Platform_',animal_id,'.fig'];
saveas(fig_onplat, fullfile(folder,fig_filename));

fig_filename = ['Heat_On_Platform_',animal_id,'.fig'];
saveas(heatmap_onplat, fullfile(folder,fig_filename));

close all;

 %% GROUPED Fraction of mice Platform Assessment with Temporal Binning (have to change group)

clear
group = 'Jaws'; %CHANGE for each group

dir = dir('*.mat');          % only looking for .mat-Files             
for i=1:length(dir)                   
    load(dir(i).name);
    a(i,:) = cell2mat(Analysis.OnPlat.PerOnPlat);
    b(i,:) = Analysis.OnPlat.Latency;
    c(i,:) = Analysis.OnPlat.EndofBout;
    d(i,:,:) = Analysis.OnPlat.Bins.Boolean; 
    e(i,:,:) = Analysis.OnPlat.Bins.PerOnPlatCue;

    f(i,:) = Analysis.FreezingOnPlat.PerFreeze;
    g(i,:,:) = Analysis.FreezingOnPlat.Bins.Boolean;
    h(i,:,:) = Analysis.FreezingOnPlat.Bins.PerOnPlatCue;   
    
    j(i,:) = Analysis.Summary.FracOnPlat; 
    k(i,:) = Analysis.Summary.FracFreezeOnPlat;
    l(i,:) = Analysis.Summary.FracFreezeCue; 
    m(i,:) = Analysis.Summary.AvgFreezeOnPlatCue; 
end

Comb_Analysis.OnPlat.Avg_on_plat_during_cue = mean(a);
Comb_Analysis.OnPlat.Avg_Latency = mean(b);
Comb_Analysis.OnPlat.Avg_on_plat_endofbout = mean(c);

Comb_Analysis.OnPlat.Frac_on_plat = zeros(size(d,2:3));
 for iii = 1:size(d,2) % for every bout
     for jjj = 1:size(d,3) % for every bin
         Comb_Analysis.OnPlat.Frac_on_plat(iii,jjj) = mean(d(:,iii,jjj),'omitnan'); %calculate average across animals for a given bin within a bout
     end
 end

 Comb_Analysis.OnPlat.Avg_on_plat_bin = zeros(size(e,2:3));
 for iii = 1:size(e,2) % for every bout
     for jjj = 1:size(e,3) % for every bin
         Comb_Analysis.OnPlat.Avg_on_plat_bin(iii,jjj) = mean(e(:,iii,jjj),'omitnan'); %calculate average across animals for a given bin within a bout
     end
 end
 
Comb_Analysis.FreezeOnPlat.Avg_freeze_during_cue = mean(f);
 
 Comb_Analysis.FreezeOnPlat.Frac_freeze = zeros(size(g,2:3));
 for iii = 1:size(g,2) % for every bout
     for jjj = 1:size(g,3) % for every bin
         Comb_Analysis.FreezeOnPlat.Frac_freeze(iii,jjj) = mean(d(:,iii,jjj),'omitnan'); %calculate average across animals for a given bin within a bout
     end
 end

 Comb_Analysis.FreezeOnPlat.Avg_freeze_bin = zeros(size(h,2:3));
 for iii = 1:size(h,2) % for every bout
     for jjj = 1:size(h,3) % for every bin
        Comb_Analysis.FreezeOnPlat.Avg_freeze_bin(iii,jjj) = mean(h(:,iii,jjj),'omitnan'); %calculate average across animals for a given bin within a bout
     end
 end
 
Comb_Analysis.Summary.FracOnPlat = mean(j);
Comb_Analysis.Summary.FracFreezeOnPlat = mean(k);
Comb_Analysis.Summary.FracFreezeCue = mean(l);
Comb_Analysis.Summary.AvgFreezeOnPlatCue = mean(m);
 
 Comb_Analysis.Fig.Avg_time_on_plat = figure(4);clf;plot(Comb_Analysis.OnPlat.Avg_on_plat_during_cue);
 title(group, ': Avg time on platform during cue');
 xlabel('Cue');ylabel('% time spent on platform');ylim([0,max(Comb_Analysis.OnPlat.Avg_on_plat_during_cue)+0.25]);
 
 % Heatmap for Fraction of mice on Platform during Cue data
Comb_Analysis.Fig.Frac_on_plat = figure(5);clf;heatmap(Comb_Analysis.OnPlat.Frac_on_plat,'CellLabelColor','none')
colormap parula
grid off
title([group,': Fraction of Mice on Platform']);
xlabel('Bin');ylabel('Cue')


% Heatmap for Avg time spent on Platform during Cue data
Comb_Analysis.Fig.Avg_on_plat_bin = figure(6);clf;heatmap(Comb_Analysis.OnPlat.Avg_on_plat_bin,'CellLabelColor','none')
colormap parula
grid off
title([group,': Avg time on Platform']);
xlabel('Bin');ylabel('Cue')

Comb_Analysis.Fig.Avg_freezeonplat_during_cue = figure(3);clf;plot(Comb_Analysis.FreezeOnPlat.Avg_freeze_during_cue);
 title(group,': Avg time freezing on platform during cue');
 xlabel('Cue');ylabel('% time freezing on platform');ylim([0,max(Comb_Analysis.FreezeOnPlat.Avg_freeze_during_cue)+0.25]);

%  close all
assignin('base',['Comb_Analysis_',group],Comb_Analysis);
 folder = uigetdir(); %put into a combined analysis folder 
 
 filename = ['Combined_Analysis_',group,'.mat'];
 save(fullfile(folder, filename));

 
 %% Can compare Non_shock to Shocked groups on same plots
 %NEED TO LOAD COMBINED ANALYSIS FILES
 
figure(90);
plot(Comb_Analysis_Shock.OnPlat.Avg_on_plat_during_cue, 'r');
hold on;
plot(Comb_Analysis_Non_Shock.OnPlat.Avg_on_plat_during_cue, 'b');
title('Avg time on plat s vs ns');
xlabel('Cue');ylabel('% time on platform');

figure(91);
plot(Comb_Analysis_Shock.FreezeOnPlat.Avg_freeze_during_cue, 'r');
hold on;
plot(Comb_Analysis_Non_Shock.FreezeOnPlat.Avg_freeze_during_cue, 'b');
title('Avg freezing on plat s vs ns');
xlabel('Cue');ylabel('% time freezing');

figure(92);
plot(Comb_Analysis_Shock.OnPlat.Avg_Latency, 'r');
hold on;
plot(Comb_Analysis_Non_Shock.OnPlat.Avg_Latency, 'b');
title('Avg latency to platform after cue');
xlabel('Cue');ylabel('Latency');

