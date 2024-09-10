plot_ind = 1; % true if plot cell index
rotate_90 = 1; % true if rotate 90 counterclockwise
blue = [0, 0.4470, 0.7410];
orange = [0.8500, 0.3250, 0.0980];
purple = [0.4940, 0.1840, 0.5560];

color = blue;
opacity = 0;
% Assuming finalA is already loaded
[M, N, Z] = size(finalA);

% Create a figure
figure;
hold on;

for z = 1:Z
    % Get the 2D footprint for the current neuron
    footprint = finalA(:, :, z);
    footprint = rot90(footprint);
    
    % Smooth the footprint to make it more circular and smooth the edges
    % Here, we'll use morphological opening but you might adjust depending on your data
    se = strel('disk', 2);
    smoothedFootprint = imopen(footprint, se);
    
    % Extract the contour of the smoothed footprint
    boundary = bwboundaries(smoothedFootprint, 8, 'noholes');
    
    if ~isempty(boundary)  % In case there is a valid boundary
        boundary = boundary{1};  % Take the first boundary (largest)
        
        % Convert boundary to polyshape
        p = polyshape(boundary(:,2), boundary(:,1));  % x and y are swapped in bwboundaries
        
        % Plot polyshape
        plot(p, 'FaceColor', color, 'FaceAlpha', opacity, 'EdgeColor', 'red', 'LineWidth', 1);
        
        % Print neuron index inside the shape
        % Find the centroid of the polyshape
        if plot_ind
            [centroid_x, centroid_y] = centroid(p);
            text(centroid_x, centroid_y, num2str(z), 'HorizontalAlignment', 'center', 'Color', 'r');
        end
    end
end

axis tight;
axis equal;
title('Neuron Footprints');
hold off;
