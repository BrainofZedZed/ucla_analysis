% Define inputs
filePaths = {
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ216B\deeptrace_analysis\240510_ZZ216B_488_08-50-04\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ215\deeptrace_analysis\240509_ZZ215_488_15-10-53\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ293\deeptrace_analysis\241111_ZZ293_08x_488_09-48-51\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ294\deeptrace_analysis\241111_ZZ294_08x_488_11-38-16\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
};
sliceNumber = 880; % Replace with your slice number
outputPath = "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\batch\all\image making";

% Run the processing function
process_tiff_files(filePaths, sliceNumber, outputPath);


%% FXN %%
function process_tiff_files(filePaths, sliceNumber, outputPath)
    % Initialize an empty cell array to store slice pixel values from all files
    slices = {};

    for i = 1:length(filePaths)
        % Open the TIFF file
        tiffFile = filePaths{i};
        imgStack = loadtiff(tiffFile);

        % Reslice the stack with default parameters (transpose for MATLAB convention)
        reslicedStack = reslice_stack(imgStack);

        % Check if the slice number is within bounds
        if sliceNumber < 1 || sliceNumber > size(reslicedStack, 3)
            error('Slice number %d is out of range for file: %s', sliceNumber, tiffFile);
        end

        % Extract the desired slice
        sliceData = reslicedStack(:, :, sliceNumber);

        % Store the slice data in the cell array
        slices{i} = sliceData;
    end

    % Sum the matrices
    summedMatrix = sum(cat(3, slices{:}), 3);

    % Save the summed matrix as a TIFF file
    outputFile = fullfile(outputPath, 'summed_matrix.tif');
    saveastiff(summedMatrix, outputFile);

    % Display the summed matrix
    disp('Summed matrix:');
    disp(summedMatrix);
    fprintf('Saved summed matrix to: %s\n', outputFile);
end

function reslicedStack = reslice_stack(stack)
    % Placeholder for reslicing functionality
    % For simplicity, this function transposes the stack along the third dimension
    reslicedStack = permute(stack, [2, 1, 3]);
end