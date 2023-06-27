f2 = fields(out.avg);
for i = 1:length(f2)
    f = f2{i};
    avg_reformat.(f) = reformatCellMat(out.avg.(f));
    writecell(avg_reformat.(f), [f '.csv']);
end


function reformattedMatrix = reformatCellMat(cellMatrix)
    % Get the number of rows in the cell matrix
    numRows = size(cellMatrix, 1);

    % Initialize the reformatted cell matrix
    reformattedMatrix = cell(numRows, 3);

    % Iterate over each row of the cell matrix
    for i = 1:numRows
        % Extract the subject ID, test day, and value from the first column
        % and second column of the current row
        entry = cellMatrix{i, 1};
        subjectID = entry(1:5);
        testDay = str2double(entry(end));
        if testDay == 4
            testDay = 3;
        end
        value = cellMatrix{i, 2};

        % Store the reformatted values in the corresponding row of the
        % reformatted cell matrix
        reformattedMatrix{i, 1} = subjectID;
        reformattedMatrix{i, 2} = testDay;
        reformattedMatrix{i, 3} = value;
    end
end
