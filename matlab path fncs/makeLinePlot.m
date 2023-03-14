function data = makeLinePlot(varargin) 

    zall = varargin{1};
    figure;
    % Subtract DC offset to get signals on top of one another
    if nargin >=2
        x1 = varargin{2};
        zall_offset = zall - mean(mean(zall));
        zero_shift = mean(zall_offset(:,1:x1),2);
        zall_offset = zall_offset - zero_shift;
        mean_zall = mean(zall_offset);
        std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
        sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));
    else
        zall_offset = zall - mean(mean(zall));
        mean_zall = mean(zall_offset);
        std_zall = std(double(zall_offset))/sqrt(size(zall_offset,1));
        sem_zall = std(zall_offset)/sqrt(size(zall_offset,1));
    end

    % plot mean and sem
    subplot(1,2,1);
    y = mean(zall_offset);
    x = 1:numel(y);
    curve1 = y + sem_zall;
    curve2 = y - sem_zall;
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    h = fill(x2, inBetween, 'r');
    set(h, 'facealpha', 0.25, 'edgecolor', 'none');
    hold on;
    plot(x, y, 'r', 'LineWidth', 2);
    
        if nargin >=2
            % Plot vertical line at epoch onset, time = 0
            x1 = varargin{2};
            xline(x1, ':', 'LineWidth', 2);
        end
        if nargin >= 3
            x2 = varargin{3};
            xline(x2, ':', 'LineWidth', 2);
        end
        
        %labels
        title ('Average with SEM');
        axis tight

    % do same, with each trial plotted individually
    subplot(1,2,2);
    plot(zall_offset');
    if nargin >= 2
        xline(x1, ':', 'LineWidth', 2);
    end
    if nargin >=3
        x2 = varargin{3};
        xline(x2, ':', 'LineWidth', 2);
    end
    
    %labels
    num_t = size(zall,1);
    leg = {};
    for i = 1:num_t
        i_t = ['trial ' num2str(i)];
        leg = [leg {i_t}];
    end
    legend(leg);
    title('Individual trials');
    axis tight

    if nargin >=4
        ttl = varargin{4};
        sgtitle(ttl);
    end
    data = zall_offset;
end