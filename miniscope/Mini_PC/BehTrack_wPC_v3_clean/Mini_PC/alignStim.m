function [stimframes_ms] = alignStim(tbl, stimframes, fps)

mscamnum = 0;
behavcamnum = 0;
dummybehavcamnum = 1;

msframes = [];
dummybehavframes = [];

for i = 1:size(tbl,1)
    if tbl(i,1) == mscamnum
        msframes = [msframes; tbl(i,:)];
    elseif tbl(i,1) == dummybehavcamnum
        dummybehavframes = [dummybehavframes; tbl(i,:)];
    end
end

msstimframes = [dummybehavframes(stimframes(:,1),3) dummybehavframes(stimframes(:,2),3)];

if fps == 15 | fps == 10
    msframes = msframes(1:2:end,:);
end

% find matching ms frame for dummy beh frame
match1 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,1);
    dif = msframes(:,3)-t;
    difN = dif(dif<0);
    match1(i) = length(difN);
    match1(i) = match1(i) - 3;  % hard code alignment to approximate shifts in stim alignment

end

match2 = [];
for i = 1:size(msstimframes,1)
    t = msstimframes(i,2);
    dif = msframes(:,3) - t;
    difN = dif(dif<0);
    match2(i) = length(difN);
    match2(i) = match2(i) - 3;  % hard code alignment to approximate shifts in stim alignment

end
match1 = match1';
match2 = match2';


stimframes_ms = [match1 match2];

% old
% % HARDCODE FOR ANALYSES DONE AT REDUCED FPS (eg 30 down to 15)
% if fps == 15 | fps == 10
%     stimframes_ms = stimframes_ms / 2;
%     stimframes_ms = floor(stimframes_ms);
% end

end