function [stimframes_ms] = alignStimFunc(ts, ds, mscamnum, dummybehavcamnum, stimframes)

msframes = [];
dummybehavframes = [];

tbl = readtable(ts); 
tbl = tbl{:,:};
% create separate lists of miniscope and stimcam frames
for i = 1:size(tbl,1)
    if tbl(i,1) == mscamnum
        msframes = [msframes; tbl(i,:)];
    elseif tbl(i,1) == dummybehavcamnum
        dummybehavframes = [dummybehavframes; tbl(i,:)];
    end
end

msstimframes = [dummybehavframes(stimframes(:,1),3), dummybehavframes(stimframes(:,2),3)];

% adjust for temporal downsampling
msframes = msframes(1:ds:end,:);
msstimframes = floor(msstimframes/ds);

% find matching ms frame for dummy beh frame
match1 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,1);
    dif = msframes(:,3)-t;
    difN = dif(dif<0);
    match1(i) = length(difN);

end

match2 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,2);
    dif = msframes(:,3) - t;
    difN = dif(dif<0);
    match2(i) = length(difN);

end
match1 = match1';
match2 = match2';


stimframes_ms = [match1 match2];

end