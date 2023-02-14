function SI_rand = shuffleLoc(lin_index_of_max_rec, ca2beh, nn, cmbins, spkfn)

% metrics based on methods in Shuman (2018) bioRxiv with modifications from
% Kinsky...Eichenbaum (2018) Cur Bio.
% Shuffles timing of spike (via permutation of frame #s) and then
% reconstructs spatial information map for each cell

numshuf = 5; % number of shuffles to do 

for shuf = 1:numshuf
% %% generate random shift in location
% r = randi([1 max(lin_index_of_max_rec)],1,1);
% lin_index_of_max_rec_rand = lin_index_of_max_rec + r;
% 
% [rr cc] = find(lin_index_of_max_rec_rand > max(lin_index_of_max_rec));
% lin_index_of_max_rec_rand(cc) = lin_index_of_max_rec_rand(cc) - max(lin_index_of_max_rec);
% 
 lin_spatial_map_rand = zeros(size(cmbins,1),nn); % columns for cells, rows for linear index

%% shuffle spike timing
for i = 1:nn
    spks = spkfn(i,:);
    spk_rand = spks(randperm(length(spks)));
    spkfn_rand(i,:) = spk_rand;
end
    
%% make linear spatial map of firing for each cell  
for i = 1:nn
    for j = 1:size(spkfn_rand,2)
        if spkfn_rand(i,j) ~= 0
            framernd = round(j*ca2beh);
            locactive = lin_index_of_max_rec(framernd);
            [rr, cc] = find(cmbins(:,:) == locactive);
            lin_spatial_map_rand(rr, i) = lin_spatial_map_rand(rr,i) + 1;
        end
    end
end

%% make density map of time in each cell
% lin_occupancymap_rand = zeros(size(cmbins,1),1);
% for i = 1:length(lin_index_of_max_rec_rand)
%     loc = lin_index_of_max_rec_rand(i);
%     [ro co] = find(cmbins(:,:) == loc);
%     lin_occupancymap_rand(ro) = lin_occupancymap_rand(ro) + 1;
% end
% 
% norm_lin_occupancymap_rand = lin_occupancymap_rand /  sum(lin_occupancymap_rand);
%% calculate SI for shuffled trial

%time = round(size(sigfn,2)/fps_new);  % length of recording in seconds
if shuf == 1
SI_rand = zeros(nn,numshuf);  %  information of a neuron's spatial rate map
end
for i = 1:nn
    for j = 1:size(lin_occupancymap,1)
        a2 = sum(lin_spatial_map(:,i) .* norm_lin_occupancymap);
        a = (lin_spatial_map(j,i)) / a2; % normalized firing rate in bin
        b = log2(a);    % base2 of normalized firing
        c = norm_lin_occupancymap_rand(j); % probability of being in bin
        bin_info = a*b*c;
        if isnan(bin_info)
            bin_info = 0;
        end
        SI_rand(i,shuf) = SI_rand(i,shuf) + bin_info;
    end
end

end
end