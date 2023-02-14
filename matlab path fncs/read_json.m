function data = read_json(fileName)
    % input JSON filename, converts it to struct
    % from MATLAB forums https://www.mathworks.com/matlabcentral/answers/474980-extract-info-from-json-file-by-matlab
    fid = fopen(fileName); % Opening the file
    raw = fread(fid,inf); % Reading the contents
    str = char(raw'); % Transformation
    fclose(fid); % Closing the file
    data = jsondecode(str); % Using the jsondecode function to parse JSON from string
end