list = [1, 20, 8, 3, 2, 7];
figure;
hold on
    for i_c = 1:length(list)
        if sum(d1_table{list(i_c), 2:end}) == 0
            plot(cntrs{list(i_c)}(1, :), pixh - cntrs{list(i_c)}(2, :), 'k');
%         elseif nnz(d1_table{list(i_c), 2:end}) > 1
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'k', 'FaceAlpha', 0.5);
        elseif (d1_table{list(i_c), 'platform'} ~= 0) && (d1_table{list(i_c), 'freeze'} ~= 0)
            fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), [.5 0 .5]);
        elseif d1_table{list(i_c),'platform'} == 1
            fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'c');
        elseif d1_table{list(i_c),'platform'} == 2
            fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'c', 'FaceAlpha', 0.2);
        elseif d1_table{list(i_c),'freeze'} == 1
            fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r');
        elseif d1_table{list(i_c),'freeze'} == 2
            fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r', 'FaceAlpha', 0.2);        
%         elseif d1_table{list(i_c),'tone'} == 1
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'm');
%         elseif d1_table{list(i_c),'tone'} == 2
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'm', 'FaceAlpha', 0.1);
       
%          elseif (d1_table{list(i_c),'tone_platform'} == 1)
%              fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r');
%         elseif (d1_table{list(i_c),'tone_platform'} == 2)
%              fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r', 'FaceAlpha', 0.2);
        else
            plot(cntrs{list(i_c)}(1, :), pixh - cntrs{list(i_c)}(2, :), 'k');

        % elseif (d1_table{list(i_c),'tone_platform'} == 2) | (d1_table{list(i_c),'tone_platform'} == 2)
         %    fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r', 'FaceAlpha', 0.1);
%         elseif d1_table{list(i_c),'tone_freeze'} == 2
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'r', 'FaceAlpha', 0.1);
%         elseif d1_table{list(i_c),'platform_freeze'} == 1
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'g');
%         elseif d1_table{list(i_c),'platform_freeze'} == 2
%             fill(cntrs{list(i_c)}(1,:), cntrs{list(i_c)}(2,:), 'g', 'FaceAlpha', 0.1);
        end
    end
    
    leg_vec = {'no response', 'platform excited', 'platform suppressed', 'freeze excited', 'freeze suppressed', 'dual encoding'};
    legend(leg_vec);
    %legend.Layout.Tile = 'east';