% % Collect info from annotation table
behavs = RawAnnotations.Behavior;
cats = categories(behavs);
% 
for i = 1:length(cats)
   cat_inds(:, i) = (behavs == cats(i));
end
% 
% behav_inds = [RawAnnotations.StartFrame, RawAnnotations.EndFrame];
% 
% % Convert from BehCAM to Miniscope using LUT
% 
% ms_inds = zeros(size(behav_inds));
% 
% % Loop through all behav vid inds and convert using lookup table
% for i = 1:length(behav_inds) * 2
%     ind = behav_inds(i);
%     ms_ind = frlu(ind, 2);
%     ms_inds(i) = ms_ind;
% end
% 
% CorrectedAnnotations = table(ms_inds(:,1), ms_inds(:,2), behavs, 'VariableNames', {'Start', 'Stop', 'Behavior'});

% Sort annotations by behavior

% Make bouts array for each behavior in cats

total_mini_frames = 53621;

for i = 1:length(cats)
    
    b = cats(i);
    bc_inds = cat_inds(:,i);
    beh_inds = RawAnnotations(bc_inds, 1:2);
    HandScore.(b{1}).Bouts = table2array(beh_inds);
    
    if exist('total_mini_frames')
        
        HandScore.(b{1}).Vector = zeros(1, total_mini_frames);
        
        bounds_test = HandScore.(b{1}).Bouts > total_mini_frames;
        to_delete = (sum(bounds_test, 2) > 0);
        HandScore.(b{1}).Bouts(to_delete, :) = [];
        
        for ii = 1:size(HandScore.(b{1}).Bouts, 1)
            bouts = HandScore.(b{1}).Bouts;
            HandScore.(b{1}).Vector(bouts(ii,1):bouts(ii,2)) = 1;
        end
    end
end

% Make vectors for each behavior






