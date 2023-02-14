% GRAVEYARD


% iterate over binary thresholds and generate true positive and false
% positive rates
roc = zeros(100,2,size(zsig,1));

for i = 1:size(zsig,1)
    sig_min = min(zsig(i,:));
    sig_max = max(zsig(i,:));

    % break up step size to range / 100
    count = 1;
    for th = sig_min:((sig_max - sig_min) / 99):sig_max
        true_pos = 0;
        false_pos = 0;
        false_neg = 0;
        true_neg = 0;

        for frame = 1:size(zsig,2)
            if eventmat(frame) == 1
                if zsig(i,frame) >= th
                    true_pos = true_pos + 1;
                else
                    false_neg = false_neg + 1;
                end
            else
                if zsig(i,frame) >= th
                    false_pos = false_pos + 1;
                else
                    true_neg = true_neg + 1;
                end         
            end
        end

        tpr = true_pos / (true_pos + false_neg);
        fpr = 1 - (false_pos / (false_pos + true_neg));
        roc(count, :, i) = [fpr, tpr];
        count = count+1;
    end
end
