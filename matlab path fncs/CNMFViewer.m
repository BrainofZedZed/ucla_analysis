function CNMFViewer(A, C, S)
% CNMFViewer  Curation tool for CNMF output (footprints A, traces C, optional spikes S).
%
%   CNMFViewer(A, C)      - curate footprints + calcium traces
%   CNMFViewer(A, C, S)   - same, plus deconvolved spikes shown under each trace
%
% A is expected as (height x width x components). C and S are expected as
% (components x frames). If A appears to be (components x H x W), or if C/S
% appear to be (frames x components) -- i.e., more rows than columns -- they
% are reoriented automatically and a warning is issued.
%
% Each "page" focuses on one currently-active component (the *anchor*) and
% shows it alongside its k-1 nearest currently-active spatial neighbors so the
% user can decide whether to merge or discard.
%
% Index conventions (several index spaces are involved -- read this once):
%   - oIdx                  : original index into the input arrays (1..Z),
%                             stable for the life of the session.
%   - slotIdx               : 1..numItemsPerPage, position on screen.
%   - pageOriginalIdx       : column vector of oIdx values currently shown,
%                             with the anchor in slot 1. (Was `closestZ`.)
%   - componentLabel(oIdx)  : label shown to the user. Equals oIdx by default.
%                             For components merged into another it equals the
%                             surviving oIdx; -1 if discarded. (Was `displayIDs`.)
%   - isActive(oIdx)        : true if the component is still in the kept set
%                             (not merged-away, not discarded). (Was `validZ`.)
%   - mergedInto(oIdx)      : surviving oIdx this was merged into (== oIdx if
%                             it survived, NaN if discarded).
%
% Buttons:
%   Merge / Discard / Normalize / Next / Back / Done   - curation actions.
%   Corr Map                                           - opens a separate
%       figure with an N x N pairwise Pearson correlation matrix between the
%       C traces of all currently-active components.
%
% The "Done" button prompts for an output file (uiputfile) and saves:
%   finalA, finalC, finalS  : kept components only, in original-order.
%                             finalS is [] when S was not provided.
%   originalToFinal(oIdx)   : index into final* for each oIdx, NaN if the
%                             component was discarded or merged away.
%   mergedInto, componentLabel, isActive : as above, for full traceability.
%
% 2023-08-01 ZZ, refactored 2026.

    % ---- input validation ---------------------------------------------------
    narginchk(2, 3);
    if nargin < 3
        S = [];
    end
    haveS = ~isempty(S);

    % Auto-detect C/S orientation. Expected: (components x frames). Frames
    % always outnumber components in real recordings, so a matrix with more
    % rows than columns is taken to be transposed.
    if size(C, 1) > size(C, 2)
        C = C.';
        warning('CNMFViewer:transposedC', ...
                'C appears to be (frames x components); transposing to (components x frames).');
    end
    if haveS && size(S, 1) > size(S, 2)
        S = S.';
        warning('CNMFViewer:transposedS', ...
                'S appears to be (frames x components); transposing to (components x frames).');
    end

    [Zc, T] = size(C);

    if haveS
        [Zs, Ts] = size(S);
        if Zs ~= Zc || Ts ~= T
            error('CNMFViewer:dimMismatch', ...
                  'S must be the same size as C (%dx%d), got %dx%d.', Zc, T, Zs, Ts);
        end
    end

    % Auto-detect A orientation. Expected: (height x width x components). If
    % A is supplied as (components x height x width), permute it. Anything
    % else is an error.
    if size(A, 3) == Zc
        % already in (H x W x C) orientation
    elseif size(A, 1) == Zc
        A = permute(A, [2, 3, 1]);
        warning('CNMFViewer:permutedA', ...
                ['A was supplied as (components x height x width); ' ...
                 'permuting to (height x width x components).']);
    else
        error('CNMFViewer:dimMismatch', ...
              'A dimensions [%s] do not match the %d components in C.', ...
              num2str(size(A)), Zc);
    end

    [~, ~, Z] = size(A);  % Z == Zc here

    % ---- state --------------------------------------------------------------
    numItemsPerPage = 5;
    currentPage     = 1;

    isActive          = true(Z, 1);
    componentLabel    = (1:Z)';
    mergedInto        = (1:Z)';
    pageOriginalIdx   = [];

    % weighted center-of-mass per component, [row_com, col_com]
    centers = computeCenters(A);

    % ---- figure & axes ------------------------------------------------------
    fig = figure('Name', 'CNMFViewer', 'Position', [100, 100, 1200, 800]);

    axC = gobjects(numItemsPerPage, 1);
    if haveS
        axS = gobjects(numItemsPerPage, 1);
        for i = 1:numItemsPerPage
            top = 0.8 - 0.15*i;
            axC(i) = axes(fig, 'Position', [0.6, top + 0.04, 0.3, 0.09]);
            axS(i) = axes(fig, 'Position', [0.6, top,        0.3, 0.04]);
        end
    else
        axS = gobjects(0);
        for i = 1:numItemsPerPage
            axC(i) = axes(fig, 'Position', [0.6, 0.8 - 0.15*i, 0.3, 0.13]);
        end
    end

    % Link x-axes of all signal-display panels: zooming/panning one trace
    % moves the same window in all the others.
    if haveS
        linkaxes([axC; axS], 'x');
    else
        linkaxes(axC, 'x');
    end

    axA      = axes(fig, 'Position', [0.1, 0.5,  0.3, 0.4]);
    axBatchA = axes(fig, 'Position', [0.1, 0.05, 0.3, 0.4]);

    labelPage = uicontrol('Style', 'text', 'Position', [820, 10, 270, 30], 'String', '');

    uicontrol('Style', 'pushbutton', 'String', 'Merge',     'Position', [100, 10, 100, 30], 'Callback', @(~,~) mergeSelected());
    uicontrol('Style', 'pushbutton', 'String', 'Discard',   'Position', [200, 10, 100, 30], 'Callback', @(~,~) discardSelected());
    uicontrol('Style', 'pushbutton', 'String', 'Normalize', 'Position', [300, 10, 100, 30], 'Callback', @(~,~) normalizeC());
    uicontrol('Style', 'pushbutton', 'String', 'Next',      'Position', [400, 10, 100, 30], 'Callback', @(~,~) nextPage());
    uicontrol('Style', 'pushbutton', 'String', 'Back',      'Position', [500, 10, 100, 30], 'Callback', @(~,~) previousPage());
    uicontrol('Style', 'pushbutton', 'String', 'Done',      'Position', [600, 10, 100, 30], 'Callback', @(~,~) done());
    uicontrol('Style', 'pushbutton', 'String', 'Corr Map',  'Position', [710, 10, 100, 30], 'Callback', @(~,~) showCorrelationMap());

    checkboxes = gobjects(numItemsPerPage, 1);

    updateDisplay();

    % ---- callbacks ----------------------------------------------------------
    function mergeSelected()
        sel = getCheckedOriginalIdx();
        if numel(sel) < 2
            return;  % need at least 2 to merge
        end
        keepID   = min(sel);
        absorbed = setdiff(sel, keepID);

        for z = absorbed'
            C(keepID, :)  = C(keepID, :) + C(z, :);
            if haveS
                S(keepID, :) = S(keepID, :) + S(z, :);
            end
            A(:,:,keepID) = A(:,:,keepID) + A(:,:,z);
            isActive(z)   = false;
        end
        % redirect bookkeeping: any oIdx (including the absorbed ones, and any
        % cell that was previously merged INTO one of the absorbed ones) now
        % points to keepID. This keeps the chain flat.
        redirect = ismember(mergedInto, absorbed);
        mergedInto(redirect)     = keepID;
        componentLabel(redirect) = keepID;

        % footprint of the surviving component changed -> recompute its COM
        centers(keepID, :) = computeCenters(A(:,:,keepID));
        updateDisplay();
    end

    function discardSelected()
        sel = getCheckedOriginalIdx();
        for z = sel'
            isActive(z)       = false;
            componentLabel(z) = -1;
            mergedInto(z)     = NaN;
        end
        updateDisplay();
    end

    function normalizeC()
        % normalize each active trace to [0,1]; guard against flat traces.
        rows = find(isActive);
        if isempty(rows)
            return;
        end
        Cact = C(rows, :);
        mn   = min(Cact, [], 2);
        mx   = max(Cact, [], 2);
        rng  = max(mx - mn, eps);
        C(rows, :) = (Cact - mn) ./ rng;
        updateDisplay();
    end

    function nextPage()
        currentPage = min(currentPage + 1, max(1, sum(isActive)));
        updateDisplay();
    end

    function previousPage()
        currentPage = max(1, currentPage - 1);
        updateDisplay();
    end

    function done()
        finalA = A(:, :, isActive);
        finalC = C(isActive, :);
        if haveS
            finalS = S(isActive, :);
        else
            finalS = [];
        end

        originalToFinal = nan(Z, 1);
        originalToFinal(isActive) = 1:sum(isActive);

        [fname, fpath] = uiputfile('*.mat', 'Save curated CNMF data', ...
                                   'cleaned_cnmf_data.mat');
        if isequal(fname, 0)
            return;  % user cancelled; leave figure open
        end
        save(fullfile(fpath, fname), ...
             'finalA', 'finalC', 'finalS', ...
             'originalToFinal', 'mergedInto', 'componentLabel', 'isActive', '-v7.3');
        close(fig);
    end

    function showCorrelationMap()
        % Show an N x N Pearson correlation matrix between the C traces of
        % every currently-active component. Cells are ordered by oIdx, and
        % tick labels show their componentLabel.

        nActive = sum(isActive);
        if nActive < 2
            return;
        end
        activeIdx = find(isActive);
        labels    = componentLabel(activeIdx);

        % --- pairwise correlation matrix ---
        R = corrMatrix(C(activeIdx, :));   % nActive x nActive

        % --- reuse one tagged figure across clicks ---
        corrFig = findobj('Type', 'figure', 'Tag', 'CNMFViewerCorrMap');
        if isempty(corrFig)
            corrFig = figure('Tag', 'CNMFViewerCorrMap', ...
                             'Position', [200, 200, 720, 640]);
        else
            figure(corrFig);
            clf(corrFig);
        end
        set(corrFig, 'Name', 'CNMFViewer - Correlation Matrix');

        axMat = axes(corrFig, 'Position', [0.12, 0.12, 0.76, 0.78]);
        hImg  = imagesc(axMat, R);
        set(hImg, 'AlphaData', ~isnan(R));   % zero-variance rows -> transparent
        axis(axMat, 'image');
        colormap(axMat, blueWhiteRedColormap(256));
        set(axMat, 'CLim', [-1, 1]);
        cb = colorbar(axMat);
        cb.Label.String = 'Pearson r';

        % tick labels: show all if few cells, otherwise sparsify
        maxLabels = 25;
        if nActive <= maxLabels
            tickPos = 1:nActive;
        else
            tickPos = unique(round(linspace(1, nActive, maxLabels)));
        end
        tickStr = arrayfun(@(z) sprintf('%d', z), labels(tickPos), 'UniformOutput', false);
        set(axMat, 'XTick', tickPos, 'YTick', tickPos, ...
                   'XTickLabel', tickStr, 'YTickLabel', tickStr);
        xtickangle(axMat, 90);
        xlabel(axMat, 'Component N');
        ylabel(axMat, 'Component N');
        title(axMat, sprintf('Pairwise Pearson correlation (%d active components)', nActive));
    end

    % ---- display ------------------------------------------------------------
    function updateDisplay()
        % wipe last frame
        cla(axA);  cla(axBatchA);
        for i = 1:numItemsPerPage
            cla(axC(i));
            if haveS, cla(axS(i)); end
        end
        delete(checkboxes(isgraphics(checkboxes)));
        checkboxes = gobjects(numItemsPerPage, 1);

        nActive    = sum(isActive);
        totalPages = max(1, nActive);

        if nActive == 0
            labelPage.String = 'No active components remain.';
            return;
        end

        currentPage = min(max(currentPage, 1), totalPages);
        activeIdx   = find(isActive);
        anchorOIdx  = activeIdx(currentPage);

        % nearest active neighbors of the anchor
        d             = sqrt(sum((centers - centers(anchorOIdx, :)).^2, 2));
        d(~isActive)  = Inf;
        d(anchorOIdx) = Inf;
        [~, order]    = sort(d, 'ascend');
        nNeighbors    = min(numItemsPerPage - 1, sum(isfinite(d)));
        pageOriginalIdx = [anchorOIdx; order(1:nNeighbors)];   % column, anchor first

        % per-trace plots
        for slot = 1:numel(pageOriginalIdx)
            oIdx = pageOriginalIdx(slot);

            plot(axC(slot), C(oIdx, :), 'k');
            if slot == 1
                title(axC(slot), sprintf('C: N = %d  (anchor)', componentLabel(oIdx)));
            else
                title(axC(slot), sprintf('C: N = %d', componentLabel(oIdx)));
            end
            axC(slot).XTick = [];

            if haveS
                stem(axS(slot), S(oIdx, :), 'Marker', 'none', 'Color', [0.8 0 0]);
                axS(slot).YTick = [];
            end

            checkboxes(slot) = uicontrol('Style', 'checkbox', ...
                                         'Position', [750, 770 - 130*slot, 15, 15]);
        end

        % displayed-footprints panel
        imagesc(axA, sum(A(:, :, pageOriginalIdx), 3));
        colormap(axA, 'parula');
        axis(axA, 'image');
        title(axA, 'Displayed footprints (anchor in red)');
        for slot = 1:numel(pageOriginalIdx)
            oIdx = pageOriginalIdx(slot);
            c    = centers(oIdx, :);   % [row, col]
            if all(isfinite(c))
                if slot == 1, color = 'r'; else, color = 'w'; end
                text(axA, c(2), c(1), num2str(componentLabel(oIdx)), ...
                     'Color', color, 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center');
            end
        end

        % all-active-footprints panel
        imagesc(axBatchA, sum(A(:,:,isActive), 3));
        colormap(axBatchA, 'parula');
        axis(axBatchA, 'image');
        title(axBatchA, sprintf('All active footprints (%d)', nActive));

        labelPage.String = sprintf('Page: %d / %d   (anchor N = %d)', ...
                                   currentPage, totalPages, componentLabel(anchorOIdx));
    end

    function sel = getCheckedOriginalIdx()
        % return original indices for currently-checked checkboxes (column vec)
        nShown   = numel(pageOriginalIdx);
        checked  = false(nShown, 1);
        for slot = 1:nShown
            h = checkboxes(slot);
            if isgraphics(h) && h.Value == 1
                checked(slot) = true;
            end
        end
        sel = pageOriginalIdx(checked);
    end
end

% ---- module-level helpers ---------------------------------------------------
function centers = computeCenters(A)
% Value-weighted centers of mass for each Z-slice of A. centers is [Z x 2]
% as [row_com, col_com]. Returns [NaN NaN] for components with zero mass.
    [N, M, Z] = size(A);
    [X, Y]    = meshgrid(1:M, 1:N);
    centers   = nan(Z, 2);
    for z = 1:Z
        w    = double(A(:,:,z));
        wsum = sum(w(:));
        if wsum > 0
            centers(z, :) = [sum(Y(:).*w(:))/wsum, sum(X(:).*w(:))/wsum];
        end
    end
end

function R = corrMatrix(Y)
% Pairwise Pearson correlation matrix for the rows of Y (N x T -> N x N).
% Rows with zero variance produce NaN entries. Avoids the Statistics
% Toolbox dependency of corr().
    Yc    = Y - mean(Y, 2);
    norms = sqrt(sum(Yc.^2, 2));            % N x 1
    R     = (Yc * Yc.') ./ (norms * norms.');
    R(~isfinite(R)) = NaN;
end

function cmap = blueWhiteRedColormap(n)
% Diverging blue -> white -> red colormap, suitable for [-1, 1] data.
    if nargin < 1, n = 256; end
    half  = floor(n/2);
    upper = n - half;
    blue  = [linspace(0.13, 1, half).',  linspace(0.40, 1, half).',  linspace(0.71, 1, half).'];
    red   = [linspace(1, 0.84, upper).', linspace(1, 0.19, upper).', linspace(1, 0.15, upper).'];
    cmap  = [blue; red];
end