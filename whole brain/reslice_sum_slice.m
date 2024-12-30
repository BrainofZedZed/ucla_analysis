% MATLAB equivalent for processing specific slices from multiple TIFF files

% File paths
files = {
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ217\\deeptrace_analysis\\240510_ZZ217_488_10-57-10\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ218\\deeptrace_analysis\\240510_ZZ218_488_13-24-29\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ219\\deeptrace_analysis\\240510_ZZ219_488_15-31-43\\refined_model___weights001_nb8_st3_at15.tiff";
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ254\\deeptrace_analysis\\240829_ZZ254_08x_488_10-45-30\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff"
};

% Array of slice numbers to process
sliceNumbers = [351, 600, 880, 900];

% Output directory
outputDir = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\batch\\all\\images\\";

% Process each slice number
for s = 1:length(sliceNumbers)
    currentSlice = sliceNumbers(s);
    
    % Initialize the sum matrix to empty
    sumMatrix = [];
    
    for f = 1:length(files)
        % Read the 3D image stack
        info = imfinfo(files{f});
        numSlices = length(info);
        image3D = zeros(info(1).Height, info(1).Width, numSlices, 'uint16');
        for z = 1:numSlices
            image3D(:, :, z) = imread(files{f}, z);
        end
        
        % Reslice the 3D image to switch from horizontal to coronal view
        imageCoronal = permute(image3D, [3, 2, 1]);
        
        % Ensure the requested slice exists in the resliced data
        if currentSlice > size(imageCoronal, 3)
            error("Slice %d exceeds the number of slices in file %s", currentSlice, files{f});
        end
        
        % Read the specific slice from the resliced data
        currentImage = imageCoronal(:, :, currentSlice);
        currentImage = squeeze(currentImage); % Remove singleton dimension
        
        % Add to the sum matrix
        if isempty(sumMatrix)
            sumMatrix = double(currentImage);
        else
            sumMatrix = sumMatrix + double(currentImage);
        end
    end
    
    % Convert back to uint16 (or another appropriate format based on your data)
    sumMatrix = uint16(sumMatrix);
    
   % Normalize sumMatrix for visualization
    minVal = double(min(sumMatrix(:))); 
    maxVal = double(max(sumMatrix(:))); 
    maxVal = 38; %hard code from across groups
    normalizedMatrix = (double(sumMatrix) - minVal) / (maxVal - minVal); 

   % We want white background where normalizedMatrix=0: [1,1,1]
    % and dark red at normalizedMatrix=1: [0.5,0,0]
    % Interpolate linearly:
    % For R: at 0 -> 1, at 1 -> 0.5
    % For G: at 0 -> 1, at 1 -> 0
    % For B: at 0 -> 1, at 1 -> 0
    redChannel   = 1 - 0.5 * normalizedMatrix;
    greenChannel = 1 - 1.0 * normalizedMatrix;
    blueChannel  = 1 - 1.0 * normalizedMatrix;
    
    colorMatrix = cat(3, redChannel, greenChannel, blueChannel);
    % Display the color image
    figure;
    imshow(colorMatrix);
    title(sprintf('Summed Matrix (Red Signal on White) for Slice %d', currentSlice));
    axis on; % Show axes for reference

   
% Save the figure as a .fig file
outputFigName = fullfile(outputDir, sprintf('summed_matrix_slice%d_color.fig', currentSlice));
savefig(outputFigName);

% Save the normalized matrix as a .mat file
outputMatName = fullfile(outputDir, sprintf('summed_matrix_slice%d_normalized.mat', currentSlice));
save(outputMatName, 'normalizedMatrix');

fprintf('Saved .fig and normalizedMatrix .mat for slice %d\n', currentSlice);
end
