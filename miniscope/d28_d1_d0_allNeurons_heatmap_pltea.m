%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

normalizeEachRowFinal = false;  % If true, each row is 0-1 normalized after building all blocks
tone_length  = 897;            % forced tone length for D1 & D28
frame_buffer = 300;            % frames on each side for D1 & D28
finalWinSize = 2*frame_buffer + tone_length;
frames_per_second = 30;        % for x-axis in seconds

numAnimals = length(align_tables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) Build "global" lists based on shock response first
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global_shock_exc  = [];  % [animalIdx, d0ID]
global_shock_supp = [];
global_rest      = [];  % all other neurons
d0_toneDurAll = [];    % gather each animal's average tone duration for D0

for i = 1:numAnimals
    % Get shock response classifications from D0 (dayIndex=1)
    shock_exc  = tone_neuron_mod{1,i}{1,1}{1,3};  % shock excited
    shock_supp = tone_neuron_mod{1,i}{1,1}{1,4};  % shock suppressed
    
    n0 = size(sigs_d0{i},1);
    allIDs = (1:n0)';
    
    % Get non-shock responsive neurons
    rest = setdiff(allIDs, [shock_exc(:); shock_supp(:)]);
    
    % Append these to global arrays
    global_shock_exc  = [global_shock_exc;  [repmat(i,numel(shock_exc),1),  shock_exc(:) ] ];
    global_shock_supp = [global_shock_supp; [repmat(i,numel(shock_supp),1), shock_supp(:)]];
    global_rest      = [global_rest;       [repmat(i,numel(rest),1),       rest(:)]      ];
    
    % Compute D0's actual average tone duration for animal i
    d0_toneOn  = find(diff([0 tone_vecs_d0{i}]) == 1);
    d0_toneOff = find(diff([tone_vecs_d0{i} 0]) == -1);
    nTones  = min(length(d0_toneOn), length(d0_toneOff));
    if nTones>0
        d0_dur = mean(d0_toneOff(1:nTones) - d0_toneOn(1:nTones) + 1);
        d0_toneDurAll = [d0_toneDurAll; d0_dur];
    end
end

% For the remaining neurons, organize by D28 response
rest_exc  = [];
rest_supp = [];
rest_none = [];

for i = 1:size(global_rest,1)
    animalIdx = global_rest(i,1);
    neuronID = global_rest(i,2);
    
    % Check if this neuron has a match in D28
    AlignT = align_tables{animalIdx};
    rA = find(AlignT.D0 == neuronID, 1, 'first');
    
    if ~isempty(rA) && ~isnan(AlignT.D28(rA))
        d28id = AlignT.D28(rA);
        exc28  = tone_neuron_mod{animalIdx}{3}{1};  % D28 excited
        supp28 = tone_neuron_mod{animalIdx}{3}{2};  % D28 suppressed
        
        if ismember(d28id, exc28)
            rest_exc = [rest_exc; global_rest(i,:)];
        elseif ismember(d28id, supp28)
            rest_supp = [rest_supp; global_rest(i,:)];
        else
            rest_none = [rest_none; global_rest(i,:)];
        end
    else
        rest_none = [rest_none; global_rest(i,:)];
    end
end

% Combine all groups in order
bigList = [global_shock_exc; global_shock_supp; rest_exc; rest_supp; rest_none];

% Record boundaries for visualization
boundary_shock_exc_supp = size(global_shock_exc,1);
boundary_shock_supp_rest_exc = boundary_shock_exc_supp + size(global_shock_supp,1);
boundary_rest_exc_supp = boundary_shock_supp_rest_exc + size(rest_exc,1);
boundary_rest_supp_none = boundary_rest_exc_supp + size(rest_supp,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) Prebuild each day's peri-tone for each animal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

peri_d28_cell = cell(1,numAnimals);
peri_d1_cell  = cell(1,numAnimals);
peri_d0_cell  = cell(1,numAnimals);

for i = 1:numAnimals
    % Row-wise 0-1 normalization (per animal, each day)
    s28norm = rowMinMaxNormalize(sigs_d28{i});
    s1norm  = rowMinMaxNormalize(sigs_d1{i});
    s0norm  = rowMinMaxNormalize(sigs_d0{i});
    
    % Build forced-window peri-tone (skip partial out-of-range)
    [peri_d28_cell{i}, ~] = buildFixedWindowPeriToneWithOffset(...
        s28norm, tone_vecs_d28{i}, tone_length, frame_buffer, finalWinSize);
    [peri_d1_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s1norm,  tone_vecs_d1{i},  tone_length, frame_buffer, finalWinSize);
    [peri_d0_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s0norm,  tone_vecs_d0{i},  tone_length, frame_buffer, finalWinSize);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) Top Block: Construct final arrays for D28-based block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nTopBlock = (Nexc + Nsupp + Nnone);  % rows in top block
block_d28 = zeros(nTopBlock, finalWinSize);
block_d1  = zeros(nTopBlock, finalWinSize);
block_d0  = zeros(nTopBlock, finalWinSize);

rowToD1ID_top = zeros(nTopBlock,1);
rowToD0ID_top = zeros(nTopBlock,1);
rowToAnimal_top = zeros(nTopBlock,1);

for rowIdx = 1:nTopBlock
    animalIdx = bigList(rowIdx,1);
    d28id     = bigList(rowIdx,2);
    
    % Insert D28 data
    block_d28(rowIdx,:) = peri_d28_cell{animalIdx}(d28id,:);
    
    % Look up matched D1 & D0 from align_tables
    AlignT = align_tables{animalIdx};
    rA = find(AlignT.D28 == d28id, 1, 'first');
    if ~isempty(rA)
        d1id = AlignT.D1(rA);
        d0id = AlignT.D0(rA);
        if ~isnan(d1id) && d1id>0 && d1id<=size(peri_d1_cell{animalIdx},1)
            block_d1(rowIdx,:) = peri_d1_cell{animalIdx}(d1id,:);
            rowToD1ID_top(rowIdx)  = d1id;
        end
        if ~isnan(d0id) && d0id>0 && d0id<=size(peri_d0_cell{animalIdx},1)
            block_d0(rowIdx,:) = peri_d0_cell{animalIdx}(d0id,:);
            rowToD0ID_top(rowIdx)  = d0id;
        end
    end
    rowToAnimal_top(rowIdx) = animalIdx;
end

% Sort D28-based block by peak time in final_d28
tone_start_idx = frame_buffer + 1;
tone_end_idx   = frame_buffer + tone_length;
tone_period    = tone_start_idx:tone_end_idx;

exc_indices  = 1:Nexc;
supp_indices = (Nexc+1):(Nexc+Nsupp);
none_indices = (Nexc+Nsupp+1):(Nexc+Nsupp+Nnone);

exc_sorted  = orderByPeakTime(block_d28, exc_indices,  tone_period);
supp_sorted = orderByPeakTime(block_d28, supp_indices, tone_period);
none_sorted = orderByPeakTime(block_d28, none_indices, tone_period);

top_new_order = [exc_sorted(:); supp_sorted(:); none_sorted(:)];

block_d28 = block_d28(top_new_order, :);
block_d1  = block_d1(top_new_order, :);
block_d0  = block_d0(top_new_order, :);

rowToD1ID_top    = rowToD1ID_top(top_new_order);
rowToD0ID_top    = rowToD0ID_top(top_new_order);
rowToAnimal_top  = rowToAnimal_top(top_new_order);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) Middle Block: D1-only neurons (not used in the top block)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We'll gather new rows from each animal, build a new block, reorder them by peak time in D1

block_d28_d1Only = [];
block_d1_d1Only  = [];
block_d0_d1Only  = [];
rowToAnimal_d1Only = [];
rowToD1ID_d1Only   = [];
rowToD0ID_d1Only   = [];

for i = 1:numAnimals
    % All D1 IDs in this animal
    n1   = size(peri_d1_cell{i},1);
    all1 = (1:n1)';
    % Already used in top block?
    usedD1 = rowToD1ID_top(rowToAnimal_top==i); % D1 IDs from top block for this animal
    unmatchedD1 = setdiff(all1, usedD1);

    % For each unmatched D1, build a new row
    for d1id_unplotted = unmatchedD1'
        new_d28_row = zeros(1, finalWinSize);
        new_d1_row  = peri_d1_cell{i}(d1id_unplotted, :);
        new_d0_row  = zeros(1, finalWinSize);

        d28id_match = NaN;
        d0id_match  = NaN;

        % Look up matched D28, D0 from alignment
        AlignT = align_tables{i};
        % find row in AlignT with D1 == d1id_unplotted
        rA = find(AlignT.D1 == d1id_unplotted, 1, 'first');
        if ~isempty(rA)
            d28id_temp = AlignT.D28(rA);
            d0id_temp  = AlignT.D0(rA);
            if ~isnan(d28id_temp) && d28id_temp>0 && d28id_temp<=size(peri_d28_cell{i},1)
                new_d28_row = peri_d28_cell{i}(d28id_temp, :);
                d28id_match = d28id_temp;
            end
            if ~isnan(d0id_temp) && d0id_temp>0 && d0id_temp<=size(peri_d0_cell{i},1)
                new_d0_row = peri_d0_cell{i}(d0id_temp, :);
                d0id_match = d0id_temp;
            end
        end
        
        block_d28_d1Only  = [block_d28_d1Only;  new_d28_row]; %#ok<AGROW>
        block_d1_d1Only   = [block_d1_d1Only;   new_d1_row];  %#ok<AGROW>
        block_d0_d1Only   = [block_d0_d1Only;   new_d0_row];  %#ok<AGROW>

        rowToAnimal_d1Only = [rowToAnimal_d1Only; i];               %#ok<AGROW>
        rowToD1ID_d1Only   = [rowToD1ID_d1Only;   d1id_unplotted];  %#ok<AGROW>
        rowToD0ID_d1Only   = [rowToD0ID_d1Only;   d0id_match];      %#ok<AGROW>
    end
end

% Now reorder these new D1-only rows by peak time in the D1 block
blockCount_d1Only = size(block_d1_d1Only,1);
if blockCount_d1Only>0
    allRows_d1 = (1:blockCount_d1Only)';
    sorted_d1Only = orderByPeakTime(block_d1_d1Only, allRows_d1, tone_period);
    block_d28_d1Only = block_d28_d1Only(sorted_d1Only,:);
    block_d1_d1Only  = block_d1_d1Only(sorted_d1Only,:);
    block_d0_d1Only  = block_d0_d1Only(sorted_d1Only,:);
    rowToAnimal_d1Only = rowToAnimal_d1Only(sorted_d1Only);
    rowToD1ID_d1Only   = rowToD1ID_d1Only(sorted_d1Only);
    rowToD0ID_d1Only   = rowToD0ID_d1Only(sorted_d1Only);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) Bottom Block: D0-only neurons (not used in top or d1Only block)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

block_d28_d0Only = [];
block_d1_d0Only  = [];
block_d0_d0Only  = [];
rowToAnimal_d0Only = [];
rowToD1ID_d0Only   = [];
rowToD0ID_d0Only   = [];

% We'll also need to gather used D0 from top block + d1-only block
for i = 1:numAnimals
    n0   = size(peri_d0_cell{i},1);
    all0 = (1:n0)';
    
    usedD0_top   = rowToD0ID_top(rowToAnimal_top==i);
    usedD0_d1Blk = rowToD0ID_d1Only(rowToAnimal_d1Only==i);
    usedD0_any   = unique([usedD0_top(:); usedD0_d1Blk(:)]);
    usedD0_any(usedD0_any==0) = [];  % remove zeros
    unmatchedD0 = setdiff(all0, usedD0_any);

    for d0id_unplotted = unmatchedD0'
        new_d28_row = zeros(1, finalWinSize);
        new_d1_row  = zeros(1, finalWinSize);
        new_d0_row  = peri_d0_cell{i}(d0id_unplotted, :);

        d28id_match = NaN;
        d1id_match  = NaN;

        AlignT = align_tables{i};
        rA = find(AlignT.D0 == d0id_unplotted, 1, 'first');
        if ~isempty(rA)
            d28id_temp = AlignT.D28(rA);
            d1id_temp  = AlignT.D1(rA);
            if ~isnan(d28id_temp) && d28id_temp>0 && d28id_temp<=size(peri_d28_cell{i},1)
                new_d28_row = peri_d28_cell{i}(d28id_temp, :);
                d28id_match = d28id_temp;
            end
            if ~isnan(d1id_temp) && d1id_temp>0 && d1id_temp<=size(peri_d1_cell{i},1)
                new_d1_row = peri_d1_cell{i}(d1id_temp, :);
                d1id_match = d1id_temp;
            end
        end

        block_d28_d0Only = [block_d28_d0Only; new_d28_row]; %#ok<AGROW>
        block_d1_d0Only  = [block_d1_d0Only;  new_d1_row];  %#ok<AGROW>
        block_d0_d0Only  = [block_d0_d0Only;  new_d0_row];  %#ok<AGROW>

        rowToAnimal_d0Only = [rowToAnimal_d0Only; i];            %#ok<AGROW>
        rowToD1ID_d0Only   = [rowToD1ID_d0Only;   d1id_match];   %#ok<AGROW>
        rowToD0ID_d0Only   = [rowToD0ID_d0Only;   d0id_unplotted]; %#ok<AGROW>
    end
end

% Reorder these new D0-only rows by peak time in the D0 block
blockCount_d0Only = size(block_d0_d0Only,1);
if blockCount_d0Only>0
    allRows_d0 = (1:blockCount_d0Only)';
    sorted_d0Only = orderByPeakTime(block_d0_d0Only, allRows_d0, tone_period);
    block_d28_d0Only = block_d28_d0Only(sorted_d0Only,:);
    block_d1_d0Only  = block_d1_d0Only(sorted_d0Only,:);
    block_d0_d0Only  = block_d0_d0Only(sorted_d0Only,:);
    rowToAnimal_d0Only = rowToAnimal_d0Only(sorted_d0Only);
    rowToD1ID_d0Only   = rowToD1ID_d0Only(sorted_d0Only);
    rowToD0ID_d0Only   = rowToD0ID_d0Only(sorted_d0Only);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6) Combine all blocks in final arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Top block: D28-based
final_d28 = block_d28;
final_d1  = block_d1;
final_d0  = block_d0;
rowToAnimal = rowToAnimal_top;
rowToD1ID   = rowToD1ID_top;
rowToD0ID   = rowToD0ID_top;

% Middle block: D1-only
final_d28 = [final_d28; block_d28_d1Only]; %#ok<AGROW>
final_d1  = [final_d1;  block_d1_d1Only];  %#ok<AGROW>
final_d0  = [final_d0;  block_d0_d1Only];  %#ok<AGROW>
rowToAnimal = [rowToAnimal; rowToAnimal_d1Only]; %#ok<AGROW>
rowToD1ID   = [rowToD1ID;   rowToD1ID_d1Only];   %#ok<AGROW>
rowToD0ID   = [rowToD0ID;   rowToD0ID_d1Only];   %#ok<AGROW>

% Bottom block: D0-only
final_d28 = [final_d28; block_d28_d0Only]; %#ok<AGROW>
final_d1  = [final_d1;  block_d1_d0Only];  %#ok<AGROW>
final_d0  = [final_d0;  block_d0_d0Only];  
rowToAnimal = [rowToAnimal; rowToAnimal_d0Only]; 
rowToD1ID   = [rowToD1ID;   rowToD1ID_d0Only];   %#ok<AGROW>
rowToD0ID   = [rowToD0ID;   rowToD0ID_d0Only];   %#ok<AGROW>

% If you want boundaries for the new blocks, record them here as well:
topBlock_end   = nTopBlock;
d1Block_end    = nTopBlock + size(block_d1_d1Only,1);
% d0Block_end  = total final size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7) [Optional] Row-wise normalization of the final arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if normalizeEachRowFinal
    final_d28 = rowMinMaxNormalize(final_d28);
    final_d1  = rowMinMaxNormalize(final_d1);
    final_d0  = rowMinMaxNormalize(final_d0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8) Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For time axis in seconds
time_axis = (1:finalWinSize) / frames_per_second;
tone_time_start = (frame_buffer + 1) / frames_per_second;
tone_time_end   = (frame_buffer + tone_length) / frames_per_second;

figure('Position',[100,100,1800,600]);

% --- D28 subplot ---
subplot(1,3,1)
imagesc(time_axis, 1:size(final_d28,1), final_d28)
%ylim([1 81]); enable if want to just see D28
colormap hot
clim([0 1])
h1 = colorbar;
h1.Label.String = 'Activity (normalized)';
hold on

xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end,   'w--','LineWidth',1)

% Draw cyan lines only for top block transitions
yline(boundary_exc_supp + 0.5,  'c','LineWidth',2)
yline(boundary_supp_none + 0.5, 'c','LineWidth',2)

title('D28: Exc (top), Supp, None (top block), + D1-only, + D0-only')
xlabel('Time (s)')
ylabel('Neuron (stacked)')
xlim([0 max(time_axis)+1])

% If you want to mark block transitions for D1-only and D0-only, do so:
% yline(topBlock_end + 0.5, 'm','LineWidth',2);
% yline(d1Block_end + 0.5, 'm','LineWidth',2);

% --- D1 subplot ---
subplot(1,3,2)
imagesc(time_axis, 1:size(final_d1,1), final_d1)
%ylim([1 81]); enable if want to just see D28
colormap hot
clim([0 1])
h2 = colorbar;
h2.Label.String = 'Activity (normalized)';
hold on
xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end,   'w--','LineWidth',1)
title('D1 - same stacked row order')
xlabel('Time (s)')
xlim([0 max(time_axis)+1])

% Mark "E" or "S"
[numRows, ~] = size(final_d1);
for rowIdx = 1:numRows
    aIdx = rowToAnimal(rowIdx);
    d1id = rowToD1ID(rowIdx);
    if d1id>0
        d1_exc  = tone_neuron_mod{aIdx}{2}{1};
        d1_supp = tone_neuron_mod{aIdx}{2}{2};
        labelStr = '';
        if ismember(d1id, d1_exc)
            labelStr = 'E';
        elseif ismember(d1id, d1_supp)
            labelStr = 'S';
        end
        if ~isempty(labelStr)
    % Choose color based on E or S
    if strcmp(labelStr, 'E')
        labelColor = [0, 0.8, 0.8];       % bright cyan
    else % 'S'
        labelColor = [0, 0.8, 0.8];   % darker cyan
    end
    
    text(max(time_axis) + 0.5, rowIdx, labelStr, ...
        'Color',            labelColor, ...
        'FontWeight',       'bold', ...
        'HorizontalAlignment','left', ...
        'FontSize',         6, ...         % smaller font
        'Margin',           1);
    end
    end
end

% --- D0 subplot ---
tmp1 = final_d0(195,:);
tmp2 = final_d0(196,:);
final_d0(2,:) = tmp1;
final_d0(6,:) = tmp2;
subplot(1,3,3)
imagesc(time_axis, 1:size(final_d0,1), final_d0)
%ylim([1 81]); enable if want to just see D28
colormap hot
clim([0 1])
h3 = colorbar;
h3.Label.String = 'Activity (normalized)';
hold on
xline(tone_time_start, 'w--','LineWidth',1)

if ~isempty(d0_toneDurAll)
    d0_avgDur = mean(d0_toneDurAll);
    offset_time_d0 = (frame_buffer + d0_avgDur) / frames_per_second;
    xline(offset_time_d0, 'w--','LineWidth',1)
end
title('D0 - same stacked row order')
xlabel('Time (s)')
xlim([0 max(time_axis)+1])

% Mark E/S on D0
for rowIdx = 1:numRows
    aIdx = rowToAnimal(rowIdx);
    d0id = rowToD0ID(rowIdx);
    if d0id>0
        d0_exc  = tone_neuron_mod{aIdx}{1}{1};
        d0_supp = tone_neuron_mod{aIdx}{1}{2};
        labelStr = '';
        if ismember(d0id, d0_exc)
            labelStr = 'E';
        elseif ismember(d0id, d0_supp)
            labelStr = 'S';
        end
        if ~isempty(labelStr)
    % Choose color based on E or S
    if strcmp(labelStr, 'E')
        labelColor = [0, 0.8, 0.8];       % bright cyan
    else % 'S'
        labelColor = [0, 0.8, 0.8];   % darker cyan
    end
    
    text(max(time_axis) + 0.5, rowIdx, labelStr, ...
        'Color',            labelColor, ...
        'FontWeight',       'bold', ...
        'HorizontalAlignment','left', ...
        'FontSize',         6, ...         % smaller font
        'Margin',           1);
end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function normMat = rowMinMaxNormalize(rawMat)
% rowMinMaxNormalize:
%   Row-wise 0-1 normalization: (X - min)/(max - min).
normMat = zeros(size(rawMat));
for rr = 1:size(rawMat,1)
    mn = min(rawMat(rr,:));
    mx = max(rawMat(rr,:));
    if mx > mn
        normMat(rr,:) = (rawMat(rr,:) - mn) / (mx - mn);
    end
end
end

function [periResp, offsetIndex] = buildFixedWindowPeriToneWithOffset(...
    sigMat, toneVec, forcedToneDur, frameBuf, finalWinSize)
toneOn  = find(diff([0 toneVec]) == 1);
toneOff = find(diff([toneVec 0]) == -1);
nTones  = min(length(toneOn), length(toneOff));
toneOn  = toneOn(1:nTones);
toneOff = toneOff(1:nTones);

[numNeurons, ~] = size(sigMat);
periResp = zeros(numNeurons, finalWinSize);

if nTones == 0
    offsetIndex = frameBuf+1;
    return;
end

dayDur     = mean(toneOff - toneOn + 1);
offsetIndex= floor(frameBuf + dayDur);

for nn = 1:numNeurons
    allTrials = [];
    for t = 1:nTones
        tOn  = toneOn(t) - frameBuf;
        tOff = toneOn(t) + forcedToneDur - 1 + frameBuf;
        if tOn<1 || tOff>size(sigMat,2), continue; end
        snippet = sigMat(nn, tOn:tOff);
        L = length(snippet);
        if L<finalWinSize
            padded = zeros(1, finalWinSize);
            padded(1:L) = snippet;
            allTrials = [allTrials; padded]; %#ok<AGROW>
        elseif L>finalWinSize
            allTrials = [allTrials; snippet(1:finalWinSize)]; %#ok<AGROW>
        else
            allTrials = [allTrials; snippet]; %#ok<AGROW>
        end
    end
    if ~isempty(allTrials)
        periResp(nn,:) = mean(allTrials,1);
    end
end
end

function sorted_indices = orderByPeakTime(dataMat, rowIndices, tone_period)
% Reorder the given rowIndices by the peak time within tone_period in dataMat
if isempty(rowIndices)
    sorted_indices = [];
    return;
end
peak_times = zeros(length(rowIndices),1);
for i = 1:length(rowIndices)
    rr = rowIndices(i);
    rowData = dataMat(rr, tone_period);
    [~, maxLoc] = max(rowData);
    peak_times(i) = maxLoc;
end
[~, sort_idx] = sort(peak_times, 'ascend');
sorted_indices = rowIndices(sort_idx);
end
