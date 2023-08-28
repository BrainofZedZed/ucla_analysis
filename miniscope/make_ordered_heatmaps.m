cutoff = 28996;
bhsig = sig(:,frtslu(1:end,3));
nn = size(bhsig,1);
n_vec = 1:nn;

% APPROACH ONE ROCLog:  DO excited, then suppressed, then other
z = table2array(ROC_Log);
csp_e = z{3,3};
csp_s = z{3,5};
csp_other = setdiff(n_vec,[csp_e; csp_s])';
csp_other = csp_other(randperm(length(csp_other)));
newC = bhsig([csp_e; csp_s; csp_other],:);


% APPROACH ONE:  DO excited, then suppressed, then other
csp_e = out.freeze.n_excited;
csp_s = out.freeze.n_suppressed;
csp_other = setdiff(n_vec,[csp_e; csp_s])';
csp_other = csp_other(randperm(length(csp_other)));
newC = bhsig([csp_e; csp_s; csp_other],:);

% APPROACH TWO: order by AUC
[a b] = sort(out.CSp.auc_neurons,'descend');
newC = bhsig(b,:);

%%
frz_length = 3;
frz_ind = find(Behavior.Freezing.Bouts(:,2)-Behavior.Freezing.Bouts(:,1)>(frz_length*30));
i_cueframes = Behavior.Freezing.Bouts(frz_ind,:);
%event_dur = i_cueframes(1,2)-i_cueframes(1,1);
event_dur = 1;
pre_frames = 3*30;
post_frames = 90;

event_frames = zeros(size(i_cueframes));
for i = 1:size(event_frames,1)
    event_frames(i,1) = i_cueframes(i,2) - pre_frames;
    event_frames(i,2) = i_cueframes(i,2)+event_dur+post_frames;
end

event_sig = [];
for i = 1:nn
    j_sig = [];
    for j = 1:size(event_frames)
        j_sig(j,:) = newC(i,event_frames(j,1):event_frames(j,2));
    end
    event_sig(i,:) = mean(j_sig,1);
    event_sig(i,:) = rescale(event_sig(i,:),0,1);
end
figure;
imagesc(event_sig);
colormap hot
xline(pre_frames,'--w','LineWidth',2)
xline(event_dur+pre_frames, '--w','LineWidth',2);

yticks(1:(length(csp_e)+length(csp_s)));
rowLabels = [repmat({'E'}, 1, length(csp_e)), repmat({'S'}, 1, length(csp_s))];
yticklabels(rowLabels);

%%
% Find the maximum values and their indices for each row
[~, idx] = max(event_sig(:,1:end), [], 2);

% Sort the rows based on the indices of their maximum values
[~, sortedRowIndices] = sort(idx, 'ascend');

% Reorder the rows of the matrix based on the sorted indices
sortedMatrix = event_sig(sortedRowIndices, :);

figure;
imagesc(sortedMatrix);
colormap hot
xline(pre_frames,'--w','LineWidth',2)
xline(event_dur+pre_frames, '--w','LineWidth',2);

yticks(1:(length(csp_e)+length(csp_s)));
rowLabels = [repmat({'E'}, 1, length(csp_e)), repmat({'S'}, 1, length(csp_s))];
yticklabels(rowLabels);