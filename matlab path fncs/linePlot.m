% linePlot:  plots mean and SEM of a matrix of N x M size. Trials in rows,
% timepoints in columns.
% INPUT: zall (N x M matrix), xlines (vector of where to plot xlines eg
% [100, 1000]), xlineNames (cell array of names of xlines for legend)

function [varargout]  = linePlot(zall, xlines, xlineNames)

    % Subtract DC offset to get signals on top of one another
    zall_offset = zall - mean(mean(zall));
    %zall_offset = zall_offset - mean(zall_offset(1:250));
    mean_zall = mean(zall_offset);
    std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
    sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));
    
    % plot mean and sem
    fig = figure;
    y = mean_zall;
    x = 1:numel(y);
    curve1 = y + sem_zall;
    curve2 = y - sem_zall;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    h = fill(x2, inBetween, 'r');
    set(h, 'facealpha', 0.25, 'edgecolor', 'none');
    hold on;
    plot(x, y, 'r', 'LineWidth', 2);
    
    for i = 1:length(xlines)
        xline(xlines(i),':');
    end
    
    leg = {'SEM', 'Mean'};
    for i = 1:length(xlineNames)
        leg = [leg xlineNames{i}];
    end
    legend(leg)

      nOutputs = nargout;
    varargout = cell(1, nOutputs);
    
    if nOutputs == 1 
        varargout{1} = fig;
    end

end


