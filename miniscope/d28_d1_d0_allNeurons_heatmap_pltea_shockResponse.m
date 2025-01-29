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
% 1) Build list of shock-responsive neurons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global_shock_exc  = [];  % [animalIdx, d0ID]
global_shock_supp = [];

for i = 1:numAnimals
    % Get shock response classifications from D0 (dayIndex=1)
    shock_exc  = tone_neuron_mod{1,i}{1,1}{1,3};  % shock excited
    shock_supp = tone_neuron_mod{1,i}{1,1}{1,4};  % shock suppressed
    
    % Append these to global arrays
    global_shock_exc  = [global_shock_exc;  [repmat(i,numel(shock_exc),1),  shock_exc(:) ] ];
    global_shock_supp = [global_shock_supp; [repmat(i,numel(shock_supp),1), shock_supp(:)]];
end

% Combine shock excited and suppressed lists
bigList = [global_shock_exc; global_shock_supp];
boundary_shock_exc_supp = size(global_shock_exc,1);

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
    
    % Build forced-window peri-tone
    [peri_d28_cell{i}, ~] = buildFixedWindowPeriToneWithOffset(...
        s28norm, tone_vecs_d28{i}, tone_length, frame_buffer, finalWinSize);
    [peri_d1_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s1norm,  tone_vecs_d1{i},  tone_length, frame_buffer, finalWinSize);
    [peri_d0_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s0norm,  tone_vecs_d0{i},  tone_length, frame_buffer, finalWinSize);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) Construct response arrays for shock-responsive neurons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nRows = size(bigList,1);
block_d28 = zeros(nRows, finalWinSize);
block_d1  = zeros(nRows, finalWinSize);
block_d0  = zeros(nRows, finalWinSize);

rowToD1ID = zeros(nRows,1);
rowToD0ID = zeros(nRows,1);
rowToAnimal = zeros(nRows,1);

% Store response types for labeling
d0_types = cell(nRows,1);
d1_types = cell(nRows,1);
d28_types = cell(nRows,1);

for rowIdx = 1:nRows
    animalIdx = bigList(rowIdx,1);
    d0id = bigList(rowIdx,2);
    
    % Start with D0 data
    if d0id>0 && d0id<=size(peri_d0_cell{animalIdx},1)
        block_d0(rowIdx,:) = peri_d0_cell{animalIdx}(d0id,:);
        rowToD0ID(rowIdx) = d0id;
        
        % Determine D0 response type
        if rowIdx <= boundary_shock_exc_supp
            d0_types{rowIdx} = 'ShE';  % Shock excited
        else
            d0_types{rowIdx} = 'ShS';  % Shock suppressed
        end
    end
    
    % Look up matched D1 & D28 from align_tables
    AlignT = align_tables{animalIdx};
    rA = find(AlignT.D0 == d0id, 1, 'first');
    if ~isempty(rA)
        d1id = AlignT.D1(rA);
        d28id = AlignT.D28(rA);
        
        % Add D1 data and response type
        if ~isnan(d1id) && d1id>0 && d1id<=size(peri_d1_cell{animalIdx},1)
            block_d1(rowIdx,:) = peri_d1_cell{animalIdx}(d1id,:);
            rowToD1ID(rowIdx) = d1id;
            
            % Check if D1 neuron was excited or suppressed
            tone_exc_d1 = tone_neuron_mod{animalIdx}{2}{1};
            tone_supp_d1 = tone_neuron_mod{animalIdx}{2}{2};
            if ismember(d1id, tone_exc_d1)
                d1_types{rowIdx} = 'E';
            elseif ismember(d1id, tone_supp_d1)
                d1_types{rowIdx} = 'S';
            else
                d1_types{rowIdx} = '-';
            end
        end
        
        % Add D28 data and response type
        if ~isnan(d28id) && d28id>0 && d28id<=size(peri_d28_cell{animalIdx},1)
            block_d28(rowIdx,:) = peri_d28_cell{animalIdx}(d28id,:);
            
            % Check if D28 neuron was excited or suppressed
            tone_exc_d28 = tone_neuron_mod{animalIdx}{3}{1};
            tone_supp_d28 = tone_neuron_mod{animalIdx}{3}{2};
            if ismember(d28id, tone_exc_d28)
                d28_types{rowIdx} = 'E';
            elseif ismember(d28id, tone_supp_d28)
                d28_types{rowIdx} = 'S';
            else
                d28_types{rowIdx} = '-';
            end
        end
    end
    
    rowToAnimal(rowIdx) = animalIdx;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) Sort neurons by peak response time in D0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tone_start_idx = frame_buffer + 1;
tone_end_idx   = frame_buffer + tone_length;
tone_period    = tone_start_idx:tone_end_idx;

% Sort excited and suppressed groups separately
shock_exc_indices = 1:boundary_shock_exc_supp;
shock_supp_indices = (boundary_shock_exc_supp + 1):nRows;

shock_exc_sorted = orderByPeakTime(block_d0, shock_exc_indices, tone_period);
shock_supp_sorted = orderByPeakTime(block_d0, shock_supp_indices, tone_period);

% Combine sorted indices
new_order = [shock_exc_sorted(:); shock_supp_sorted(:)];

% Reorder all arrays
block_d28 = block_d28(new_order, :);
block_d1  = block_d1(new_order, :);
block_d0  = block_d0(new_order, :);
rowToD1ID = rowToD1ID(new_order);
rowToD0ID = rowToD0ID(new_order);
rowToAnimal = rowToAnimal(new_order);
d0_types = d0_types(new_order);
d1_types = d1_types(new_order);
d28_types = d28_types(new_order);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if normalizeEachRowFinal
    block_d28 = rowMinMaxNormalize(block_d28);
    block_d1  = rowMinMaxNormalize(block_d1);
    block_d0  = rowMinMaxNormalize(block_d0);
end

time_axis = (1:finalWinSize) / frames_per_second;
tone_time_start = (frame_buffer + 1) / frames_per_second;
tone_time_end   = (frame_buffer + tone_length) / frames_per_second;

figure('Position',[100,100,1800,600]);

% --- D0 subplot ---
subplot(1,3,1)
imagesc(time_axis, 1:size(block_d0,1), block_d0)
colormap hot
clim([0 1])
h1 = colorbar;
h1.Label.String = 'Activity (normalized)';
hold on

% Add tone timing lines
xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_start+10, 'w--','LineWidth',1)

% Draw boundary between excited and suppressed
if boundary_shock_exc_supp > 0
    yline(boundary_shock_exc_supp + 0.5, 'c','LineWidth',2)
end

title('D0: Shock-Excited → Shock-Suppressed')
xlabel('Time (s)')
ylabel('Neuron (sorted by peak time)')
xlim([0 max(time_axis)])

% Add response type labels
for i = 1:nRows
    if ~isempty(d0_types{i})
        text(max(time_axis) + 0.5, i, d0_types{i}, ...
            'Color', [0, 0.8, 0.8], ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 8)
    end
end

% --- D1 subplot ---
subplot(1,3,2)
imagesc(time_axis, 1:size(block_d1,1), block_d1)
colormap hot
clim([0 1])
h2 = colorbar;
h2.Label.String = 'Activity (normalized)';
hold on

% Add tone timing lines
xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end, 'w--','LineWidth',1)

% Draw boundary between excited and suppressed
if boundary_shock_exc_supp > 0
    yline(boundary_shock_exc_supp + 0.5, 'c','LineWidth',2)
end

title('D1 (aligned to D0)')
xlabel('Time (s)')
xlim([0 max(time_axis)])

% Add response type labels
for i = 1:nRows
    if ~isempty(d1_types{i})
        text(max(time_axis) + 0.5, i, d1_types{i}, ...
            'Color', [0, 0.8, 0.8], ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 8)
    end
end

% --- D28 subplot ---
subplot(1,3,3)
imagesc(time_axis, 1:size(block_d28,1), block_d28)
colormap hot
clim([0 1])
h3 = colorbar;
h3.Label.String = 'Activity (normalized)';
hold on

% Add tone timing lines
xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end, 'w--','LineWidth',1)

% Draw boundary between excited and suppressed
if boundary_shock_exc_supp > 0
    yline(boundary_shock_exc_supp + 0.5, 'c','LineWidth',2)
end

title('D28 (aligned to D0)')
xlabel('Time (s)')
xlim([0 max(time_axis)])

% Add response type labels
for i = 1:nRows
    if ~isempty(d28_types{i})
        text(max(time_axis) + 0.5, i, d28_types{i}, ...
            'Color', [0, 0.8, 0.8], ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 8)
    end
end

%%
% Add helper functions at the bottom
function normMat = rowMinMaxNormalize(rawMat)
    % rowMinMaxNormalize:
    %   Row-wise 0-1 normalization: (X - min)/(max - min)
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
    % Build peri-stimulus time windows around each tone presentation
    % Inputs:
    %   sigMat: Matrix of neural signals [neurons x time]
    %   toneVec: Binary vector indicating tone timing
    %   forcedToneDur: Fixed duration to use for all tones
    %   frameBuf: Number of frames to include before/after tone
    %   finalWinSize: Total size of the window
    
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
                allTrials = [allTrials; padded];
            elseif L>finalWinSize
                allTrials = [allTrials; snippet(1:finalWinSize)];
            else
                allTrials = [allTrials; snippet];
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