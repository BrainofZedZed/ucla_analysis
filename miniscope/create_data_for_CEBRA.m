% Assuming you have sigfn, spkfn, cueframes.csm, cueframes.csp, Behavior, and
% Metrics loaded

%% Part 0: check for different calcium data names
if exist("finalC", "var")
    sigfn = finalC;
end
if exist("Cdata","var")
    sigfn = Cdata;
end

if exist("finalS", "var")
    spkfn = finalS;
end
if exist("Sdata", "var")
    spkfn = Sdata;
end

%% Part 1: translate behavior frames to miniscope frames
% Create deep copies of the original variables
translated_csm = Behavior.Temporal.csm.Vector;
translated_csp = Behavior.Temporal.csp.Vector;
translated_Freezing_Bouts = Behavior.Freezing.Vector;

% Translate translated_csm
for i = 1:size(translated_csm, 1)
    idx_begin = find(frtslu(:, 2) == translated_csm(i, 1));
    idx_end = find(frtslu(:, 2) == translated_csm(i, 2));
    if ~isempty(idx_begin) && ~isempty(idx_end)
        translated_csm(i, 1) = frtslu(idx_begin, 3);
        translated_csm(i, 2) = frtslu(idx_end, 3);
    end
end

% Translate translated_csp
for i = 1:size(translated_csp, 1)
    idx_begin = find(frtslu(:, 2) == translated_csp(i, 1));
    idx_end = find(frtslu(:, 2) == translated_csp(i, 2));
    if ~isempty(idx_begin) && ~isempty(idx_end)
        translated_csp(i, 1) = frtslu(idx_begin, 3);
        translated_csp(i, 2) = frtslu(idx_end, 3);
    end
end

% Translate translated_Freezing_Bouts
for i = 1:size(translated_Freezing_Bouts, 1)
    idx_begin = find(frtslu(:, 2) == translated_Freezing_Bouts(i, 1));
    idx_end = find(frtslu(:, 2) == translated_Freezing_Bouts(i, 2));
    if ~isempty(idx_begin) && ~isempty(idx_end)
        translated_Freezing_Bouts(i, 1) = frtslu(idx_begin, 3);
        translated_Freezing_Bouts(i, 2) = frtslu(idx_end, 3);
    end
end

% Save the translated variables into ms_frames structure
ms_frames.csm = translated_csm;
ms_frames.csp = translated_csp;
ms_frames.Freezing = translated_Freezing_Bouts;

%% Part 2:  vectorize everything and code it
% 0 = pre-tone; 1 = CS-; 2 = CS+; 3 = CS- ITI; 4 = CS+ ITI
% Initialize all_tone_data as zeros
all_tone_data = zeros(1, length(sigfn));

%% downsample head velocity to match miniscope frames
% Original time base
originalTimeBase = linspace(1, length(Metrics.Velocity.Head), length(Metrics.Velocity.Head));

% New time base
newTimeBase = linspace(1, length(Metrics.Velocity.Head), length(sigfn));

% Interpolate to downsample
velocity_data = interp1(originalTimeBase, Metrics.Velocity.Head, newTimeBase, 'linear');

%% downsample freeze vector to match miniscope frames
% Original time base
originalTimeBase = linspace(1, length(Behavior.Freezing.Vector), length(Behavior.Freezing.Vector));

% New time base
newTimeBase = linspace(1, length(Behavior.Freezing.Vector), length(sigfn));

% Interpolate to downsample
freezing_data = interp1(originalTimeBase, Behavior.Freezing.Vector, newTimeBase, 'linear');


%% Mark periods defined by cueframes.csm
for i = 1:size(ms_frames.csm, 1)
    all_tone_data(ms_frames.csm(i, 1):ms_frames.csm(i, 2)) = 1;
    
    % Mark indices between end and begin of cueframes.csm with value 3
    if i < size(ms_frames.csm, 1)
        all_tone_data(ms_frames.csm(i, 2)+1:ms_frames.csm(i+1, 1)-1) = 3;
    else
        % If it's the last row of cueframes.csm, fill until the first row of cueframes.csp
        all_tone_data(ms_frames.csm(i, 2)+1:ms_frames.csp(1, 1)-1) = 3;
    end
end

% Mark periods defined by cueframes.csp
for i = 1:size(ms_frames.csp, 1)
    all_tone_data(ms_frames.csp(i, 1):ms_frames.csp(i, 2)) = 2;
    
    % Mark indices between end and begin of cueframes.csp with value 4
    if i < size(ms_frames.csp, 1)
        all_tone_data(ms_frames.csp(i, 2)+1:ms_frames.csp(i+1, 1)-1) = 4;
    else
        % If it's the last row of cueframes.csp, fill until the end of all_tone_data
        all_tone_data(ms_frames.csp(i, 2)+1:end) = 4;
    end
end

% Get the lengths of the vectors
length_freeze = length(ms_frames.Freezing);
length_all_tone = length(all_tone_data);

% Check if the lengths are different
if length_freeze < length_all_tone
    % If freeze_vector is shorter, append zeros to it
    number_of_zeros = length_all_tone - length_freeze;
    freeze_vector = [freeze_vector, zeros(number_of_zeros, 1)]; % appending zeros vertically
elseif length_freeze > length_all_tone
    error('freeze_vector is longer than all_tone_data. Unable to proceed.');
end

save('data_for_cebra.mat', 'all_tone_data',"velocity_data","freeze_vector", 'sigfn', 'spkfn');
disp('done');
clear;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Original time base
orig = Behavior.Temporal.csp.Vector;
originalTimeBase = linspace(1, length(orig), length(orig));

% New time base
newtb = sigfn;
newTimeBase = linspace(1, length(orig), length(newtb));

% Interpolate to downsample
new_vec = interp1(originalTimeBase, orig, newTimeBase, 'linear');

