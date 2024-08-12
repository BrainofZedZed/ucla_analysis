function drawRectangles(x_coords)

% drawRectangles overlays red rectanges on a plot, defined by the ylim of
% the current figure and then the x points in a row in the x_points matrix.
% input:  x_points, Nx2 matrix with row indices for rectangle X position

    % Define x-axis boundary pairs for the rectangles
    xBoundaries = x_coords; % Each row is a pair [x1, x2]
    
    % Get the limits of the current y-axis
    yLimits = ylim;
    
    % Loop over each pair of boundaries to draw rectangles
    for i = 1:size(xBoundaries, 1)
        x1 = xBoundaries(i, 1);
        x2 = xBoundaries(i, 2);
        rectangle('Position', [x1, yLimits(1), x2 - x1, diff(yLimits)], ...
                  'FaceColor', [1, 0, 0, 0.3], ... % Red color with 30% opacity
                  'EdgeColor', 'none'); % No edge
    end
end