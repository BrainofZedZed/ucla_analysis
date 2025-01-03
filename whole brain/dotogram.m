% Process a single 2D image file to calculate density based on average brightness.

% Input file
%351, 600, 880, 900
input_file = "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\batch\all\images\summed_matrix_slice900.tif";

% Read the image
image = imread(input_file);

% Determine image dimensions
[image_height, image_width] = size(image);

% Compute dimensions for 100 µm voxels
rm = rem(image_height, 10); % Remainder for rows
rn = rem(image_width, 10);  % Remainder for columns

% Initialize density matrix
density = zeros((image_height - rm) / 10, (image_width - rn) / 10);

% Calculate density for each voxel (average brightness)
for m = 1:(image_height - rm) / 10
    for n = 1:(image_width - rn) / 10
        % Extract the voxel
        voxel = image(1 + rm + (m - 1) * 10 : rm + m * 10, ...
                      1 + rn + (n - 1) * 10 : rn + n * 10);
        % Calculate the average brightness value
        density(m, n) = mean(voxel(:));
    end
end

% Normalize density for visualization
max_density = max(density(:));
normalized_density = density / max_density;
normalized_density = normalized_density / 7; % quarter max px value (arbitrary)

% Visualize the density map
figure;
for m = 1:size(density, 1)
    for n = 1:size(density, 2)
        % Determine radius proportional to density
        r = sqrt(normalized_density(m, n)) * 0.8; % Adjust scale factor as needed
        % Plot a rectangle (circle approximation) at the corresponding location
        rectangle('Position', [n, size(density, 1) - m, 2 * r, 2 * r], ...
                  'Curvature', [1, 1], ...
                  'FaceColor', [0, normalized_density(m, n), normalized_density(m, n)], ...
                  'EdgeColor', 'none');
    end
end
% all 'FaceColor 0
% d28 'FaceColor', [0.5, normalized_density(m, n), normalized_density(m, n)], ...
% d1  'FaceColor', [1, normalized_density(m, n), normalized_density(m, n)], ...

axis equal;
title('Density Map (Average Brightness)');
xlabel('Voxel Columns');
ylabel('Voxel Rows');

% Extract folder and file name information
[input_folder, input_name, ~] = fileparts(input_file);

% Extract numeric suffix from input file name
number_match = regexp(input_name, '\d+$', 'match'); % Extract the numeric suffix
if ~isempty(number_match)
    number_suffix = number_match{1};
else
    error('No numeric suffix found in the input file name.');
end

% Generate output file name
output_fig_name = fullfile(input_folder, sprintf('dotogram_%s.fig', number_suffix));

% Save the visualization as a MATLAB .fig file
savefig(gcf, output_fig_name);

disp(['Figure saved as: ', output_fig_name]);
