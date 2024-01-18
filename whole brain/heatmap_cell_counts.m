%% get the cellCounts files
% Specify the files
targetDirectory = 'D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d';

% Recursively search for 'CellCounts.xlsx' files
fileList = dir(fullfile(targetDirectory, '**', 'CellCounts.xlsx'));

% Initialize a cell array to store paths
cellCountsPaths = cell(length(fileList), 1);

% Store the full path of each found file in the cell array
for k = 1:length(fileList)
    cellCountsPaths{k} = fullfile(fileList(k).folder, fileList(k).name);
end

%%
% here, need to manually go into cellCountPaths and remove rows that you
% don't want to be analyzed before continuing
%%

files = cellCountsPaths;

%% hard code group IDs
% Define the set of strings to check for assigning 'C'
cno_names = {'1A', '2A', '3C', '4A', '5C', '6A', '6B'};
saline_names = {'1B', '1C', '3A', '3D', '5A', '5B', '7A'};


% Initialize the group_ID cell array
group_ID = cell(size(cellCountsPaths));
animal_ID = cell(size(cellCountsPaths));

% Process each path in cellCountsPaths
for k = 1:length(cellCountsPaths)
    path = cellCountsPaths{k};
    group_ID{k} = ''; % Default to blank

    % Check for each string in the set
    for str = cno_names
        if contains(path, ['\' str{1}])
            group_ID{k} = 'CNO';
            animal_ID{k} = str{1}; % Save the matched string
            break; % Exit the inner loop if a match is found
        end
    end
    % Check for each string in the set
    for str = saline_names
        if contains(path, ['\' str{1}])
            group_ID{k} = 'saline';
            animal_ID{k} = str{1};
            break; % Exit the inner loop if a match is found
        end
    end
end



%% make heatmap for all brains
% Initialize
all_counts = [];  % To store cell counts from all files

data_col = 5;  % which column from CellCounts.xlsx to use as data for plot
% 5 is noramlized by volume and total count
% 4 is noramlized just by volume

% Loop through each file and extract data
for i = 1:length(files)
    % Read the 'names' and the counts from the excel file
    [~,~,raw_data] = xlsread(files{i});
    
    % Assuming the header is in the first row, extract data from second row onwards
    names = raw_data(2:end, 2);
    counts = cell2mat(raw_data(2:end, data_col));
    
    % Append the counts to our main data
    all_counts(:, i) = counts;
end

% Modify labels to differentiate duplicates
unique_labels = cell(size(animal_ID));
for i = 1:length(animal_ID)
    unique_labels{i} = [group_ID{i} ' ' animal_ID{i}];
end
    
% Plot heatmap
figure;
h = heatmap(names, unique_labels, all_counts', 'Colormap', parula);
h.Title = 'Brain Regions vs Treatment';
h.XLabel = 'Brain Regions';
h.YLabel = 'Treatment';

% Modify y-axis labels to only display the original labels (e.g., 'CNO' or 'SALINE')
%yticks(1.5:2:length(unique_labels)+0.5);
%yticklabels({'C', 'S'});  % Adjust if more categories are added

%% get group averages and plot difference
% Initialize
all_counts = [];  % To store cell counts from all files

% Loop through each file and extract data
for i = 1:length(files)
    % Read the 'names' and the counts from the excel file
    [~,~,raw_data] = xlsread(files{i});
    
    % Assuming the header is in the first row, extract data from second row onwards
    names = raw_data(2:end, 2);
    counts = cell2mat(raw_data(2:end, data_col));
    
    % Append the counts to our main data
    all_counts(:, i) = counts;
end

% Calculate the averages for each group
cno_avg = mean(all_counts(:, strcmp(group_ID, 'CNO')), 2);
saline_avg = mean(all_counts(:, strcmp(group_ID, 'saline')), 2);

% Calculate the difference
difference = cno_avg - saline_avg;

% Plot the difference
figure;
bar(difference);
xlabel('Brain Regions');
ylabel('Difference in Cell Counts (CNO - SALINE)');
title('Difference in Average Cell Counts Between CNO and SALINE');
xticks(1:length(names));
xticklabels(names);
xtickangle(45);  % Angle the x-axis labels for better visibility

%% stats
cno_data = all_counts(:, strcmp(group_ID, 'CNO'));
saline_data = all_counts(:, strcmp(group_ID, 'saline'));

region_numbers = [79, 80, 81, 82, 97, 98, 99, 120, 134, 135, 136, 137, 138];
region_stats = names(region_numbers);
% Specify the rows you want to test
rowsToTest = region_numbers; % Replace with the row numbers you're interested in

% Initialize arrays to store results
p_values = zeros(size(rowsToTest));
h_values = zeros(size(rowsToTest));

% Loop through each specified row and perform the t-test
for i = 1:length(rowsToTest)
    rowNumber = rowsToTest(i);

    % Extract the specific rows from each matrix
    row_cno_data = cno_data(rowNumber, :);
    row_saline_data = saline_data(rowNumber, :);

    % Perform the t-test
    [h, p, ci, stats] = ttest2(row_cno_data, row_saline_data);

    % Store results
    region_stats{i,2} = p;
end

%% 
ca1_row = 79;
pl_row = 120;

cno_ca1 = cno_data(ca1_row, :);
saline_ca1 = saline_data(ca1_row,:);

cno_pl = cno_data(pl_row,:);
saline_pl = saline_data(pl_row,:);
