function caBehavior = assembleBehSessions(caBehavior, Cues)

%% Determine Learning Session Type based on number of tones
total_frames = size(Cues.toneVector, 2);

caBehavior.Session = Cues.Session;

% %% Check number of tones
% tones = Cues.tones;
% tone_number = size(tones, 1);
% 
% %% Check if shocks are present
% try
%     shock_number = size(Cues.shocks, 1);
% catch
%     shock_number = 0;
% end
% 
% %% If a Retrieval / NoPlatform Session (9 tones, 0 shocks)
% if tone_number == 9 && shock_number == 0
%     caBehavior.ER = [1, tones(5,2)];
%     caBehavior.LR = tones(5,2)+1, total_frames];
%     
% %% If a Training 1 Session (12 tones, 9 shocks)
% elseif tone_number == 12 && shock_number == 9
%     caBehavior.BL = [1, tones(3,2)];
%     caBehavior.EL = [tones(3,2)+1, tones(8,2)];
%     caBehavior.LL = [tones(8,1), total_frames];
% 
% %% If a Training 2 Session (12 tones, 12 shocks)
% elseif tone_number == 12 && shock_number == 12
%     caBehavior.EL = [1, tones(6,2)];
%     caBehavior.LL = [tones(6,1), total_frames];
% end

% Prep session_labels, which contain str labels for learning periods
session_labels = fieldnames(caBehavior.Session);
to_remove = contains(session_labels, {'vector', 'Vector'});
session_labels(to_remove) = [];

% Prep beh_labels, which contain str labels for behaviors
beh_labels = fieldnames(caBehavior);
remove_sess = contains(beh_labels, {'session', 'Session'});
beh_labels(remove_sess) = [];

for s = 1:size(session_labels, 1)
    current_sess_label = session_labels{s};
    
    for b = 1:size(beh_labels, 1)
        current_beh_label = beh_labels{b};
        new_vec = caBehavior.Session.([current_sess_label, 'vector']) & caBehavior.(current_beh_label).Vector;
        new_vec_name = newVecName(current_sess_label, current_beh_label);
        caBehavior.(new_vec_name) = new_vec;
    end
end

save('caBehavior.mat', 'caBehavior')
end