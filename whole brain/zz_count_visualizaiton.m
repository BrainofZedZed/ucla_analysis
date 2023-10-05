% Load data (replace 'CellCounts.xlsx' with the correct path if necessary)
data = readtable('CellCounts.xlsx');

% 1. Bar chart for all data
figure;
bar(data.cellCountsNormalizedByRegionVolumeAndTotalCells);
set(gca, 'XTick', 1:height(data), 'XTickLabel', data.name, 'XTickLabelRotation', 45, 'FontSize', 6);
title('Cell Counts Normalized by Region Volume Total Cells');
ylabel('Counts');
xlabel('Names');

% 3. Dendrogram for all data
% Extract the 6th column data
activity = data{:, 6};

% Compute hierarchical clustering
Z = linkage(activity, 'average');

% Display the dendrogram
figure;
[H, T, outperm] = dendrogram(Z, 0); % "0" means show all leaf nodes
set(gca, 'XTick', 1:length(outperm), 'XTickLabel', data.name(outperm));
xtickangle(45);
title('Dendrogram for Activity Data');



% Filter data based on 'atlas number'
atlas_numbers = [354, 771, 1097, 549, 313, 795, 536, 1089, 382, 423, 463, 726, 843, 926, 254, 31, 44, 972, 311];
filtered_data = data(ismember(data.atlasNumber, atlas_numbers), :);

% 1. Bar chart for filtered data
figure;
bar(filtered_data.cellCountsNormalizedByRegionVolumeAndTotalCells);
set(gca, 'XTick', 1:height(filtered_data), 'XTickLabel', filtered_data.name, 'XTickLabelRotation', 45, 'FontSize', 6);
title('Filtered Cell Counts Normalized by Total Cells and Region Volume');
ylabel('Counts');
xlabel('Names');

% 3. Dendrogram for filtered data
filtered_activity = filtered_data{:, 6};
Z_filtered = linkage(filtered_activity, 'average');

figure;
[H_filtered, T_filtered, outperm_filtered] = dendrogram(Z_filtered, 0);
set(gca, 'XTick', 1:length(outperm_filtered), 'XTickLabel', filtered_data.name(outperm_filtered));
xtickangle(45);
title('Dendrogram for Filtered Activity Data');