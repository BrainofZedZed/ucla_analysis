%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Neural Response Alignment and Visualization Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
normalizeEachRowFinal = true;  % If true, each row is 0-1 normalized after building all blocks
tone_length  = 897;            % forced tone length for D1 & D28
frame_buffer = 300;            % frames on each side for D1 & D28
finalWinSize = 2*frame_buffer + tone_length;
frames_per_second = 30;        % for x-axis in seconds

% Alignment options
plot_d0_aligned = true;      % If true, aligns to D0 shock responses
plot_d28_aligned = false;    % If true, aligns to D28 tone responses
plotAllNeurons = true;       % If true, plots all neurons instead of just modulated ones

% Safety check - only one alignment can be true
if plot_d0_aligned && plot_d28_aligned
    error('Cannot plot both alignments simultaneously. Choose either D0 or D28 alignment.');
end

if ~plot_d0_aligned && ~plot_d28_aligned
    error('Must choose at least one alignment type (D0 or D28).');
end

numAnimals = length(align_tables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN ANALYSIS PIPELINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine alignment type
alignToD28 = plot_d28_aligned;

% 1) Build aligned neuron lists based on options
if alignToD28
    [neuronList, boundary_exc_supp, boundary_supp_other] = buildNeuronList(align_tables, ...
        tone_neuron_mod, 3, numAnimals, plotAllNeurons, sigs_d28);
else
    [neuronList, boundary_exc_supp, boundary_supp_other] = buildNeuronList(align_tables, ...
        tone_neuron_mod, 1, numAnimals, plotAllNeurons, sigs_d0);
end

% 2) Prebuild peri-event responses
peri_d28_cell = cell(1,numAnimals);
peri_d1_cell  = cell(1,numAnimals);
peri_d0_cell  = cell(1,numAnimals);

for i = 1:numAnimals
    % Row-wise normalization
    s28norm = rowMinMaxNormalize(sigs_d28{i});
    s1norm  = rowMinMaxNormalize(sigs_d1{i});
    s0norm  = rowMinMaxNormalize(sigs_d0{i});
    
    % Build fixed-window responses
    [peri_d28_cell{i}, ~] = buildFixedWindowPeriToneWithOffset(...
        s28norm, tone_vecs_d28{i}, tone_length, frame_buffer, finalWinSize);
    [peri_d1_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s1norm,  tone_vecs_d1{i},  tone_length, frame_buffer, finalWinSize);
    [peri_d0_cell{i},  ~] = buildFixedWindowPeriToneWithOffset(...
        s0norm,  tone_vecs_d0{i},  tone_length, frame_buffer, finalWinSize);
end

% 3) Build response blocks
[responseBlocks, neuronInfo] = buildResponseBlocks(neuronList, ...
    boundary_exc_supp, boundary_supp_other, align_tables, peri_d0_cell, peri_d1_cell, ...
    peri_d28_cell, tone_neuron_mod, alignToD28);

% 4) Sort neurons
tone_start_idx = frame_buffer + 1;
tone_end_idx   = frame_buffer + tone_length;
tone_period    = tone_start_idx:tone_end_idx;

if alignToD28
    new_order = orderByPeakTimeAndType(responseBlocks.d28, ...
        1:size(responseBlocks.d28,1), tone_period, boundary_exc_supp, boundary_supp_other, plot_d0_aligned);
else
    new_order = orderByPeakTimeAndType(responseBlocks.d0, ...
        1:size(responseBlocks.d0,1), tone_period, boundary_exc_supp, boundary_supp_other, plot_d0_aligned);
end

% 5) Reorder all arrays
responseBlocks.d28 = responseBlocks.d28(new_order, :);
responseBlocks.d1  = responseBlocks.d1(new_order, :);
responseBlocks.d0  = responseBlocks.d0(new_order, :);

% Reorder neuron metadata
neuronInfo.rowToD1ID = neuronInfo.rowToD1ID(new_order);
neuronInfo.rowToD0ID = neuronInfo.rowToD0ID(new_order);
neuronInfo.rowToD28ID = neuronInfo.rowToD28ID(new_order);
neuronInfo.rowToAnimal = neuronInfo.rowToAnimal(new_order);
neuronInfo.d0_types = neuronInfo.d0_types(new_order);
neuronInfo.d1_types = neuronInfo.d1_types(new_order);
neuronInfo.d28_types = neuronInfo.d28_types(new_order);

% 6) Apply final normalization if requested
if normalizeEachRowFinal
    responseBlocks.d28 = rowMinMaxNormalize(responseBlocks.d28);
    responseBlocks.d1  = rowMinMaxNormalize(responseBlocks.d1);
    responseBlocks.d0  = rowMinMaxNormalize(responseBlocks.d0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VISUALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setup time axis
time_axis = (1:finalWinSize) / frames_per_second;
tone_time_start = (frame_buffer + 1) / frames_per_second;
tone_time_end   = (frame_buffer + tone_length) / frames_per_second;

% Create figure
figure('Position',[100,100,1800,600]);

% Plot aligned responses
if alignToD28
    alignment_type = 'D28';
else
    alignment_type = 'D0';
end

createAlignmentPlots(responseBlocks, neuronInfo, alignment_type, ...
    time_axis, tone_time_start, tone_time_end, boundary_exc_supp, boundary_supp_other);

%%
% HELPER FXNS

function createAlignmentPlots(responseBlocks, neuronInfo, alignment_type, time_axis, tone_time_start, tone_time_end, boundary_exc_supp, boundary_supp_other)
    figure('Position',[100,100,1800,600]);
    
    % Set up colorbars for response types
    respTypeWidth = 0.01;  % Width of response type colorbar
    
    % D0 subplot
    ax1 = subplot(1,3,1);
    % Main plot position
    pos = get(gca, 'Position');
    mainPos = [pos(1), pos(2), pos(3)-respTypeWidth, pos(4)];
    set(gca, 'Position', mainPos)
    
    imagesc(time_axis, 1:size(responseBlocks.d0,1), responseBlocks.d0)
    colormap hot
    clim([0 1])
    h1 = colorbar;
    h1.Label.String = 'Activity (normalized)';
    hold on
    
    % Add tone timing lines
    xline(tone_time_start, 'w--','LineWidth',1)
    xline(tone_time_end, 'w--','LineWidth',1)
    
    % Draw boundaries
    if boundary_exc_supp > 0
        yline(boundary_exc_supp + 0.5, 'c', 'LineWidth', 2)
    end
    if boundary_supp_other > 0
        yline(boundary_supp_other + 0.5, 'g', 'LineWidth', 2)
    end
    
    if strcmp(alignment_type, 'D0')
        title('D0: Shock-Excited → Shock-Suppressed → Other')
    else
        title('D0 (aligned to D28)')
    end
    xlabel('Time (s)')
    ylabel('Neuron (sorted by peak time)')
    xlim([0 max(time_axis)])
    
    % Add response type colorbar
        axes('Position', [mainPos(1)+mainPos(3), mainPos(2), respTypeWidth, mainPos(4)])
    responseColors = zeros(size(responseBlocks.d0,1), 1, 3);
    for i = 1:size(responseBlocks.d0,1)
        if strcmp(alignment_type, 'D0')
            if i <= boundary_exc_supp
                responseColors(i,1,:) = [1, 0.5, 0];  % Orange for shock-excited
            elseif i <= boundary_supp_other
                responseColors(i,1,:) = [0, 0, 0];    % Black for shock-suppressed
            else
                responseColors(i,1,:) = [1, 1, 1];    % White for other
            end
        else
            if ~isempty(neuronInfo.d0_types{i})
                if strcmp(neuronInfo.d0_types{i}, 'ShE')
                    responseColors(i,1,:) = [1, 0.5, 0];  % Orange for shock-excited
                elseif strcmp(neuronInfo.d0_types{i}, 'ShS')
                    responseColors(i,1,:) = [0, 0, 0];    % Black for shock-suppressed
                else
                    responseColors(i,1,:) = [1, 1, 1];    % White for other
                end
            else
                responseColors(i,1,:) = [1, 1, 1];        % White for empty
            end
        end
    end
    image(responseColors)
    axis off
    
    % D1 subplot with similar modifications...
    ax2 = subplot(1,3,2);
    pos = get(gca, 'Position');
    mainPos = [pos(1), pos(2), pos(3)-respTypeWidth, pos(4)];
    set(gca, 'Position', mainPos)
    
    imagesc(time_axis, 1:size(responseBlocks.d1,1), responseBlocks.d1)
    colormap hot
    clim([0 1])
    h2 = colorbar;
    h2.Label.String = 'Activity (normalized)';
    hold on
    
    xline(tone_time_start, 'w--','LineWidth',1)
    xline(tone_time_end, 'w--','LineWidth',1)
    
    
    if strcmp(alignment_type, 'D0')
        title('D1 (aligned to D0)')
    else
        title('D1 (aligned to D28)')
    end
    xlabel('Time (s)')
    xlim([0 max(time_axis)])
    
    % Response type colorbar for D1
    axes('Position', [mainPos(1)+mainPos(3), mainPos(2), respTypeWidth, mainPos(4)])
    responseColors = zeros(size(responseBlocks.d1,1), 1, 3);
    for i = 1:size(responseBlocks.d1,1)
        if ~isempty(neuronInfo.d1_types{i})
            if strcmp(neuronInfo.d1_types{i}, 'E')
                responseColors(i,1,:) = [1, 0.5, 0];
            elseif strcmp(neuronInfo.d1_types{i}, 'S')
                responseColors(i,1,:) = [0, 0, 0];
            else
                responseColors(i,1,:) = [1, 1, 1];
            end
        else
            responseColors(i,1,:) = [1, 1, 1];
        end
    end
    image(responseColors)
    axis off
    
    % D28 subplot with similar modifications...
    ax3 = subplot(1,3,3);
    pos = get(gca, 'Position');
    mainPos = [pos(1), pos(2), pos(3)-respTypeWidth, pos(4)];
    set(gca, 'Position', mainPos)
    
    imagesc(time_axis, 1:size(responseBlocks.d28,1), responseBlocks.d28)
    colormap hot
    clim([0 1])
    h3 = colorbar;
    h3.Label.String = 'Activity (normalized)';
    hold on
    
    xline(tone_time_start, 'w--','LineWidth',1)
    xline(tone_time_end, 'w--','LineWidth',1)
    
    if boundary_exc_supp > 0
        yline(boundary_exc_supp + 0.5, 'c', 'LineWidth', 2)
    end
    if boundary_supp_other > 0
        yline(boundary_supp_other + 0.5, 'g', 'LineWidth', 2)
    end
    
    if strcmp(alignment_type, 'D0')
        title('D28 (aligned to D0)')
    else
        title('D28: Tone-Excited → Tone-Suppressed → Other')
    end
    xlabel('Time (s)')
    xlim([0 max(time_axis)])
    
    % Response type colorbar for D28
    axes('Position', [mainPos(1)+mainPos(3), mainPos(2), respTypeWidth, mainPos(4)])
    responseColors = zeros(size(responseBlocks.d28,1), 1, 3);
    for i = 1:size(responseBlocks.d28,1)
        if ~isempty(neuronInfo.d28_types{i})
            if strcmp(neuronInfo.d28_types{i}, 'E')
                responseColors(i,1,:) = [1, 0.5, 0];
            elseif strcmp(neuronInfo.d28_types{i}, 'S')
                responseColors(i,1,:) = [0, 0, 0];
            else
                responseColors(i,1,:) = [1, 1, 1];
            end
        else
            responseColors(i,1,:) = [1, 1, 1];
        end
    end
    image(responseColors)
    axis off
    linkaxes([ax1 ax2 ax3], 'xy');

end

function [neuronList, boundary_exc_supp, boundary_supp_other] = buildNeuronList(align_tables, tone_neuron_mod, ...
    dayIdx, animalCount, plotAllNeurons, sigs)
    
    global_exc = [];
    global_supp = [];
    global_other = [];
    
    for i = 1:animalCount
        % Get modulated neurons based on day
        if dayIdx == 1  % D0
            exc_neurons = tone_neuron_mod{1,i}{1,dayIdx}{1,3};  % excited
            supp_neurons = tone_neuron_mod{1,i}{1,dayIdx}{1,4}; % suppressed
        else  % D1 or D28
            exc_neurons = tone_neuron_mod{1,i}{1,dayIdx}{1,1};  % excited
            supp_neurons = tone_neuron_mod{1,i}{1,dayIdx}{1,2}; % suppressed
        end
        
        if plotAllNeurons
            % Get all neurons for the day
            maxNeuronID = size(sigs{1,i},1);
            all_neurons = 1:maxNeuronID;
            
            % Find non-responsive neurons
            other_neurons = setdiff(all_neurons, [exc_neurons; supp_neurons]);
        
            % Add to global lists maintaining separate categories
            global_exc = [global_exc; [repmat(i,numel(exc_neurons),1), exc_neurons(:)]];
            global_supp = [global_supp; [repmat(i,numel(supp_neurons),1), supp_neurons(:)]];
            global_other = [global_other; [repmat(i,numel(other_neurons),1), other_neurons(:)]];
        else
            % Only include modulated neurons
            global_exc = [global_exc; [repmat(i,numel(exc_neurons),1), exc_neurons(:)]];
            global_supp = [global_supp; [repmat(i,numel(supp_neurons),1), supp_neurons(:)]];
        end
    end
    
    % Combine all categories maintaining boundaries
    neuronList = [global_exc; global_supp; global_other];
    boundary_exc_supp = size(global_exc,1);
    boundary_supp_other = boundary_exc_supp + size(global_supp,1);
end

function [responseBlocks, neuronInfo] = buildResponseBlocks(neuronList, boundary_exc_supp, ...
    boundary_supp_other, align_tables, peri_d0_cell, peri_d1_cell, peri_d28_cell, tone_neuron_mod, alignToD28)

    nRows = size(neuronList,1);
    finalWinSize = size(peri_d0_cell{1},2);
    
    % Initialize response blocks
    block_d28 = zeros(nRows, finalWinSize);
    block_d1  = zeros(nRows, finalWinSize);
    block_d0  = zeros(nRows, finalWinSize);
    
    % Initialize tracking arrays
    rowToD1ID = zeros(nRows,1);
    rowToD0ID = zeros(nRows,1);
    rowToD28ID = zeros(nRows,1);
    rowToAnimal = zeros(nRows,1);
    
    % Store response types
    d0_types = cell(nRows,1);
    d1_types = cell(nRows,1);
    d28_types = cell(nRows,1);
    
    for rowIdx = 1:nRows
        animalIdx = neuronList(rowIdx,1);
        AlignT = align_tables{animalIdx};
        
        if alignToD28
            % D28 alignment logic
            d28id = neuronList(rowIdx,2);
            rA = find(AlignT.D28 == d28id, 1, 'first');
            
            if ~isempty(rA)
                d0id = AlignT.D0(rA);
                d1id = AlignT.D1(rA);
                
                % Add D28 data first (primary alignment)
                if d28id>0 && d28id<=size(peri_d28_cell{animalIdx},1)
                    block_d28(rowIdx,:) = peri_d28_cell{animalIdx}(d28id,:);
                    rowToD28ID(rowIdx) = d28id;
                    
                    % Set tone response type based on row position
                    if rowIdx <= boundary_exc_supp
                        d28_types{rowIdx} = 'E';
                    elseif rowIdx <= boundary_supp_other
                        d28_types{rowIdx} = 'S';
                    else
                        d28_types{rowIdx} = '-';
                    end
                end
                
                % Add D0 data and determine shock modulation
                if ~isnan(d0id) && d0id>0 && d0id<=size(peri_d0_cell{animalIdx},1)
                    block_d0(rowIdx,:) = peri_d0_cell{animalIdx}(d0id,:);
                    rowToD0ID(rowIdx) = d0id;
                    
                    % Check shock modulation regardless of row position
                    shock_exc = tone_neuron_mod{animalIdx}{1}{3};
                    shock_supp = tone_neuron_mod{animalIdx}{1}{4};
                    if ismember(d0id, shock_exc)
                        d0_types{rowIdx} = 'ShE';
                    elseif ismember(d0id, shock_supp)
                        d0_types{rowIdx} = 'ShS';
                    else
                        d0_types{rowIdx} = '-';
                    end
                end
                
                % Add D1 data
                if ~isnan(d1id) && d1id>0 && d1id<=size(peri_d1_cell{animalIdx},1)
                    block_d1(rowIdx,:) = peri_d1_cell{animalIdx}(d1id,:);
                    rowToD1ID(rowIdx) = d1id;
                    
                    % Check tone modulation for D1
                    tone_exc = tone_neuron_mod{animalIdx}{2}{1};
                    tone_supp = tone_neuron_mod{animalIdx}{2}{2};
                    if ismember(d1id, tone_exc)
                        d1_types{rowIdx} = 'E';
                    elseif ismember(d1id, tone_supp)
                        d1_types{rowIdx} = 'S';
                    else
                        d1_types{rowIdx} = '-';
                    end
                end
            end
            
        else
            % D0 alignment logic
            d0id = neuronList(rowIdx,2);
            rA = find(AlignT.D0 == d0id, 1, 'first');
            
            % Add D0 data first (primary alignment)
            if d0id>0 && d0id<=size(peri_d0_cell{animalIdx},1)
                block_d0(rowIdx,:) = peri_d0_cell{animalIdx}(d0id,:);
                rowToD0ID(rowIdx) = d0id;
                
                % Set shock response type based on row position
                if rowIdx <= boundary_exc_supp
                    d0_types{rowIdx} = 'ShE';
                elseif rowIdx <= boundary_supp_other
                    d0_types{rowIdx} = 'ShS';
                else
                    d0_types{rowIdx} = '-';
                end
            end
            
            if ~isempty(rA)
                d1id = AlignT.D1(rA);
                d28id = AlignT.D28(rA);
                
                % Add D1 data and determine tone modulation
                if ~isnan(d1id) && d1id>0 && d1id<=size(peri_d1_cell{animalIdx},1)
                    block_d1(rowIdx,:) = peri_d1_cell{animalIdx}(d1id,:);
                    rowToD1ID(rowIdx) = d1id;
                    
                    % Check tone modulation
                    tone_exc = tone_neuron_mod{animalIdx}{2}{1};
                    tone_supp = tone_neuron_mod{animalIdx}{2}{2};
                    if ismember(d1id, tone_exc)
                        d1_types{rowIdx} = 'E';
                    elseif ismember(d1id, tone_supp)
                        d1_types{rowIdx} = 'S';
                    else
                        d1_types{rowIdx} = '-';
                    end
                end
                
                % Add D28 data and determine tone modulation
                if ~isnan(d28id) && d28id>0 && d28id<=size(peri_d28_cell{animalIdx},1)
                    block_d28(rowIdx,:) = peri_d28_cell{animalIdx}(d28id,:);
                    rowToD28ID(rowIdx) = d28id;
                    
                    % Check tone modulation
                    tone_exc = tone_neuron_mod{animalIdx}{3}{1};
                    tone_supp = tone_neuron_mod{animalIdx}{3}{2};
                    if ismember(d28id, tone_exc)
                        d28_types{rowIdx} = 'E';
                    elseif ismember(d28id, tone_supp)
                        d28_types{rowIdx} = 'S';
                    else
                        d28_types{rowIdx} = '-';
                    end
                end
            end
        end
        
        rowToAnimal(rowIdx) = animalIdx;
    end
    
    % Package outputs
    responseBlocks = struct('d0', block_d0, 'd1', block_d1, 'd28', block_d28);
    neuronInfo = struct('rowToD0ID', rowToD0ID, 'rowToD1ID', rowToD1ID, ...
        'rowToD28ID', rowToD28ID, 'rowToAnimal', rowToAnimal, ...
        'd0_types', {d0_types}, 'd1_types', {d1_types}, ...
        'd28_types', {d28_types});
end

function normMat = rowMinMaxNormalize(rawMat)
    % rowMinMaxNormalize: Performs row-wise min-max normalization
    %   Each row is independently scaled to range from 0 to 1
    %
    % Inputs:
    %   rawMat: Input matrix to normalize [N x T]
    %
    % Returns:
    %   normMat: Normalized matrix [N x T]
    
    normMat = zeros(size(rawMat));
    for rr = 1:size(rawMat,1)
        mn = min(rawMat(rr,:));
        mx = max(rawMat(rr,:));
        if mx > mn
            normMat(rr,:) = (rawMat(rr,:) - mn) / (mx - mn);
        end
    end
end

function [periResp, offsetIndex] = buildFixedWindowPeriToneWithOffset(sigMat, toneVec, forcedToneDur, frameBuf, finalWinSize)
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

function sorted_indices = orderByPeakTimeAndType(dataMat, rowIndices, tone_period, ...
    boundary_exc_supp, boundary_supp_other, plot_d0_aligned)
    
    if isempty(rowIndices)
        sorted_indices = [];
        return;
    end
    
    % Split indices by type using both boundaries
    exc_indices = rowIndices(rowIndices <= boundary_exc_supp);
    supp_indices = rowIndices(rowIndices > boundary_exc_supp & ...
        rowIndices <= boundary_supp_other);
    other_indices = rowIndices(rowIndices > boundary_supp_other);
    
    % Sort each group independently by peak time
    exc_sorted = orderByPeakTime(dataMat, exc_indices, tone_period, false, plot_d0_aligned);
    supp_sorted = orderByPeakTime(dataMat, supp_indices, tone_period, false, plot_d0_aligned);
    other_sorted = orderByPeakTime(dataMat, other_indices, tone_period, true, plot_d0_aligned);
    
    % Combine all sorted groups maintaining boundaries
    sorted_indices = [exc_sorted(:); supp_sorted(:); other_sorted(:)];
end

function sorted_indices = orderByPeakTime(dataMat, rowIndices, tone_period, is_other, plot_d0_aligned)
    if isempty(rowIndices)
        sorted_indices = [];
        return;
    end
    
    if nargin < 4
        is_other = false;
    end
    
    peak_times = zeros(length(rowIndices),1);
    for i = 1:length(rowIndices)
        rr = rowIndices(i);
        if is_other && plot_d0_aligned
            % For other neurons, look at first 10s of tone
            rowData = dataMat(rr, 300:600);
        else
            rowData = dataMat(rr, tone_period);
        end
        [~, maxLoc] = max(rowData);
        peak_times(i) = maxLoc;
    end
    [~, sort_idx] = sort(peak_times, 'ascend');
    sorted_indices = rowIndices(sort_idx);
end