function CNMFViewer_vid(A, C, S, videoPath)
% homebrew version of CNMFViewer from Minian with Video Integration
% 2023 08 01 ZZ
    [Nx, Mx, Z] = size(A);
    [Zx, ~] = size(C);
    numItemsToDisplay = 5;
    currentPage = 1;
    closestZ = [];
    displayIDs = 1:Z;
    alreadyDisplayed = false(Z, 1);
    currentZDisplay = [];

    % Video Integration
    videoObj = VideoReader(videoPath);
    numFrames = floor(videoObj.Duration * videoObj.FrameRate);
    currentFrame = 1;

    if Z ~= Zx
        error('Z dimension must match for A and C.');
    end

    % Calculate total pages
    totalPages = ceil(Z / numItemsToDisplay);

    centers = zeros(Z, 2);
    for zIdx = 1:Z
        [row, col] = find(A(:, :, zIdx) > 0);
        centers(zIdx, :) = [mean(row), mean(col)];
    end

    validZ = true(Z, 1); % Initially, all Z items are valid
    mergeMapping = cell(Z, 1);
    for i = 1:Z
        mergeMapping{i} = i; % Initially, each item is in a separate group
    end

    distances = pdist2(centers, centers);

    fig = figure('Name', 'Interactive Data Visualizer', 'Position', [100, 100, 1200, 800]);

    axC = gobjects(numItemsToDisplay, 1);
    for i = 1:numItemsToDisplay
        axC(i) = axes(fig, 'Position', [0.6, 0.8 - 0.15*i, 0.3, 0.13]);
    end

    axA = axes(fig, 'Position', [0.1, 0.5, 0.3, 0.4]);

    % Video Axes
    axVideo = axes(fig, 'Position', [0.1, 0.05, 0.3, 0.4]);

    % Page label
    labelPage = uicontrol('Style', 'text', 'Position', [700, 10, 200, 30], 'String', ['Page: ', num2str(currentPage), '/', num2str(totalPages)]);

    buttonMerge = uicontrol('Style', 'pushbutton', 'String', 'Merge', 'Position', [100, 10, 100, 30], 'Callback', @(src, event) mergeData());
    buttonDiscard = uicontrol('Style', 'pushbutton', 'String', 'Discard', 'Position', [200, 10, 100, 30], 'Callback', @(src, event) discardData());
    buttonNormalize = uicontrol('Style', 'pushbutton', 'String', 'Normalize', 'Position', [300, 10, 100, 30], 'Callback', @(src, event) normalizeC());
    buttonNext = uicontrol('Style', 'pushbutton', 'String', 'Next', 'Position', [400, 10, 100, 30], 'Callback', @(src, event) nextPage());
    buttonBack = uicontrol('Style', 'pushbutton', 'String', 'Back', 'Position', [500, 10, 100, 30], 'Callback', @(src, event) previousPage());
    buttonDone = uicontrol('Style', 'pushbutton', 'String', 'Done', 'Position', [600, 10, 100, 30], 'Callback', @(src, event) done());

    % Slider for video frame navigation
    sliderFrame = uicontrol('Style', 'slider', 'Min', 1, 'Max', numFrames, ...
        'Value', 1, 'Position', [50, 10, 300, 20], ...
        'Callback', @(src, event) updateVideo());

    checkboxes = gobjects(numItemsToDisplay, 1);

    updateDisplay();

    function mergeData()
        selectedIdx = find(arrayfun(@(x) isvalid(x) && isa(x, 'matlab.ui.control.UIControl') && x.Value, checkboxes));
        selectedZ = closestZ(selectedIdx);
        mergeID = min(selectedZ);
        for z = setdiff(selectedZ, mergeID)
            C(mergeID, :) = C(mergeID, :) + C(z, :);
            S(mergeID, :) = S(mergeID, :) + S(z, :);
            A(:,:,mergeID) = A(:,:,mergeID) + A(:,:,z);
            checkboxes(find(closestZ == z)).Enable = 'off';
            displayIDs(z) = mergeID;
            validZ(z) = false;
        end
        displayIDs(mergeID) = mergeID;
        updateDisplay();
    end

    function discardData()
        selectedIdx = find(arrayfun(@(x) isvalid(x) && isa(x, 'matlab.ui.control.UIControl') && x.Value, checkboxes));
        selectedZ = closestZ(selectedIdx);
        for z = selectedZ
            checkboxes(find(closestZ == z)).Enable = 'off';
            displayIDs(z) = -1;
            validZ(z) = false;
        end
        updateDisplay();
    end

    function normalizeC()
        minC = min(C, [], 2);
        maxC = max(C, [], 2);
        C = (C - minC) ./ (maxC - minC);
        updateDisplay();
    end

    function nextPage()
        currentZDisplay = [];
        currentPage = currentPage + 1;
        updateDisplay();
    end

    function previousPage()
        currentZDisplay = [];
        currentPage = currentPage - 1;
        updateDisplay();
    end

    function done()
        close(fig);
    end

    function updateDisplay()
        delete(checkboxes);
        for i = 1:numItemsToDisplay
            closestZ(i) = displayIDs((currentPage-1)*numItemsToDisplay + i);
            checkboxes(i) = uicontrol('Style', 'checkbox', 'Position', [500, 700 - 100*i, 20, 20]);
        end

        for i = 1:length(axC)
            if closestZ(i) > 0 && validZ(closestZ(i))
                plot(axC(i), C(closestZ(i), :));
                hold(axC(i), 'on');
                plot(axC(i), S(closestZ(i), :));
                hold(axC(i), 'off');
                title(axC(i), ['Component: ', num2str(closestZ(i))]);
            else
                cla(axC(i));
                title(axC(i), '');
            end
        end

        imagesc(axA, sum(A, 3));
        colormap(axA, 'gray');
        axis(axA, 'off');

        labelPage.String = ['Page: ', num2str(currentPage), '/', num2str(totalPages)];

        updateVideo();
    end

    function updateVideo()
        currentFrame = round(sliderFrame.Value);
        videoObj.CurrentTime = (currentFrame - 1) / videoObj.FrameRate;
        vidFrame = readFrame(videoObj);
        imagesc(axVideo, vidFrame);

        % Update the vertical line in signals
        for i = 1:length(axC)
            if isvalid(axC(i))
                yL = ylim(axC(i));
                hold(axC(i), 'on');
                plot(axC(i), [currentFrame, currentFrame], yL, 'r');
                hold(axC(i), 'off');
            end
        end
    end
end
