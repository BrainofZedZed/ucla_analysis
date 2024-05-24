% Get a list of all folders in the current directory
target = 'C:\Users\boba4\Box\Zach_repo\Projects\DA PMA\fiber photometry\GRABDA FC\cohort2\batch';
folders = dir(target);
folders = folders([folders.isdir]);  % Keep only directories

% Initialize cell matrices for D0 and D1 sessions
D0_sig = {};
D1_sig = {};

% Loop through each folder
for i = 1:length(folders)
    folderName = folders(i).name;
    
    % Check if the folder name matches the pattern "DPXXX_DX"
    if startsWith(folderName, 'DP') && length(folderName) >= 8 && folderName(6) == '_'
        % Extract ID and session
        ID = folderName(1:5);
        session = folderName(7:end);
        
        % Define the file pattern to search for
        filePattern = fullfile(target, folderName, '*CSp_fibpho_analysis.mat');
        files = dir(filePattern);
        
        % If a matching file is found, load 'zall'
        if ~isempty(files)
            data = load(fullfile(files(1).folder, files(1).name), 'zall');
            if isfield(data, 'zall')
                zall = data.zall;
                
                % Repeat the ID for each row of zall
                ID_column = repmat({ID}, size(zall, 1), 1);
                
                % Determine which cell matrix to add to based on the session
                if strcmp(session, 'D0')
                    zall = zall(:,1:1100);
                    % Check if zall has the same number of columns as the previous zall
                    if isempty(D0_sig)
                        D0_sig = [ID_column, num2cell(zall)];
                    else             
                        D0_sig = [D0_sig; [ID_column, num2cell(zall)]];
                    end
                elseif strcmp(session, 'D1')
                    % Check if zall has the same number of columns as the previous zall
                    zall = zall(:,1:2100);
                    if isempty(D1_sig)
                        D1_sig = [ID_column, num2cell(zall)];
                    else 
                        D1_sig = [D1_sig; [ID_column, num2cell(zall)]];
                    end
                end
            end
        end
    end
end

% Display results
disp('D0_sig:');
disp(D0_sig);
disp('D1_sig:');
disp(D1_sig);
