function [varargout] = linePlot(zall, varargin)
% linePlot: Plots mean and SEM of a matrix of N x M size. Trials in rows,
% timepoints in columns.
%
% Syntax:
%   [fig] = linePlot(zall)
%   [fig] = linePlot(zall, xlines)
%   [fig] = linePlot(zall, xlines, xlineNames)
%   [fig] = linePlot(zall, xlines, xlineNames, align)
%   [fig] = linePlot(zall, xlines, xlineNames, align, smooth)
%
% Inputs:
%   zall       - (N x M matrix) Data matrix with trials in rows and timepoints in columns.
%   varargin   - Variable input arguments:
%       xlines      - (vector) Positions where to plot xlines (e.g., [100, 1000]).
%       xlineNames  - (cell array) Names of xlines for the legend.
%       align       - (binary) Whether to align rows by subtracting mean of the first xline.
%       smooth_wnd  - (int) span for smoothing, 0 is no smoothing
%       title       - (string) title for plot
%
% Outputs:
%   fig - (figure handle) Figure handle of the plot.
%
% Example:
%   zall = rand(10, 1000);
%   xlines = [100, 500, 900];
%   xlineNames = {'Start', 'Middle', 'End'};
%   align = true;
%   smooth_wnd = 200;
%   fig = linePlot(zall, xlines, xlineNames, align, smooth_wnd);

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'zall');
    addOptional(p, 'xlines', []);
    addOptional(p, 'xlineNames', {});
    addOptional(p, 'align', false);
    addOptional(p, 'smooth_wnd', 0);
    parse(p, zall, varargin{:});
    
    zall = p.Results.zall;
    xlines = p.Results.xlines;
    xlineNames = p.Results.xlineNames;
    align = p.Results.align;
    smooth_wnd = p.Results.smooth_wnd;

    if align
        % Subtract DC offset to get signals on top of one another
        zall_offset = zall - mean(mean(zall));
        for i = 1:size(zall, 1)
            zall_offset(i, :) = zall(i, :) - mean(zall(i, 1:xlines(1)));
        end
    else
        zall_offset = zall;
    end

    mean_zall = mean(zall_offset);
    sem_zall = std(zall_offset) / sqrt(size(zall_offset, 1));

    if smooth_wnd > 0
        mean_zall = smooth(mean_zall, smooth_wnd)';
        sem_zall = smooth(sem_zall, smooth_wnd)';
    end

    % Plot individual lines
    figure;
    plot(zall_offset');
    hold on;
    if ~isempty(xlines)
        for i = 1:length(xlines)
            xline(xlines(i), ':');
        end
    end

    % Plot mean and SEM
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

    if ~isempty(xlines)
        for i = 1:length(xlines)
            xline(xlines(i), ':');
        end
    end

    leg = {'SEM', 'Mean'};
    if ~isempty(xlineNames)
        leg = [leg, xlineNames];
    end
    legend(leg);

    % Handle outputs
    nOutputs = nargout;
    varargout = cell(1, nOutputs);
    if nOutputs >= 1
        varargout{1} = fig;
    end
end
