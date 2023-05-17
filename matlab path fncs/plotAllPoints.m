function plotAllPoints(dataStruct, columnNumber, figLims)
    % Get the field names from the struct
    fieldNames = fieldnames(dataStruct);
    
    % Create a figure
    figure;
    
    hold on;
    
    % Loop through each field
    for i = 1:numel(fieldNames)
        % Get the current field data
        fieldData = dataStruct.(fieldNames{i});
        
        % Extract the column coordinates based on the input number
        columnCoords = fieldData(:, columnNumber);
        
        % Plot the point
        plot(columnCoords(1), columnCoords(2), 'o');
    end
    
    hold off;
    
    % Set plot title and axis labels
    title('Points from Struct Fields');
    xlabel('X');
    ylabel('Y');
end
