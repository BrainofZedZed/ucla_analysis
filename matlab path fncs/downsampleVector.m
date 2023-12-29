function downsampledVector = downsampleVector(originalVector, startingSize, endingSize)
    % Calculate the downsampling factor
    downsamplingFactor = startingSize / endingSize;

    % Create a time vector for the original data
    timeOriginal = 1:numel(originalVector);

    % Create a time vector for the downsampled data
    timeDownsampled = 1:downsamplingFactor:numel(originalVector);

    % Interpolate to obtain the downsampled vector
    downsampledVector = interp1(timeOriginal, originalVector, timeDownsampled);
end
