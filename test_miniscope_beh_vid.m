function synchronize_video_and_data
    % Step 1: Prompt the User for Video and Data Files
    [videoFileName, videoPath] = uigetfile({'*.mp4';'*.avi'}, 'Select Video File');
    [calciumFileName, calciumPath] = uigetfile({'*.mat'}, 'Select Calcium Data File');

    % Load the video and calcium data
    videoObject = VideoReader(fullfile(videoPath, videoFileName));
    calciumStruct = load(fullfile(calciumPath, calciumFileName));
    calciumFields = fields(calciumStruct);
    calciumData = calciumStruct.(calciumFields{1});

    % Step 2: Ask About Data Alignment
    choice = questdlg('Do you want to align calcium and video data based on start and end times?', ...
        'Align Data', 'Yes', 'No', 'Yes');

    if strcmp(choice, 'Yes')
        % Step 3: Data Stretching and Normalization
        videoLength = videoObject.NumFrames;
        calciumLength = size(calciumData, 2);

        % Stretch calcium data if lengths do not match
        if videoLength ~= calciumLength
            x = linspace(1, calciumLength, videoLength);
            stretchedCalciumData = interp1(1:calciumLength, calciumData', x)';
            calciumData = stretchedCalciumData;
        end

        % Normalize calcium data
        for i = 1:size(calciumData, 1)
            calciumData(i, :) = (calciumData(i, :) - min(calciumData(i, :))) / ...
                                (max(calciumData(i, :)) - min(calciumData(i, :)));
        end
    end

     % Step 4: Display and Control Interface
    f = figure('Name', 'Video and Calcium Data Synchronization', 'NumberTitle', 'off');

   % Create video axes on the left
    videoAxes = axes('Parent', f, 'Position', [.05 .2 .45 .7]);
    
    % Create calcium axes on the right
    calciumAxes = axes('Parent', f, 'Position', [.55 .2 .4 .7]);
    
    % Initialize UI controls for play and pause below the video
    playButton = uicontrol('Style', 'pushbutton', 'String', 'Play', ...
        'Position', [50, 50, 50, 20], 'Callback', @playCallback);
    pauseButton = uicontrol('Style', 'pushbutton', 'String', 'Pause', ...
        'Position', [110, 50, 50, 20], 'Callback', @pauseCallback);

    % Initialize the shared variables and store them
    setappdata(f, 'isPlaying', false);
    setappdata(f, 'currentFrame', 1); % Initial frame

    % Define the timer for playback
    timerObj = timer('TimerFcn', @updateDisplay, 'Period', 1/videoObject.FrameRate, ...
                     'ExecutionMode', 'fixedSpacing', 'BusyMode', 'drop');
    setappdata(f, 'timerObj', timerObj);
    
    % Scroll bar for video navigation
    scrollBar = uicontrol('Style', 'slider', 'Min', 1, 'Max', videoObject.NumFrames, ...
        'Value', 1, 'Position', [50, 20, 300, 20], 'Callback', @scrollVideo);

    % Text for frame number
    frameNumberText = uicontrol('Style', 'text', 'String', 'Frame: 1', ...
        'Position', [360, 20, 100, 20]);

   % The playCallback function needs to start the timer and update 'isPlaying'
    function playCallback(~, ~)
        f = gcf;
        isPlaying = getappdata(f, 'isPlaying');
        timerObj = getappdata(f, 'timerObj');
        if ~isPlaying
            start(timerObj);
            setappdata(f, 'isPlaying', true);
        end
    end


    function pauseCallback(src, ~)
        % Retrieve the shared variables
        f = ancestor(src, 'figure');
        isPlaying = getappdata(f, 'isPlaying');
        timerObj = getappdata(f, 'timerObj');

        if isPlaying
            stop(timerObj);
            setappdata(f, 'isPlaying', false);
        end
    end

    % The updateDisplay function needs to be modified to interact with the slider and frame text
    function updateDisplay(~, ~)
        f = gcf;
        videoObject = getappdata(f, 'videoObject');
        currentFrame = getappdata(f, 'currentFrame');
        if hasFrame(videoObject)
            videoObject.CurrentTime = (currentFrame-1) / videoObject.FrameRate;
            frame = readFrame(videoObject);
            imshow(frame, 'Parent', videoAxes);
            set(frameNumberText, 'String', sprintf('Frame: %d', currentFrame));
            set(scrollBar, 'Value', currentFrame);
            updateCalciumDisplay(currentFrame);
            currentFrame = currentFrame + 1;
            if currentFrame > videoObject.NumFrames
                currentFrame = 1;
                stop(timerObj);
                setappdata(f, 'isPlaying', false);
            end
            setappdata(f, 'currentFrame', currentFrame);
        end
    end

 function scrollVideo(src, ~)
        % Retrieve the video object
        videoObject = getappdata(gcf, 'videoObject');
        
        % Get the new frame number
        frameNumber = round(get(src, 'Value'));
        set(frameNumberText, 'String', sprintf('Frame: %d', frameNumber));
        
        % Read and display the new frame
        videoObject.CurrentTime = (frameNumber-1) / videoObject.FrameRate;
        if hasFrame(videoObject)
            frame = readFrame(videoObject);
            imshow(frame, 'Parent', videoAxes);
        end
        
        % Update the calcium data display
        updateCalciumDisplay(frameNumber);
    end

    function updateCalciumDisplay(frameNumber)
        % Retrieve the calcium data
        calciumData = getappdata(gcf, 'calciumData');
        
        % Clear the calcium axes
        cla(calciumAxes);
        
        % Display each trace in its own row
        hold on;
        for i = 1:size(calciumData, 1)
            plot(calciumAxes, calciumData(i, :) + i, 'k');
        end
        hold off;
        
        % Set the axes limits and appearance
        xlim(calciumAxes, [max(1, frameNumber - 200), min(size(calciumData, 2), frameNumber + 200)]);
        ylim(calciumAxes, [0, size(calciumData, 1) + 1]);
        set(calciumAxes, 'YTick', []);
        xlabel(calciumAxes, 'Time (frames)');
        
        % Draw a line indicating the current frame
        line(calciumAxes, [frameNumber, frameNumber], get(calciumAxes, 'YLim'), ...
             'Color', 'r', 'LineWidth', 2);
    end

    % Start the initial display
    updateCalciumDisplay(1);

end
