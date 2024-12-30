% This code calculates density-based dotograms from multiple slices and files with a unified style.
% It first optionally uses a manually defined global maximum density, or if not defined, determines 
% a global maximum density from all slices, then normalizes each slice accordingly.

% Manually define globalMaxDensity here if desired:
% Set to [] if you want the code to compute it automatically.
%globalMaxDensity = 6.7; % empirical, from PLTeA all

% User-selected color family for the summed overlay image (not directly used in the dotogram):
%chosenColor = [0.8 0.33 0];


% File paths for D1
files = {
   "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ217\\deeptrace_analysis\\240510_ZZ217_488_10-57-10\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
   "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ218\\deeptrace_analysis\\240510_ZZ218_488_13-24-29\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
   "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ219\\deeptrace_analysis\\240510_ZZ219_488_15-31-43\\refined_model___weights001_nb8_st3_at15.tiff";
   "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ254\\deeptrace_analysis\\240829_ZZ254_08x_488_10-45-30\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff"
};

% % weights for D1
weights = [1.6, 5.7, 4.6, 6.5];

% % file path for all
% files = {
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ216B\\deeptrace_analysis\\240510_ZZ216B_488_08-50-04\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ215\\deeptrace_analysis\\240509_ZZ215_488_15-10-53\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ293\\deeptrace_analysis\\241111_ZZ293_08x_488_09-48-51\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ294\\deeptrace_analysis\\241111_ZZ294_08x_488_11-38-16\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
% };
% 
% % weights for all
% weights = [20.7, 20.5, 5.7, 5.5];

% % file paths for d28
% files = {
%     "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ212\deeptrace_analysis\240509_ZZ212_488_11-07-21\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%     "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ213\deeptrace_analysis\240509_ZZ213_488_13-10-03\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%     "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ252\deeptrace_analysis\240829_ZZ252_08x_488_12-17-11\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
%     "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ253\deeptrace_analysis\240829_ZZ253_08x_488_13-48-27\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
% };

% weights for d28
%weights = [6.4, 2, 2.7, 1.3];

sliceNumbers = [351, 600, 880, 900];

outputDir = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\batch\\d1\\images\\";

for s = 1:length(sliceNumbers)
    currentSlice = sliceNumbers(s);
    
    % Initialize sumMatrix
    sumMatrix = [];
    
    % ---------------------------
    % PER-FILE NORMALIZATION
    % ---------------------------
    for f = 1:length(files)
        info = imfinfo(files{f});
        numSlices = length(info);
        image3D = zeros(info(1).Height, info(1).Width, numSlices, 'uint16');
        for z = 1:numSlices
            image3D(:, :, z) = imread(files{f}, z);
        end
        
        % Permute to coronal
        imageCoronal = permute(image3D, [3, 2, 1]);
        
        if currentSlice > size(imageCoronal, 3)
            error("Slice %d exceeds the number of slices in file %s", currentSlice, files{f});
        end
        
        currentImage = double(squeeze(imageCoronal(:, :, currentSlice)));
        
        % Divide by the weight for this file
        currentImage = currentImage / weights(f);
        
        % Accumulate in sumMatrix
        if isempty(sumMatrix)
            sumMatrix = currentImage;
        else
            sumMatrix = sumMatrix + currentImage;
        end
    end
    
    % Convert to uint16 if desired
    sumMatrix = uint16(sumMatrix);
    
    % ---------------------------
    % DOTOGRAM (Density) SECTION
    % ---------------------------
    [image_height, image_width] = size(sumMatrix);
    rm = rem(image_height, 10);
    rn = rem(image_width, 10);

    density = zeros((image_height - rm)/10, (image_width - rn)/10);
    for m = 1:(image_height - rm)/10
        for n = 1:(image_width - rn)/10
            voxel = sumMatrix(1+rm+(m-1)*10 : rm+m*10, 1+rn+(n-1)*10 : rn+n*10);
            density(m, n) = mean(voxel(:));
        end
    end
    
    % Normalize density (example, local maximum or global reference)
    localMaxDensity = max(density(:));
    normalized_density = density / localMaxDensity;
    
    scale_factor = 1/7;  % Adjust as desired
    normalized_density = normalized_density * scale_factor;
    
    fig = figure;
    for m = 1:size(density, 1)
        for n = 1:size(density, 2)
            r = sqrt(normalized_density(m, n)) * 0.8;
            rectangle('Position', [n, size(density,1)-m, 2*r, 2*r], ...
                      'Curvature', [1,1], ...
                      'FaceColor', [0, normalized_density(m, n), normalized_density(m, n)], ...
                      'EdgeColor', 'none');
        end
    end
    
    axis equal;
    title(sprintf('Density Map (Slice %d)', currentSlice));
    xlabel('Voxel Columns');
    ylabel('Voxel Rows');
    
    output_fig_name = fullfile(outputDir, sprintf('normed_dotogram_slice%d.fig', currentSlice));
    savefig(fig, output_fig_name);
    disp(['Figure saved as: ', output_fig_name]);
end