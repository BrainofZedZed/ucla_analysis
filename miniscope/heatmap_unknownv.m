%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER OPTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

normalizeEachRowFinal = false;  % If true, each row in final_d28/d1/d0 is 0-1 normalized
tone_length  = 897;            % forced tone length for D1 & D28
frame_buffer = 150;            % frames on each side for D1 & D28
finalWinSize = 2*frame_buffer + tone_length;  % e.g., 1197 columns
frames_per_second = 30;        % 900 frames = 30 seconds

numAnimals = length(align_tables);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) Build "global" lists for D28 excited / suppressed / none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global_exc   = [];  % [animalIdx, d28ID]
global_supp  = [];
global_none  = [];
d0_toneDurAll = [];  % we'll gather each animal's average tone duration

for i = 1:numAnimals
    % Day 28 classification from nested tone_neuron_mod: dayIndex=3 => D28
    exc28  = tone_neuron_mod{i}{3}{1};  % excited
    supp28 = tone_neuron_mod{i}{3}{2};  % suppressed
    n28    = size(sigs_d28{i},1);
    allIDs = (1:n28)';
    none28 = setdiff(allIDs, [exc28(:); supp28(:)]);
    
    % Append these to global arrays
    global_exc  = [global_exc;  [repmat(i,numel(exc28),1),  exc28(:) ] ];
    global_supp = [global_supp; [repmat(i,numel(supp28),1), supp28(:)] ];
    global_none = [global_none; [repmat(i,numel(none28),1), none28(:)] ];
    
    % Compute D0's actual average tone duration for animal i
    d0_toneOn  = find(diff([0 tone_vecs_d0{i}]) == 1);
    d0_toneOff = find(diff([tone_vecs_d0{i} 0]) == -1);
    nTones  = min(length(d0_toneOn), length(d0_toneOff));
    if nTones>0
        d0_dur = mean(d0_toneOff(1:nTones) - d0_toneOn(1:nTones) + 1);
        d0_toneDurAll = [d0_toneDurAll; d0_dur];
    end
end

% Combine them: all excited, then suppressed, then none
bigList = [global_exc; global_supp; global_none];
Nexc  = size(global_exc,1);
Nsupp = size(global_supp,1);
Nnone = size(global_none,1);

% Boundaries (for D28 subplot)
boundary_exc_supp = Nexc;        % row where excited ends, suppressed begins
boundary_supp_none = Nexc+Nsupp;  % row where suppressed ends, none begins

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) Prebuild each day's peri-tone for each animal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

peri_d28_cell = cell(1,numAnimals);
peri_d1_cell  = cell(1,numAnimals);
peri_d0_cell  = cell(1,numAnimals);

for i = 1:numAnimals
    % Row-wise 0-1 normalization
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
% 3) Construct final arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

final_d28 = zeros(Nexc+Nsupp+Nnone, finalWinSize);
final_d1  = zeros(Nexc+Nsupp+Nnone, finalWinSize);
final_d0  = zeros(Nexc+Nsupp+Nnone, finalWinSize);
rowToD1ID = zeros(Nexc+Nsupp+Nnone,1);
rowToD0ID = zeros(Nexc+Nsupp+Nnone,1);
rowToAnimal = zeros(Nexc+Nsupp+Nnone,1);

for rowIdx = 1:(Nexc+Nsupp+Nnone)
    animalIdx = bigList(rowIdx,1);
    d28id     = bigList(rowIdx,2);
    
    % Insert D28 data
    final_d28(rowIdx,:) = peri_d28_cell{animalIdx}(d28id,:);
    
    % Look up matched D1 & D0 from align_tables
    AlignT = align_tables{animalIdx};
    rA = find(AlignT.D28 == d28id, 1, 'first');
    if ~isempty(rA)
        d1id = AlignT.D1(rA);
        d0id = AlignT.D0(rA);
        if ~isnan(d1id) && d1id>0 && d1id<=size(peri_d1_cell{animalIdx},1)
            final_d1(rowIdx,:) = peri_d1_cell{animalIdx}(d1id,:);
            rowToD1ID(rowIdx)  = d1id;
        end
        if ~isnan(d0id) && d0id>0 && d0id<=size(peri_d0_cell{animalIdx},1)
            final_d0(rowIdx,:) = peri_d0_cell{animalIdx}(d0id,:);
            rowToD0ID(rowIdx)  = d0id;
        end
    end
    rowToAnimal(rowIdx) = animalIdx;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) Sort neurons within each category by peak timing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get indices for each category
exc_indices = 1:Nexc;
supp_indices = (Nexc+1):(Nexc+Nsupp);
none_indices = (Nexc+Nsupp+1):(Nexc+Nsupp+Nnone);

% Define tone period indices for peak finding
tone_start_idx = frame_buffer + 1;
tone_end_idx = frame_buffer + tone_length;
tone_period = tone_start_idx:tone_end_idx;

% Sort each category by peak timing
exc_sorted = orderByPeakTime(final_d28, exc_indices, tone_period);
supp_sorted = orderByPeakTime(final_d28, supp_indices, tone_period);
none_sorted = orderByPeakTime(final_d28, none_indices, tone_period);

% Create new order and reorder all matrices
new_order = [exc_sorted; supp_sorted; none_sorted];
final_d28 = final_d28(new_order, :);
final_d1 = final_d1(new_order, :);
final_d0 = final_d0(new_order, :);
rowToD1ID = rowToD1ID(new_order);
rowToD0ID = rowToD0ID(new_order);
rowToAnimal = rowToAnimal(new_order);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5) [Optional] Row-wise normalization of the final arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if normalizeEachRowFinal
    final_d28 = rowMinMaxNormalize(final_d28);
    final_d1  = rowMinMaxNormalize(final_d1);
    final_d0  = rowMinMaxNormalize(final_d0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6) Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Create time axis
time_axis = (1:finalWinSize) / frames_per_second;
tone_time_start = (frame_buffer + 1) / frames_per_second;
tone_time_end = (frame_buffer + tone_length) / frames_per_second;

figure('Position',[100,100,1800,600]);

% --- D28 subplot ---
subplot(1,3,1)
imagesc(time_axis, 1:size(final_d28,1), final_d28)
colormap hot
clim([0 1])
h1 = colorbar;
h1.Label.String = 'Activity (normalized)';
hold on

xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end, 'w--','LineWidth',1)
yline(boundary_exc_supp + 0.5, 'c','LineWidth',2)
yline(boundary_supp_none + 0.5, 'c','LineWidth',2)

title('D28: Exc (top), Supp, None (bottom)')
xlabel('Time (s)')
ylabel('Neuron (global)')
xlim([0 max(time_axis)+1])

% --- D1 subplot ---
subplot(1,3,2)
imagesc(time_axis, 1:size(final_d1,1), final_d1)
colormap hot
clim([0 1])
h2 = colorbar;
h2.Label.String = 'Activity (normalized)';
hold on

xline(tone_time_start, 'w--','LineWidth',1)
xline(tone_time_end, 'w--','LineWidth',1)

title('D1 - same row order')
xlabel('Time (s)')
xlim([0 max(time_axis)+1])

% Mark "E" or "S"
[numRows, ~] = size(final_d1);
for rowIdx = 1:numRows
    aIdx = rowToAnimal(rowIdx);
    d1id = rowToD1ID(rowIdx);
    if d1id>0
        d1_exc = tone_neuron_mod{aIdx}{2}{1};
        d1_supp = tone_neuron_mod{aIdx}{2}{2};
        labelStr = '';
        if ismember(d1id, d1_exc)
            labelStr = 'E';
        elseif ismember(d1id, d1_supp)
            labelStr = 'S';
        end
        if ~isempty(labelStr)
            text(max(time_axis)+0.5, rowIdx, labelStr, ...
                'Color','white', ...
                'FontWeight','bold', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', 'black', ...
                'FontSize', 8, ...
                'Margin', 1);
        end
    end
end

% --- D0 subplot ---
subplot(1,3,3)
imagesc(time_axis, 1:size(final_d0,1), final_d0)
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

title('D0 - same row order')
xlabel('Time (s)')
xlim([0 max(time_axis)+1])

% D0 E/S labels
for rowIdx = 1:numRows
    aIdx = rowToAnimal(rowIdx);
    d0id = rowToD0ID(rowIdx);
    if d0id>0
        d0_exc = tone_neuron_mod{aIdx}{1}{1};
        d0_supp = tone_neuron_mod{aIdx}{1}{2};
        labelStr = '';
        if ismember(d0id, d0_exc)
            labelStr = 'E';
        elseif ismember(d0id, d0_supp)
            labelStr = 'S';
        end
        if ~isempty(labelStr)
            text(max(time_axis)+0.5, rowIdx, labelStr, ...
                'Color','white', ...
                'FontWeight','bold', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor', 'black', ...
                'FontSize', 8, ...
                'Margin', 1);
        end
    end
end

% Add legend for E/S
annotation('textbox', [0.95 0.8 0.04 0.1], ...
    'String', {'E: Excited','S: Suppressed'}, ...
    'EdgeColor', 'white', ...
    'Color', 'white', ...
    'BackgroundColor', 'black', ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function normMat = rowMinMaxNormalize(rawMat)
% Row-wise 0-1 normalization: (X - min)/(max - min).
% If a row is constant, it becomes all zeros.
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
% Returns:
%   periResp   = [numNeurons x finalWinSize], skipping partial out-of-bound trials
%   offsetIndex= ~floor(frameBuf + dayDur)

toneOn  = find(diff([0 toneVec]) == 1);
toneOff = find(diff([toneVec 0]) == -1);
nTones  = min(length(toneOn), length(toneOff));
toneOn  = toneOn(1:nTones);
toneOff = toneOff(1:nTones);

[numNeurons, ~] = size(sigMat);
periResp = zeros(numNeurons,