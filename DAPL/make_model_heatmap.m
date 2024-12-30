% Load the data
% Assuming the data is saved as 'data.csv' and contains headers in the first row.
filename = "C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\modeling\PMA_TDmodel_params.xlsx"
data = readtable(filename);

rowLabels = {'Row1', 'Row2', 'Row3', 'Row4', 'Row5', 'Row6', 'Row7', 'Row8', 'Row9', 'Row10', ...
             'Row11', 'Row12', 'Row13', 'Row14', 'Row15', 'Row16', 'Row17', 'Row18', 'Row19', 'Row20',...
             '21','22','23','24','25','26','27'};
columnLabels = {'Uncertainty_1', 'Uncertainty_2', 'Uncertainty_3', 'Uncertainty_4', 'Uncertainty_5', ...
                'Base_1', 'Base_2', 'Base_3', 'Base_4', 'Base_5', ...
                'Gamma_1', 'Gamma_2', 'Gamma_3', 'Gamma_4', 'Gamma_5', ...
                'Alpha_1', 'Alpha_2', 'Alpha_3', 'Alpha_4', 'Alpha_5'};

% Ensure data size matches labels
if size(data, 1) ~= length(rowLabels)
    error('Number of rows in data does not match rowLabels.');
end
if size(data, 2) ~= length(columnLabels)
    error('Number of columns in data does not match columnLabels.');
end

% Create Heatmap
h = heatmap(columnLabels, rowLabels, data);

% Customize Heatmap
h.Title = 'Model Heatmap';
h.XLabel = 'Metrics';
h.YLabel = 'Observations';
h.Colormap = hot; % Change colormap as needed
