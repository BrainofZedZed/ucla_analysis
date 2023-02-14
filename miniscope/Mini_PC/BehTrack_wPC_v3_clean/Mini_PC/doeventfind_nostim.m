function pkinfo = doeventfind_nostim(sigfn, minpeakprominence)

minpeak = minpeakprominence;
zsigfn = sigfn;
nn = size(zsigfn,1);
pkinfo = [];
% convert clacium signal to zscore and findpeaks. Store info in variable
% 'pkinfo'. pkinfo is organized into rows:  1) Cell ID, 2) event #, 3) pk
% value, 4) location of peak, 5) width of peak, 6) prominence of peak, 7)
% if in stim period (1=stim; 0=base);
for i = 1:nn
    zsigfn(i,:) = zscore(zsigfn(i,:));
    [pks, locs, w, p] = findpeaks(zsigfn(i,:),'MinPeakProminence', minpeak, 'WidthReference', 'halfheight');
    numevents = length(pks);
    start = size(pkinfo,2);
    for j = 1:numevents
        pkinfo(1,start+j) = i;        % cell ID
        pkinfo(2,start+j) = j;        % event #
        pkinfo(3,start+j) = pks(j);   % pk vlaue
        pkinfo(4,start+j) = locs(j);  % location (time)
        pkinfo(5,start+j) = w(j);     % width (using half-height)
        pkinfo(6,start+j) = p(j);     % prominence

    end
end
end