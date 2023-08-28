function CNMFViewer(A, C, S)
% homebrew version of CNMFViewer from Minian
% 2023 08 01 ZZ
    [Nx, Mx, Z] = size(A);
    [Zx, ~] = size(C);
    numItemsToDisplay = 5;
    currentPage = 1;
    closestZ = [];
    displayIDs = 1:Z;
    alreadyDisplayed = false(Z, 1);
    currentZDisplay = [];


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

    fig = figure('Name', 'CNMFViewer', 'Position', [100, 100, 1200, 800]);

    axC = gobjects(numItemsToDisplay, 1);
    for i = 1:numItemsToDisplay
        axC(i) = axes(fig, 'Position', [0.6, 0.8 - 0.15*i, 0.3, 0.13]);
    end

    axA = axes(fig, 'Position', [0.1, 0.5, 0.3, 0.4]);
    axBatchA = axes(fig, 'Position', [0.1, 0.05, 0.3, 0.4]);

    % Page label
    labelPage = uicontrol('Style', 'text', 'Position', [700, 10, 200, 30], 'String', ['Page: ', num2str(currentPage), '/', num2str(totalPages)]);

    buttonMerge = uicontrol('Style', 'pushbutton', 'String', 'Merge', 'Position', [100, 10, 100, 30], 'Callback', @(src, event) mergeData());
    buttonDiscard = uicontrol('Style', 'pushbutton', 'String', 'Discard', 'Position', [200, 10, 100, 30], 'Callback', @(src, event) discardData());
    buttonNormalize = uicontrol('Style', 'pushbutton', 'String', 'Normalize', 'Position', [300, 10, 100, 30], 'Callback', @(src, event) normalizeC());
    buttonNext = uicontrol('Style', 'pushbutton', 'String', 'Next', 'Position', [400, 10, 100, 30], 'Callback', @(src, event) nextPage());
    buttonBack = uicontrol('Style', 'pushbutton', 'String', 'Back', 'Position', [500, 10, 100, 30], 'Callback', @(src, event) previousPage());
    buttonDone = uicontrol('Style', 'pushbutton', 'String', 'Done', 'Position', [600, 10, 100, 30], 'Callback', @(src, event) done());

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
            displayIDs(z) = mergeID; % Display the same ID for the merged item
            validZ(z) = false; % Mark the merged component as invalid
        end
        displayIDs(mergeID) = mergeID; % Not necessary, but added for clarity
        updateDisplay();
    end




    function discardData()
        selectedIdx = find(arrayfun(@(x) isvalid(x) && isa(x, 'matlab.ui.control.UIControl') && x.Value, checkboxes));
        selectedZ = closestZ(selectedIdx);
        for z = selectedZ
            checkboxes(find(closestZ == z)).Enable = 'off';
            displayIDs(z) = -1; % Display ID as -1 for discarded items
            validZ(z) = false; % Mark the discarded component as invalid
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
        currentPage = max(1, currentPage - 1);
        updateDisplay();
    end

   function done()
        finalC = C(validZ, :);
        finalS = S(validZ, :);
        finalA = A(:,:,validZ);
        save('cleaned_cnmf_data.mat', 'finalC', 'finalS', 'finalA');
        close(fig);
    end

    function updateDisplay()
        delete(checkboxes);
        checkboxes = gobjects(numItemsToDisplay, 1);
        
        idxZ = (currentPage - 1) * numItemsToDisplay + 1 : currentPage * numItemsToDisplay;
        idxZ = idxZ(idxZ <= Z); % Ensure we don't exceed the bounds
        
        % Check if currentZDisplay is empty
        if isempty(currentZDisplay)
            % Adjust distances based on the actual items in idxZ
            sortedDistances = sort(distances(idxZ, :), 2, 'ascend');
        
            % Use validZ to exclude discarded or merged items
            closestIdx = ismember(distances(idxZ, :), sortedDistances(:, 2:numItemsToDisplay+1)) & ~alreadyDisplayed' & validZ';
        
            closestZ = find(any(closestIdx, 1));
            
            % Populate currentZDisplay
            currentZDisplay = closestZ;
        else
            closestZ = currentZDisplay;
        end

        numActualDisplay = min(length(idxZ), numel(closestZ)); % Determine how many items we can actually display
        
        for i = 1:numActualDisplay
            zIdx = closestZ(i);
            if zIdx <= Z 
                plot(axC(i), C(zIdx, :), 'k');
                title(axC(i), ['C Signal for N = ', num2str(displayIDs(zIdx))]);
                checkboxes(i) = uicontrol('Style', 'checkbox', 'Position', [750, 770 - 130 * i, 15, 15]);
                
                if ~validZ(zIdx)
                    checkboxes(i).Value = 1;  % Checkbox is checked
                    checkboxes(i).Enable = 'off';  % Checkbox is disabled
                end
        
                alreadyDisplayed(zIdx) = true;
            end
        end

        imagesc(axA, sum(A(:,:,closestZ(1:numActualDisplay)), 3)); % Make sure not to exceed bounds here too
        colormap(axA, 'parula');
        title(axA, 'Displayed footprints');
        
        for i = 1:numActualDisplay
            zIdx = closestZ(i);
            if zIdx <= Z % Ensure we don't exceed the bounds
                [row, col] = find(A(:,:,zIdx) > 0);
                if ~isempty(row) && ~isempty(col)
                    text(axA, mean(col), mean(row), num2str(displayIDs(zIdx)), 'Color', 'w'); % Use displayIDs instead of zIdx
                end
            end
        end

        
        imagesc(axBatchA, sum(A, 3));
        colormap(axBatchA, 'parula');
        title(axBatchA, 'All footprints');
        
        % Update page label
        labelPage.String = ['Page: ', num2str(currentPage), '/', num2str(totalPages)];
    end

end
