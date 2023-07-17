%% plotPeriToneLocs_batch -- a script to make a GIF of peri-tone location
%% also records if animal was outside platform or not at shock onset
% TO LOAD:  manually load (from BehDEPOT output):  Metrics, Behavior_Filter,
% Params; also load experiment file from FCXD

% TO ADJUST:  ensure tonetimes = event bouts of interest; can exclude
% certain tones from visualization using the commented out line

% NB: be aware of the temporal resolution limits of shock alignment

clear;
%% Params
doCSV = 0;  % 0 or 1, save to csv (auto saves to experiment file)
fps = 49.97; % fps, leave blank to autoload
name_of_tone = "CSp"; % exact name of tone in Behavior.Temporal

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

% loop through videos
for j = 1:length(P2.video_folder_list)
    % clear previous round
    clearvars -except 'fps' 'name_of_tone' 'P2' 'directory_contents' 'j'
    % Initialize 
    current_video = P2.video_folder_list(j);    
    video_folder = strcat(P2.video_directory, '\', current_video);
    cd(video_folder) %Folder with data files   
%%
% assume save to CSV unless indicated otherwise
if ~exist('doCSV','var')
    doCSV = 1;
end

% load experiment data
exp_file = dir('*-*-*_*-*-*.mat');
load([exp_file.folder '\' exp_file.name]);

% load behDEPOT data
bd_folder = dir('*_analyzed');
cd(bd_folder.name);
load('Params.mat');
load('Behavior.mat');
load('Metrics.mat');
load('Tracking.mat');
cd('../')

%% set params and load
shock_dur = us_dur;  % duration of co-terminating shock in seconds
if ~isempty(fps)
    fps = Params.Video.frameRate;  % camera FPS
end
xdim = Params.Video.frameWidth; % x-dimension of video (pixel)
ydim = Params.Video.frameHeight; % y-dimension of video (pixel)

% ADJUST THIS LINE TO POINT TOWARD TONE EVENT BOUTS OF INTEREST
tonetimes = Behavior.Temporal.(name_of_tone).Bouts;
shocktimes = Behavior.Temporal.US.Bouts;
%tonetimes = tonetimes(4:end,:);  % edit to exclude certain tones (eg (4,:end,:) to include only 4th tone through end

X = Tracking.Smooth.BetwLegs(1,:);
Y = Tracking.Smooth.BetwLegs(2,:);
location = [X;Y];

% alternative:  plot nose location
% X = Tracking.Smooth.Nose(1,:);
% Y = Tracking.Smooth.Nose(2,:);
% location = [X;Y];

%% make figure and save image to variable im
fig = figure;
on_platform_shock = zeros(size(tonetimes,1),1);
on_platform_tone = zeros(size(tonetimes,1),1);
for idx = 1:length(tonetimes)
    % makes figure, plots ROI
    set(gca,'Color', '#DCDCDC')
    xlim([0 xdim]); 
    ylim([0 ydim]); 
    hold on
    title(['Location during tone ' num2str(idx)]);
    leg = [];
    for n_roi = 1:length(Params.roi_name)
        plot(polyshape(Params.roi{n_roi}), 'FaceAlpha', 0.1);
        leg = [leg, Params.roi_name{n_roi}];
    end

    % plots shock deliveries
    loc = location(:,shocktimes(idx,1):shocktimes(idx,2));
    xloc = loc(1,:);
    yloc = loc(2,:);
    ploc = Params.roi{1};
    in = inpolygon(xloc,yloc,ploc(:,1),ploc(:,2));
    scatter(xloc(~in),yloc(~in),25,'ks','filled');
    
    % record whether location is on platform during shock times
    on_platform_shock(idx) = all(in);

    % record whether location is on platform at start of tone
    on_platform_tone(idx) = inpolygon(X(tonetimes(idx,1)),Y(tonetimes(idx,1)),ploc(:,1),ploc(:,2));

    %plots location
    xx(idx,:) = X(tonetimes(idx,1):tonetimes(idx,2));
    yy(idx,:) = Y(tonetimes(idx,1):tonetimes(idx,2));
    sz = 1:length(xx);
    scatter(xx(idx,:),yy(idx,:),5,sz);
    colormap('jet')
    colorbar;
    colorbar('Ticks',[1,length(xx)-100,(length(xx)-1)],'TickLabels',{'Start','SHOCK', 'End'}) 

    %saves fig to frame, then collects frame
    frame = getframe(fig);
    im{idx} = frame2im(frame);
    
    clf;
end

%% make gif
filename = 'periToneLocs.gif'; % Specify the output file name
for idx = 1:length(im)
    [A,map] = rgb2ind(im{idx},256);
    if idx == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',1.5);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',1.5);
    end
end

tone_plots = im;
save(exp_file.name, 'tone_plots', 'on_platform_shock', 'on_platform_tone','-append');
close;
end

inpolygon(X(tonetimes(1,1)),Y(tonetimes(1,1)),ploc(:,1),ploc(:,2))