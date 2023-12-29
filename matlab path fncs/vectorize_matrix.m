function binary_vector = vectorize_matrix(input_matrix, end_number)
    % Check if 'end_number' is provided, if not, set it to the max value in the second column
    if nargin < 2
        end_number = max(input_matrix(:, 2));
    end

    % Initialize binary vector with zeros
    binary_vector = zeros(1, end_number);

    % Loop through each row of the input matrix
    for i = 1:size(input_matrix, 1)
        % Extract the start and end values from the current row
        start_value = input_matrix(i, 1);
        end_value = input_matrix(i, 2);
        
        % Set the elements in the binary vector to 1 within the specified range
        binary_vector(start_value:end_value) = 1;
    end
end
