%% plotPeriToneLocs -- a script to make a GIF of peri-tone PMA animal location
% TO LOAD:  manually load (from BehDEPOT output):  Metrics, Behavior_Filter,
% Params; also load experiment file from FCXD

% TO ADJUST:  ensure tonetimes = event bouts of interest; can exclude
% certain tones from visualization using the commented out line

% NB: be aware of the temporal resolution limits of shock alignment
%% set params and load
shock_dur = us_dur;  % duration of co-terminating shock in seconds
fps = Params.Video.frameRate;  % camera FPS
xdim = Params.Video.frameWidth; % x-dimension of video (pixel)
ydim = Params.Video.frameHeight; % y-dimension of video (pixel)

% ADJUST THIS LINE TO POINT TOWARD TONE EVENT BOUTS OF INTEREST
tonetimes = Behavior_Filter.Temporal.CSp.EventBouts;

%tonetimes = tonetimes(4:end,:);  % edit to exclude certain tones (eg (4,:end,:) to include only 4th tone through end

X = Metrics.Location(1,:);
Y = Metrics.Location(2,:);

%% make figure and save image to variable im
fig = figure;
for idx = 1:length(tonetimes)
    % makes figure, plots ROI
    set(gca,'Color', '#DCDCDC')
    xlim([0 xdim]); 
    ylim([0 ydim]); 
    hold on
    title(['Location during tone ' num2str(idx)]);
    leg = [];
    plot(polyshape(Params.roi{1}), 'FaceAlpha', 0.1);
    leg = [leg, 'platform']

    % plots shock deliveries
    loc = Metrics.Location(:,tonetimes(idx,2)-(fps*shock_dur):tonetimes(idx,2));
    xloc = loc(1,:);
    yloc = loc(2,:);
    ploc = Params.roi{1};
    in = inpolygon(xloc,yloc,ploc(:,1),ploc(:,2));
    scatter(xloc(~in),yloc(~in),25,'ks','filled');
    
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
save('tone_loc.mat');