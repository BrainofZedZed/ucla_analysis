% GOAL: apply a minimum threshold of difference between first and second
% columns of a matrix
% INPUT:  startStop - Nx2 matrix, typically showing [start, stop] frames,
% minDur - minimum distance between columns
% OUTPUT: Nx2 matrix with rows below minDur excluded

function startStop_thresh = applymin2bouts(startStop, minDur)
    dur = startStop(:,2) - startStop(:,1);
    include = find(dur>minDur);
    startStop_thresh = startStop(include,:);
end
