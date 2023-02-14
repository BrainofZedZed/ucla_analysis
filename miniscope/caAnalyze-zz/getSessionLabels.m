function Cues = getSessionLabels(Cues)

total_frames = size(Cues.toneVector, 2);

%% Separate shocks by learning period
shock_number = 0;

try
    shocks = Cues.shocks;
    shock_number = size(shocks, 1);   
end

%% Separate learning periods based on number of shocks
tones = Cues.tones;

if shock_number == 9
    Cues.Session.BL = [1, tones(3,2)];
    Cues.Session.EL = [tones(3,2)+1, tones(8,2)];
    Cues.Session.LL = [tones(8,1), total_frames];
    Cues.Session.BLvector = makeVector(Cues.Session.BL, total_frames);
    Cues.Session.ELvector = makeVector(Cues.Session.EL, total_frames);
    Cues.Session.LLvector  = makeVector(Cues.Session.LL, total_frames);
elseif shock_number == 12
    Cues.Session.EL = [1, tones(6,2)];
    Cues.Session.LL = [tones(6,1), total_frames];
    Cues.Session.ELvector = makeVector(Cues.Session.EL, total_frames);
    Cues.Session.LLvector  = makeVector(Cues.Session.LL, total_frames);
elseif shock_number == 0
    Cues.Session.ER = [1, tones(5,2)];
    Cues.Session.LR = [tones(5,1), total_frames];
    Cues.Session.ERvector = makeVector(Cues.Session.ER, total_frames);
    Cues.Session.LRvector  = makeVector(Cues.Session.LR, total_frames);
end

save(['Cues_' Cues.ID], 'Cues')
end