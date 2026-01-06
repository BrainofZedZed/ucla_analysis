% aggregateROCData_script.m
% This script compiles ROC count data from multiple ca_roc_output.mat files 
% into a table, adds sig-row counts, overlap sets, and counts per cell-column,
% then serializes and saves as CSV.

%% Specify top‐level directory
inputDir = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\good\CSminus removed';

%% Find first‐level subdirectories
d1 = dir(inputDir);
d1 = d1([d1.isdir] & ~ismember({d1.name},{'.','..'}));

%% Preallocate storage
ID                     = {};
freeze_excited         = {};
freeze_suppressed      = {};
tone_excited           = {};
tone_suppressed        = {};
shock_excited          = {};
shock_suppressed       = {};
postshock_excited      = {};
postshock_suppressed   = {};
sig_row_count          = nan(0,1);

%% Loop through each second‐level folder and load data
for i = 1:numel(d1)
    path1 = fullfile(inputDir, d1(i).name);
    d2 = dir(path1);
    d2 = d2([d2.isdir] & ~ismember({d2.name},{'.','..'}));
    
    for j = 1:numel(d2)
        thisID   = d2(j).name;
        filePath = fullfile(path1, thisID, 'ca_roc_output.mat');
        
        if exist(filePath,'file')==2
            S   = load(filePath,'out','sig');
            out = S.out;
            sig = S.sig;
            
            ID{end+1,1} = thisID;
            
            % freeze
            if isfield(out,'freeze') && ~isempty(out.freeze.n_excited)
                freeze_excited{end+1,1}    = out.freeze.n_excited;
            else
                freeze_excited{end+1,1}    = NaN;
            end
            if isfield(out,'freeze') && ~isempty(out.freeze.n_suppressed)
                freeze_suppressed{end+1,1} = out.freeze.n_suppressed;
            else
                freeze_suppressed{end+1,1} = NaN;
            end
            
            % tone (CSp)
            if isfield(out,'CSp') && ~isempty(out.CSp.n_excited)
                tone_excited{end+1,1}    = out.CSp.n_excited;
            else
                tone_excited{end+1,1}    = NaN;
            end
            if isfield(out,'CSp') && ~isempty(out.CSp.n_suppressed)
                tone_suppressed{end+1,1} = out.CSp.n_suppressed;
            else
                tone_suppressed{end+1,1} = NaN;
            end
            
            % shock
            if isfield(out,'shock') && ~isempty(out.shock.n_excited)
                shock_excited{end+1,1}    = out.shock.n_excited;
            else
                shock_excited{end+1,1}    = NaN;
            end
            if isfield(out,'shock') && ~isempty(out.shock.n_suppressed)
                shock_suppressed{end+1,1} = out.shock.n_suppressed;
            else
                shock_suppressed{end+1,1} = NaN;
            end
            
            % postshock
            if isfield(out,'postshock') && ~isempty(out.postshock.n_excited)
                postshock_excited{end+1,1}    = out.postshock.n_excited;
            else
                postshock_excited{end+1,1}    = NaN;
            end
            if isfield(out,'postshock') && ~isempty(out.postshock.n_suppressed)
                postshock_suppressed{end+1,1} = out.postshock.n_suppressed;
            else
                postshock_suppressed{end+1,1} = NaN;
            end

            % sig‐row count
            if ~isempty(sig)
                sig_row_count(end+1,1) = size(sig,1);
            else
                sig_row_count(end+1,1) = NaN;
            end
            
        else
            warning('File not found: %s', filePath);
        end
    end
end

%% Assemble into a table with cell columns
T = table( ...
    ID, ...
    freeze_excited, freeze_suppressed, ...
    tone_excited,  tone_suppressed,  ...
    shock_excited, shock_suppressed, ...
    postshock_excited, postshock_suppressed, ...
    'VariableNames', { ...
      'ID', ...
      'freeze_excited','freeze_suppressed', ...
      'tone_excited','tone_suppressed', ...
      'shock_excited','shock_suppressed', ...
      'postshock_excited','postshock_suppressed' ...
    } ...
);

%% Add sig‐row count before freeze_excited
T = addvars(T, sig_row_count, ...
    'Before','freeze_excited', ...
    'NewVariableNames','sig_row_count');

%% Count number of entries in each original ROC column
n_freeze_excited        = cellfun(@numel, T.freeze_excited);
n_freeze_suppressed     = cellfun(@numel, T.freeze_suppressed);
n_tone_excited          = cellfun(@numel, T.tone_excited);
n_tone_suppressed       = cellfun(@numel, T.tone_suppressed);
n_shock_excited         = cellfun(@numel, T.shock_excited);
n_shock_suppressed      = cellfun(@numel, T.shock_suppressed);
n_postshock_excited     = cellfun(@numel, T.postshock_excited);
n_postshock_suppressed  = cellfun(@numel, T.postshock_suppressed);

T = addvars( T, ...
    n_freeze_excited,    n_freeze_suppressed,  ...
    n_tone_excited,      n_tone_suppressed,    ...
    n_shock_excited,     n_shock_suppressed,   ...
    n_postshock_excited, n_postshock_suppressed, ...
    'After','postshock_suppressed', ...
    'NewVariableNames', { ...
      'number_freeze_excited', 'number_freeze_suppressed', ...
      'number_tone_excited',   'number_tone_suppressed',   ...
      'number_shock_excited',  'number_shock_suppressed',  ...
      'number_postshock_excited','number_postshock_suppressed' } ...
);

%% Compute overlap sets between freeze, tone, shock
nRows = height(T);
freeze_and_tone       = cell(nRows,1);
freeze_and_shock      = cell(nRows,1);
tone_and_shock        = cell(nRows,1);
freeze_tone_and_shock = cell(nRows,1);

for i = 1:nRows
    fr = unique([T.freeze_excited{i}(:);    T.freeze_suppressed{i}(:)]);
    fr(isnan(fr)) = [];
    to = unique([T.tone_excited{i}(:);      T.tone_suppressed{i}(:)]);
    to(isnan(to)) = [];
    sh = unique([T.shock_excited{i}(:);     T.shock_suppressed{i}(:)]);
    sh(isnan(sh)) = [];
    
    freeze_and_tone{i}       = intersect(fr, to);
    freeze_and_shock{i}      = intersect(fr, sh);
    tone_and_shock{i}        = intersect(to, sh);
    freeze_tone_and_shock{i} = intersect(freeze_and_tone{i}, sh);
end

%% Add overlap columns
T.freeze_and_tone       = freeze_and_tone;
T.freeze_and_shock      = freeze_and_shock;
T.tone_and_shock        = tone_and_shock;
T.freeze_tone_and_shock = freeze_tone_and_shock;

%% Serialize only cell‐array columns for CSV export
vars = T.Properties.VariableNames(2:end);  % skip ID
for k = 1:numel(vars)
    col = T.(vars{k});
    if iscell(col)
        T.(vars{k}) = cellfun(@mat2str, col, 'UniformOutput', false);
    end
end

%% Save table as CSV in the input directory
writetable(T, fullfile(inputDir, 'aggregate_neuron_mod_ID2.csv'));
