function ranges = vec2mat(binaryVector)
    % vec2mat Convert a binary vector to start-stop matrix ranges of 1s
    %
    % Input:
    %   binaryVector - A vector containing binary values (0s and 1s)
    %
    % Output:
    %   ranges - An Nx2 matrix where each row contains the start and stop
    %            indices of a sequence of 1s in the binary vector

    % Find the indices where there is a change in value
    changes = [0, diff(binaryVector), 0];
    
    % Find start and end points
    startIndices = find(changes == 1);
    endIndices = find(changes == -1) - 1;
    
    % Create the output matrix
    ranges = [startIndices(:), endIndices(:)];
end
