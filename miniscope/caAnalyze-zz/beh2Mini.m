% beh2Mini: post-BehaviorDEPOT Script for FRLU Generation and Miniscope-Aligned Prep

function caBehavior = beh2Mini(Behavior, Metrics, frlu, total_ca_frames)
% Create a copy of data (for adjustment)
caBehavior = struct();

num_frames = total_ca_frames;
beh2ca = frlu(:,2);


% Use lookup table to convert annotations in tempBehavior
% Do Behavior.Temporal
behavs = fieldnames(Behavior.Temporal);

bouts = beh2ca(Behavior.Freezing.Bouts);
caBehavior.Freezing = genBehStruct(bouts(:,1), bouts(:,2), num_frames);
% for i = 1:size(behavs, 1)
%     % convert behavior bouts from behavior frames to miniscope frames
%     bouts = beh2ca(Behavior.Temporal.(behavs{i}).Bouts);
%     
%     % save to outbound struct
%     caBehavior.(behavs{i}) = genBehStruct(bouts(:,1), bouts(:,2), num_frames);
%     
% end

% do Freezing
% bouts = beh2ca(Behavior.Freezing.Bouts);
% caBehavior.Freezing = genBehStruct(bouts(:,1), bouts(:,2), num_frames);
% 
% % do intersect
% [a b] = findStartStop(Behavior.Intersect.TemBeh.csp.Freezing.BehInEventVector);
% bouts = [a, b];
% caBehavior.cspFreezing = genBehStruct(bouts(:,1), bouts(:,2), num_frames);
% 
% [a b] = findStartStop(Behavior.Intersect.TemBeh.csm.Freezing.BehInEventVector);
% bouts = [a,b];
% caBehavior.csmFreezing = genBehStruct(bouts(:,1), bouts(:,2), num_frames);
% 

% Save caBehavior struct
save('caBehavior.mat', 'caBehavior')

end