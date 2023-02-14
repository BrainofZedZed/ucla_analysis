%% manual load 
% load Metrics, Behavior_Filter

%% analyze distance 

[dvec, dsum] = calcLocDist(Metrics.Location);
dvec = dvec/26;
dsum = dsum/26;
lasertimes = Behavior_Filter.Temporal.laser.EventBouts;
lasertimes(:,2) = lasertimes(:,1) + 1500;
%%
%lasertimes = lasertimes(2:end,:);
lasertimes(1,1) = lasertimes(1,1) + 100;
lasertimes(1,2) = lasertimes(1,2) + 100;
%%
laserdur = lasertimes(1,2) - lasertimes(1,1);

priortimes = lasertimes-laserdur*2;

% sum distance vector during laser times
dist_laser = zeros(1,length(lasertimes));
for i = 1:length(lasertimes)
    dist_laser(i) = sum(dvec(lasertimes(i,1):lasertimes(i,2)));
end
avg_dist_laser = mean(dist_laser);

% sum distance vector prior to laser
dist_prior = zeros(1,length(priortimes));
for i = 1:length(priortimes)
    dist_prior(i) = sum(dvec(priortimes(i,1):priortimes(i,2)));
end
avg_dist_prior = mean(dist_prior);

dist_laser2 = dist_laser';
dist_prior2 = dist_prior';

parallelcoords([dist_prior2, dist_laser2],'Labels',{'Prior', 'Laser'});
xlim([0.9 2.1]);
ylabel('Distance moved (cm)')
title('Effect of light on distance moved')
hold on
scatter(1,avg_dist_prior,250,'black', 'filled')
scatter(2,avg_dist_laser,250,'black', 'filled')
%savefig('light_distance.fig');

dist_laser = [dist_prior2, dist_laser2];
%% analyze freezing
laser_freeze = cell2mat(Behavior_Filter.Temporal.laser.Freezing.PerBehDuringCue);
avg_lf = mean(laser_freeze);
frzvec = Behavior.Freezing.Vector;
prior_freeze = [];
for i = 1:length(priortimes)
    prior_freeze(i) = mean(frzvec(priortimes(i,1):priortimes(i,2)));
end
avg_pf = mean(prior_freeze);
lf = laser_freeze';

%%
%lf = lf(1:4);
%%
pf = prior_freeze';
figure;
parallelcoords([pf, lf], 'Labels', {'Prior','Laser'});
xlim([0.9 2.1]);
ylabel('% freezing during interval')
title('Effect of light on freezing')
hold on
scatter(1,avg_pf,250,'black', 'filled')
scatter(2,avg_lf,250,'black', 'filled')
%savefig('light_freezing.fig');

freeze_laser = [pf, lf];
dist_freeze = [dist_laser, freeze_laser];
out_avg = mean(dist_freeze,1);