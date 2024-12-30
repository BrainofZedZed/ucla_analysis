%% File paths
files = {
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ217\\deeptrace_analysis\\240510_ZZ217_488_10-57-10\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ218\\deeptrace_analysis\\240510_ZZ218_488_13-24-29\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ219\\deeptrace_analysis\\240510_ZZ219_488_15-31-43\\refined_model___weights001_nb8_st3_at15.tiff",
    "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ254\\deeptrace_analysis\\240829_ZZ254_08x_488_10-45-30\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff"
};

%% Initialize colors
braincolors = zeros(4, 3);
braincolors(1, :) = [255, 228, 79]; % ZZ217
braincolors(2, :) = [235, 193, 87]; % ZZ218
braincolors(3, :) = [229, 148, 67]; % ZZ219
braincolors(4, :) = [250, 120, 68]; % ZZ254

%% Overlay skeletonized whole-brain images
for idx = 1:length(files)
    file = files{idx};
    s = imfinfo(file); % 's' is a struct array where each element corresponds to one page in the TIFF file
    height = s(1).Height;
    width = s(1).Width;
    num_pages = numel(s);

    % Process slices one at a time to reduce memory usage
    for i = 1:num_pages
        % Read current slice
        test_slice = imread(file, i);

        % Initialize mask for the current slice
        mask_slice = uint8(255 * ones(height, width, 3));

        % Process pixel values
        for k = 1:width
            for j = 1:height
                for h = 1:15
                    if test_slice(j, k) == 17 * h
                        mask_slice(j, k, 1) = max(0, 255 - ((255 - mask_slice(j, k, 1)) + h * ((255 - braincolors(idx, 1)) / 20)));
                        mask_slice(j, k, 2) = max(0, 255 - ((255 - mask_slice(j, k, 2)) + h * ((255 - braincolors(idx, 2)) / 20)));
                        mask_slice(j, k, 3) = max(0, 255 - ((255 - mask_slice(j, k, 3)) + h * ((255 - braincolors(idx, 3)) / 20)));
                    end
                end
            end
        end

        % Save the processed slice immediately
        output_file = sprintf('output_mask_%d_page_%d.tiff', idx, i);
        options.compress = 'lzw';
        options.color = 1;
        options.overwrite = true;
        saveastiff(uint8(mask_slice), output_file, options);
        fprintf('Saved processed slice: %s\n', output_file);
    end
end
