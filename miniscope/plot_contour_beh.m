% edited from min1pipe function

    %%% prepare contours %%%
    [x, y] = ind2sub([pixh, pixw], seedsfn);
    ids = 1: length(x);
    cntrs = cell(1, length(ids));
    thres = 0.8;
    for i_c = 1: length(ids)
        tmp = full(reshape(roifn(:, ids(i_c)), pixh, pixw) * max(sigfn(ids(i_c), :), [], 2));
        tmp = imgaussfilt(tmp, 3);
        lvl = max(max(tmp)) * thres;
        cntrs{i_c} = contour(flipud(tmp), [lvl, lvl]);
        cntrs{i_c} = [cntrs{i_c}(:, 2: end - 1), cntrs{i_c}(:, 2)];
    end
    
    %%% plot %%%
nn = length(cntrs);
figure;
hold on
    for i_c = 1:nn
        if sum(d1_table{i_c, 2:end}) == 0
            plot(cntrs{i_c}(1, :), pixh - cntrs{i_c}(2, :), 'k');
%         elseif nnz(d1_table{i_c, 2:end}) > 1
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'k', 'FaceAlpha', 0.5);
        elseif (d1_table{i_c, 'platform'} ~= 0) && (d1_table{i_c, 'freeze'} ~= 0)
            fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), [.5 0 .5]);
        elseif d1_table{i_c,'platform'} == 1
            fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'c');
        elseif d1_table{i_c,'platform'} == 2
            fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'c', 'FaceAlpha', 0.2);
        elseif d1_table{i_c,'freeze'} == 1
            fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r');
        elseif d1_table{i_c,'freeze'} == 2
            fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r', 'FaceAlpha', 0.2);        
%         elseif d1_table{i_c,'tone'} == 1
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'm');
%         elseif d1_table{i_c,'tone'} == 2
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'm', 'FaceAlpha', 0.1);
       
%          elseif (d1_table{i_c,'tone_platform'} == 1)
%              fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r');
%         elseif (d1_table{i_c,'tone_platform'} == 2)
%              fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r', 'FaceAlpha', 0.2);
        else
            plot(cntrs{i_c}(1, :), pixh - cntrs{i_c}(2, :), 'k');

        % elseif (d1_table{i_c,'tone_platform'} == 2) | (d1_table{i_c,'tone_platform'} == 2)
         %    fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r', 'FaceAlpha', 0.1);
%         elseif d1_table{i_c,'tone_freeze'} == 2
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'r', 'FaceAlpha', 0.1);
%         elseif d1_table{i_c,'platform_freeze'} == 1
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'g');
%         elseif d1_table{i_c,'platform_freeze'} == 2
%             fill(cntrs{i_c}(1,:), cntrs{i_c}(2,:), 'g', 'FaceAlpha', 0.1);
        end
    end
    
    %leg_vec = {'no response', 'freeze excited', 'freeze suppressed', 'tone excited', 'tone suppressed', 'platform excited', 'platform suppressed', 'tone+freeze excited', 'tone+freeze suppressed', 'platform+freeze excited', 'platform+freeze suppressed'}; 
    %legend(leg_vec);
    