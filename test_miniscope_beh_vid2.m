function synchronizeVideoCalciumGUI()
    % Step 1: Load Video and Calcium Data
    [videoFileName, videoPath] = uigetfile({'*.mp4';'*.avi';'*.mov'}, 'Select Video File');
    if isequal(videoFileName,0)
       disp('User selected Cancel for video file.');
       return;
    else
       videoFile = fullfile(videoPath, videoFileName);
    end

    [dataFileName, dataPath] = uigetfile({'*.mat'}, 'Select Calcium Data File');
    if isequal(dataFileName,0)
       disp('User selected Cancel for calcium data.');
       return;
    else
       calciumDataFile = fullfile(dataPath, dataFileName);
       load(calciumDataFile); % Assumes calcium data is saved in a variable within the .mat file
    end
    
    videoObj = VideoReader(videoFile);
    videoFrames = videoObj.NumFrames;
    calciumLength = size(calciumData, 2);

    % Normalize calcium data regardless of user choice on alignment
    calciumData = (calciumData - min(calciumData, [], 2)) ./ (max(calciumData, [], 2) - min(calciumData, [], 2));
    
    % Step 2: Optionally Align Calcium Data
    choice = questdlg('Do you want to align calcium and video data based on start and end times?', ...
        'Align Data', ...
        'Yes','No','Yes');
    switch choice
        case 'Yes'
            % Stretch calcium data if lengths differ
            if calciumLength ~= videoFrames
                newX = linspace(1, calciumLength, videoFrames);
                for i = 1:size(calciumData, 1)
                    calciumData(i, :) = interp1(1:calciumLength, calciumData(i, :), newX, 'linear');
                end
            end
        case 'No'
            disp('Skipping alignment.');
    end

    % Step 3: Create GUI
    hFig = figure('Name', 'Calcium and Video Synchronization', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    videoAxes = axes('Units', 'pixels', 'Position', [50, 100, 560, 700]);
    calciumAxes = axes('Units', 'pixels', 'Position', [650, 100, 500, 700]);
    
    totalFrames = videoObj.NumFrames;

    playBtn = uicontrol('Style', 'pushbutton', 'String', 'Play', 'Position', [700, 500, 50, 25], 'Callback', @playVideo);
    pauseBtn = uicontrol('Style', 'pushbutton', 'String', 'Pause', 'Position', [760, 500, 50, 25], 'Callback', @pauseVideo);
    frameSlider = uicontrol('Style', 'slider', 'Min', 1, 'Max', totalFrames, 'Value', 1, 'Position', [50, 320, 640, 20], 'Callback', @scrubVideo);
    frameNumberText = uicontrol('Style', 'text', 'String', 'Frame: 1', 'Position', [700, 470, 100, 25]);

    % Initial plot of calcium data with a window size of 200 frames
    currentFrame = 1;  % Initialization of current frame
    windowSize = 200;  % Set the window size around the current frame
    updateCalciumPlot(currentFrame);  % Initial update of calcium plot
    
    videoTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 1 / videoObj.FrameRate, 'TimerFcn', @updateVideo);

    function playVideo(~, ~)
        if strcmp(videoTimer.Running, 'off')
            start(videoTimer);
        end
    end

    function pauseVideo(~, ~)
        if strcmp(videoTimer.Running, 'on')
            stop(videoTimer);
        end
    end

    function scrubVideo(source, ~)
        frameNum = round(source.Value);
        updateFrameDisplay(frameNum);
    end

    function updateVideo(~, ~)
        frameNum = round(frameSlider.Value) + 1;
        if frameNum > totalFrames
            frameNum = 1; % Loop to the beginning
        end
        updateFrameDisplay(frameNum);
    end

% Update function for calcium data plot
    function updateCalciumPlot(frameNum)
        cla(calciumAxes); % Clear the axes for the new plot
        hold(calciumAxes, 'on'); % Hold on to plot multiple lines
    
        % Determine the range of frames to display around the current frame
        if frameNum > windowSize && (frameNum + windowSize) <= size(calciumData, 2)
            windowFrames = (frameNum-windowSize):(frameNum+windowSize);
        else
            windowFrames = max(1, frameNum-windowSize):min(size(calciumData, 2), frameNum+windowSize);
        end
    
        % Plot each neuron's calcium trace in its own horizontal space
        for neuronIndex = 1:size(calciumData, 1)
            % Offset each neuron's data by its index
            yOffset = neuronIndex - 1;
            plot(calciumAxes, windowFrames, calciumData(neuronIndex, windowFrames) + yOffset, 'k');
        end
    
        % Add a dashed line at the current frame
        plot(calciumAxes, [frameNum, frameNum], get(calciumAxes, 'YLim'), 'r--');
    
        hold(calciumAxes, 'off'); % Release the hold to finish plotting
        set(calciumAxes, 'YTick', []); % Hide Y-axis ticks
        xlim(calciumAxes, [windowFrames(1), windowFrames(end)]); % Set X-axis limits to the window
        xlabel(calciumAxes, 'Frames');
        title(calciumAxes, 'Calcium Data');
    end


    function updateFrameDisplay(frameNum)
        frameSlider.Value = frameNum;
        set(frameNumberText, 'String', ['Frame: ' num2str(frameNum)]);
        videoFrame = read(videoObj, frameNum);
        imshow(videoFrame, 'Parent', videoAxes);

        % Update calcium plot
        updateCalciumPlot(frameNum);
    end
end
