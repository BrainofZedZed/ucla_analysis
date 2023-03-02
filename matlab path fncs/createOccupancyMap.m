function map = createOccupancyMap(Tracking,Params,binsz)
% CREATEOCCUPANCYMAP creates heatmap of arena occupancy
% Tracking from BehDEPOT
% Params from BehDEPOT
% binsz:  size of spatial bins (cm)

%% bin the space and get location probabilty map
binwidth = Params.px2cm*binsz;
bnwidth2 = [binwidth binwidth];
loc = Tracking.Smooth.Head;

xbnlm1 = 0;
ybnlm1 = 0;
% xbnlm1 = min(loc(:,1))*0.9;
% ybnlm1 = min(loc(:,2))*0.9;

xbnlm2 = Params.Video.frameWidth;
ybnlm2 = Params.Video.frameHeight;

% generate squre bins covering map and percent of time spent in bins
[gridprob, ~, ~] = histcounts2(loc(1,:), loc(2,:), 'xbinlimits', [0 xbnlm2], 'ybinlimits', [0 ybnlm2], 'BinWidth', bnwidth2, 'Normalization', 'probability');
%[gridcount, ~, ~] = histcounts2(loc(1,:), loc(2,:), 'xbinlimits', [0 xbnlm2], 'ybinlimits', [0 ybnlm2], 'BinWidth', bnwidth2, 'Normalization', 'count');

gridprob(gridprob == 0) = nan;  % just for display purposes
map = heatmap(gridprob);
map.NodeChildren(3).YDir = 'normal'; % flip Y axis to match DLC
map.NodeChildren(3).XDir = 'reverse'; % flip x
title('Location heatmap')
gridprob(isnan(gridprob)) = 0;

end