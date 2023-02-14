function [spkmap, gridprob, xedges, yedges, spkfn_fp, spkgrd, locs_dist_fp, spkmap_entry, gridcount] = binNFire_v3_rawCa2(px2cm, binsz, sigfn, locs_dist, spdreq, fps, frluX, fps_beh, minpeakprom)
%% do peak analysis for calcium trace

% finds peak times, then calculates starting time of peak by subtracting width of peak 
pkinfo = doeventfind_nostim(sigfn, minpeakprom);
capks_time = nan(size(sigfn,1),max(pkinfo(2,:)));
for i = 1:size(sigfn,1)
    this_pks = pkinfo(:,find(pkinfo(1,:) == i));
    for j = 1:size(this_pks,2)
        capks_time(i,j) = this_pks(4,j)-round(this_pks(5,j)/2);
    end
end

capks_time(capks_time < 1) = 1; % % adjustment for early events

spkfn = zeros(size(sigfn,1),size(sigfn,2));

for i = 1:size(sigfn,1)
    this_frm = capks_time(i,~isnan(capks_time(i,:)));
    spkfn(i,this_frm) = 1;
end

%% implement speed detection
% take speed and reject all activity while speed is < 2.5cm/s (per
% Lefort..Rondi-Reig 2019)
spdminperframe = spdreq*px2cm/fps;  % use fps of ms, not fps of beh, because array pulled beh frames into ms frame times
spdminpersec = spdminperframe*px2cm;

% method 1: instanteous speed requirement applied at frame level
slow_frames = [];
j = 1;
for i = 1:length(locs_dist)
    if locs_dist(i,3) < spdminperframe
        slow_frames(j) = i;
        j = j+1;
    end
end

% method 2: speed req applied at 1 cm bins

%% trim spk data to frames of interest and fast pass spk and location data
% trim spk data to frames of interset
spkfn_fp = spkfn(:,frluX(1,1):frluX(end,1));

% remove both spike and location data from slow frames
spkfn_fp(:,slow_frames) = nan;
spkfn_fp = spkfn_fp(:,all(~isnan(spkfn_fp)));

locs_dist_fp = locs_dist;
locs_dist_fp(slow_frames,:) = nan;
locs_dist_fp = locs_dist_fp(all(~isnan(locs_dist_fp),2),:);

%% bin the space and get location probabilty map
binwidth = px2cm*binsz;
bnwidth2 = [binwidth binwidth];
xbnlm1 = min(locs_dist_fp(:,1))*0.75;
ybnlm1 = min(locs_dist_fp(:,2))*0.75;

xbnlm2 = max(locs_dist_fp(:,1))*1.1;
ybnlm2 = max(locs_dist_fp(:,2))*1.1;

% generate squre bins covering map and percent of time spent in bins
[gridprob, xedges, yedges] = histcounts2(locs_dist_fp(:,1), locs_dist_fp(:,2), 'xbinlimits', [0 xbnlm2], 'ybinlimits', [0 ybnlm2], 'BinWidth', bnwidth2, 'Normalization', 'probability');
[gridcount, ~, ~] = histcounts2(locs_dist_fp(:,1), locs_dist_fp(:,2), 'xbinlimits', [0 xbnlm2], 'ybinlimits', [0 ybnlm2], 'BinWidth', bnwidth2, 'Normalization', 'cumcount');

heatmap(gridprob);
gridprob(gridprob == 0) = nan;  % just for display purposes
title('Location heatmap')
gridprob(isnan(gridprob)) = 0;
%surf(mean(xedges([1:end-1;2:end])), mean(yedges([1:end-1;2:end])), gridprob)


%% identify if a spk occurred; add it to spatial bin
nn = size(spkfn_fp,1);
xbin = 0;
ybin = 0;
last_x = [];
last_y = [];
spkmap = zeros(size(gridprob,1), size(gridprob,2), nn);
spkmap_entry = spkmap;

for i = 1:nn
    last_x = [];
    last_y = [];
    last_x(1) = 0;
    last_y(1) = 0;
    for j = 1:size(spkfn_fp,2)
        if spkfn_fp(i,j) ~= 0
            x = locs_dist_fp(j,1);
            y = locs_dist_fp(j,2);
            for k = 1:size(gridprob,1)
                if xbin == 0
                     if (x >= xedges(k)) & (x < xedges(k+1))
                         xbin = k;
                     end
                end
            end
            for m = 1:(size(gridprob,2))
                if ybin == 0
                     if y >= yedges(m) & y < yedges(m+1)
                        ybin = m;
                     end
                end
            end 
            spkmap(xbin,ybin,i) = spkmap(xbin,ybin,i)+1;
            last_x(j+1) = xbin;
            last_y(j+1) = ybin;
            
            if last_x(j) ~= last_x(j+1) | last_y(j) ~= last_y(j+1) 
              spkmap_entry(xbin,ybin,i) = spkmap_entry(xbin,ybin,i)+1;
            end
            
            xbin = 0;
            ybin = 0;
        end
    end
end


%% make heatmap
% cellofint = 43;
% figure;
% h = heatmap(spkmap(:,:,cellofint));
% h.Title = (['spatial heatmap of deconvolved "spike" events of cell # ' num2str(cellofint)]);
% h.Colormap = jet;

%% normalize firing to spatial grid probability 
% calculate spatial activity rate map 
spkgrd = [];
for i = 1:nn
    i_spkmap = spkmap(:,:,i);
    spkgrd_i(:,:) = i_spkmap ./ (gridprob + eps);
    spkgrd(:,:,i) = spkgrd_i;
end



end