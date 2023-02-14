function f_tbl = prepFrluData(ms_ts_file, beh_ts_file)

%% Import timestamp files for V4 and BehCam
    
    % Collect timestamp data
    ms = readtable(ms_ts_file);
    beh = readtable(beh_ts_file);
    
    % Prep and label data for alignment
    ms_ID = array2table(zeros(size(ms,1), 1));
    beh_ID = array2table(ones(size(beh,1), 1));
    
    ms = [ms_ID, ms];
    beh = [beh_ID, beh];
    
    % Assemble output table for alignment
    f_tbl = [ms; beh];

    clearvars ms beh tbl ms_ID beh_ID
    
end