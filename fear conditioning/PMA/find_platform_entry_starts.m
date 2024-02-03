% Main script execution
% Uncomment and modify the following line according to your data loading method
% load('your_data_file.mat'); % Replace 'your_data_file.mat' with your data file name

% Calculate the start indices and entry indices
[platformEntryStartIndices, platformEntryIndices] = findPlatformEntries(Tracking, Params, Behavior, Metrics);

% Display the results
disp('Start indices of platform entries:');
disp(platformEntryStartIndices);
disp('Platform entry indices:');
disp(platformEntryIndices);

function [startIndices, entryIndices] = findPlatformEntries(Tracking, Params, Behavior, Metrics)
    midBackPositions = Tracking.Smooth.MidBack;
    inROIvector = Behavior.Spatial.platform.inROIvector;
    speeds = Metrics.Movement.Data;
    roi = Params.roi{1};

    startIndices = [];
    entryIndices = [];

    for i = 2:length(inROIvector)
        if inROIvector(i) == 1 && inROIvector(i-1) == 0
            entryIndex = i;
            startIndex = findStartIndex(midBackPositions, speeds, i, roi);

            if startIndex > 0
                startIndices(end+1) = startIndex;
                entryIndices(end+1) = entryIndex;
            end
        end
    end
end

function startIndex = findStartIndex(positions, speeds, entryIndex, roi)
    for i = entryIndex-1:-1:2
        if speeds(i) < 0.4|| ~isMovingStraight(positions, i, roi)
            startIndex = i + 1;
            return;
        end
    end
    startIndex = -1; % Indicates no valid start index found
end



function isStraight = isMovingStraight(positions, index, roi)
    angleThreshold = 45;

    if index < 3 || index > size(positions, 2)
        isStraight = false;
        return;
    end

    roiCenter = mean(roi, 1);
    x1 = positions(1, index-2);
    y1 = positions(2, index-2);
    x2 = positions(1, index-1);
    y2 = positions(2, index-1);
    x3 = positions(1, index);
    y3 = positions(2, index);

    directionToROI = atan2d(roiCenter(2) - y3, roiCenter(1) - x3);
    direction1 = atan2d(y2 - y1, x2 - x1);
    direction2 = atan2d(y3 - y2, x3 - x2);

    isStraight = abs(direction1 - direction2) < angleThreshold && abs(directionToROI - direction2) < angleThreshold;
end
