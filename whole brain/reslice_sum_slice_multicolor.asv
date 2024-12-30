% MATLAB equivalent for processing specific slices from multiple TIFF files

% User-selected color family: choose from 'red', 'orange', or 'blue'
chosenColor = 'red';

% Define max colors for each file in the chosen color family:
switch chosenColor
    case 'red'
        fileColors = [
            0, 0.0, 0.0;  % File 1
            0, 0.0, 0.0;  % File 2
            0, 0.0, 0.0;  % File 3
            0, 0.0, 0.0]; % File 4
    case 'orange'
        fileColors = [
            0.9, 0.4, 0.0; 
            0.8, 0.3, 0.0; 
            0.7, 0.2, 0.0; 
            0.6, 0.1, 0.0];
    case 'blue'
        fileColors = [
            0.0, 0.0, 0.8; 
            0.0, 0.0, 0.6; 
            0.0, 0.0, 0.4; 
            0.0, 0.0, 0.2];
    otherwise
        error('Unknown color family selected.');
end

% File paths for D1
% files = {
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ217\\deeptrace_analysis\\240510_ZZ217_488_10-57-10\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ218\\deeptrace_analysis\\240510_ZZ218_488_13-24-29\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ219\\deeptrace_analysis\\240510_ZZ219_488_15-31-43\\refined_model___weights001_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ254\\deeptrace_analysis\\240829_ZZ254_08x_488_10-45-30\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff"
% };

%file path for all
% files = {
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ216B\\deeptrace_analysis\\240510_ZZ216B_488_08-50-04\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ215\\deeptrace_analysis\\240509_ZZ215_488_15-10-53\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ293\\deeptrace_analysis\\241111_ZZ293_08x_488_09-48-51\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ294\\deeptrace_analysis\\241111_ZZ294_08x_488_11-38-16\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
% };

% % file paths for d28
files = {
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ212\deeptrace_analysis\240509_ZZ212_488_11-07-21\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ213\deeptrace_analysis\240509_ZZ213_488_13-10-03\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ252\deeptrace_analysis\240829_ZZ252_08x_488_12-17-11\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ253\deeptrace_analysis\240829_ZZ253_08x_488_13-48-27\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
};

% Slice numbers to process
sliceNumbers = [351, 600, 880, 900];

% Output directory
outputDir = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\batch\\d28\\images\\";

for s = 1:length(sliceNumbers)
    currentSlice = sliceNumbers(s);
    
    finalR = [];
    finalG = [];
    finalB = [];
    
    for f = 1:length(files)
        info = imfinfo(files{f});
        numSlices = length(info);
        image3D = zeros(info(1).Height, info(1).Width, numSlices, 'uint16');
        for z = 1:numSlices
            image3D(:, :, z) = imread(files{f}, z);
        end
        
        imageCoronal = permute(image3D, [3, 2, 1]);
        
        if currentSlice > size(imageCoronal, 3)
            error("Slice %d exceeds the number of slices in file %s", currentSlice, files{f});
        end
        
        currentImage = squeeze(imageCoronal(:, :, currentSlice));
        
        % Determine dimensions if not done yet
        if isempty(finalR)
            [H, W] = size(currentImage);
            finalR = ones(H, W);
            finalG = ones(H, W);
            finalB = ones(H, W);
        end
        
        minVal = double(min(currentImage(:)));
        maxVal = double(max(currentImage(:)));
        chosenMaxVal = 38; % hard-coded
        normalizedMatrix = (double(currentImage) - minVal) / (chosenMaxVal - minVal);
        normalizedMatrix(normalizedMatrix < 0) = 0;
        
        baseColor = fileColors(f, :);
       
        % Before mapping normalizedMatrix to colors, define a startColor darker than white:
        startColor = [1, 1, 1]; % slightly darker than white

        % Then adjust the color mapping lines:
        R = startColor(1) - normalizedMatrix * (startColor(1) - baseColor(1));
        G = startColor(2) - normalizedMatrix * (startColor(2) - baseColor(2));
        B = startColor(3) - normalizedMatrix * (startColor(3) - baseColor(3));

        % Combine using min to overlay darker colors where signals overlap
        finalR = min(finalR, R);
        finalG = min(finalG, G);
        finalB = min(finalB, B);
    end
    
    colorMatrix = cat(3, finalR, finalG, finalB);
    
    figure;
    imshow(colorMatrix);
    title(sprintf('Overlay (Slice %d, %s)', currentSlice, chosenColor));
    axis on;
    
    outputFigName = fullfile(outputDir, sprintf('overlay_slice%d_%s.fig', currentSlice, chosenColor));
    savefig(outputFigName);
    
    outputMatName = fullfile(outputDir, sprintf('overlay_slice%d_%s.mat', currentSlice, chosenColor));
    save(outputMatName, 'colorMatrix');
    
    fprintf('Saved overlay figure and .mat for slice %d\n', currentSlice);
end
