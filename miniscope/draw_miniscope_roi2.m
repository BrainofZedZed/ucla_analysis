% INPUT:  A - spatial footprints arranged in (X,Y,cell); default
% organization from MiniAn.
% tl;dr:  takes footprints from MiniAn, finds the edges, orders them in
% clockwise direction, turns them into polygons, then plots them. Advantage
% of polygon object is easy calculations of shape properties (area,
% eccentricity, etc)

[f p] = uigetfile('.mat', 'Load .mat file with footprints');
load([p f]);
A = Adata;
contours = false(size(A));  % empty matrix for cell contours
centers = zeros(size(A,3),2);  % empty matrix for center calculations
footprints = polyshape.empty;  % empty polygon array for cell contours

figure;
set(gca, 'Color', 'w');
xlim([0, size(A,1)]);
ylim([0, size(A,2)]);
axis square;
hold on

A2 = A;
A2(A2 ~= 0) = 1;
for i = 1:size(A,3)
    contours(:,:,i) = edge(A2(:,:,i));  % finds edges of footprint
    [r, c] = find(contours(:,:,i) ~= 0);
    centers(i,1) = mean(c);  % get center of shape to calculate vertex angles
    centers(i,2) = mean(r);
    angles = zeros(size(r));  % zeros out an angle array, used to order the vertices of the footprints
    for j = 1:size(r)
        angles(j) = atan2d((r(j) - centers(i,2)), (c(j) - centers(i,1)));  % calculates the angle of each vertex
    end
        
    [sortedAngles, sortedIndexes] = sort(angles);  % sorts angles
     x = c(sortedIndexes);  % rearranges vertices based on angles
     y = r(sortedIndexes);  %
     footprint = polyshape(x,y);  % creates a polygon based on vertices
     plot(footprint, 'FaceAlpha', 1, 'FaceColor', 'g');  % plots
     footprint = polyshape.empty;
end