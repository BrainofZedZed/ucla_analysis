function Cues = assembleCueSessions(Cues)

total_frames = size(Cues.toneVector, 2);

%% Separate shocks by learning period
shock_number = 0;

try
    shocks = Cues.shocks;
    shock_number = size(shocks, 1);
    
    if size(shocks, 1) == 9
        Cues.ELshocks = shocks(1:5,:);
        Cues.LLshocks = shocks(5:9,:);
    elseif size(shocks, 1) == 12
        Cues.ELshocks = shocks(1:6,:);
        Cues.LLshocks = shocks(7:12,:);
    end    
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

period_vectors = fieldnames(Cues.Session);
vec_check = contains(period_vectors, 'vector');
period_vectors = period_vectors(vec_check);

if shock_number > 0
    cue_vectors = {'toneVector'; 'shockVector'};
else
    cue_vectors = {'toneVector'};
end

%% Make vectors for extracted data

for sp = 1:size(period_vectors, 1)
    current_sp_vec = period_vectors{sp};
    for c = 1:size(cue_vectors, 1)
        current_cue_vec = cue_vectors{c};
        new_vec = Cues.Session.(current_sp_vec) & Cues.(current_cue_vec);
        new_vec_name = newVecName(current_sp_vec, current_cue_vec);
        Cues.(new_vec_name) = new_vec;
    end
end

save(['Cues_' Cues.ID], 'Cues')
end