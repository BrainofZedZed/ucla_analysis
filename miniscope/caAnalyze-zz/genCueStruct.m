function Cues = genCueStruct(cue_file, totalCaFrames, downsample, exp_file, frlu)
% generates Cue struct holding all cue information in frames relative to
% calcium imaging

load(exp_file, 'exp_ID');
load(cue_file, 'cueframes');
cues = fieldnames(cueframes);

Cues.ID = exp_ID;

beh2ca = frlu(:,2);

for i = 1:length(cues)
    if strcmp(cues(i), 'csp') 
        Cues.csp = beh2ca(cueframes.(cues{i}));
        Cues.cspVector = makeVector(Cues.csp, totalCaFrames);
    elseif strcmp(cues(i), 'us')
        Cues.shocks = beh2ca(cueframes.(cues{i}));
        Cues.shockVector = makeVector(Cues.shocks, totalCaFrames);  
    elseif strcmp(cues(i), 'csm')
        Cues.csm = beh2ca(cueframes.(cues{i}));
        Cues.csmVector = makeVector(Cues.csm, totalCaFrames);
    elseif strcmp(cues(i), 'laser')
        Cues.laser = beh2ca(cueframes.(cues{i}));
        Cues.laserVector = makeVector(Cues.laser, totalCaFrames);   
    end
end

save(['Cues_' exp_ID], 'Cues')

end
