id = 'ZZ189 tonehab CS+';
 
laser_off = [1,3];
laser_on = [2,4];

zsig_laseroff = zall(laser_off,:);
zsig_laseron = zall(laser_on,:);

avg_off = mean(zsig_laseroff,1);
avg_on = mean(zsig_laseron,1);

figure; 
plot(zall(1,:), 'Color', 'k'); hold on;
plot(zall(3,:), 'Color', [0.5, 0.5, 0.5]); %gray
plot(zall(2,:), 'Color', 'r');  % red
plot(zall(4,:), 'Color', [1, 0.5, 0.5']); % light red
xline((P2.fp_fps*P2.trange_peri_bout(1)), ':', 'LineWidth', 2);
xline((length(zall)-(P2.fp_fps*P2.trange_peri_bout(2))), ':', 'LineWidth', 2);
legend('Laser Off', 'Laser Off', 'Laser On', 'Laser On', 'Tone On', 'Tone Off');
xlabel('frames at 102 fps');
ylabel('sig (zscore)');
hold off;
title(id);
savefig('tone_response_laser.fig');

%%
P2.fp_fps*P2.trange_peri_bout(1);
t0 = P2.fp_fps*P2.trange_peri_bout(1);
peaks_trial = max(zall(:,t0:t0+2*P2.fp_fps)');

figure;
scatter([1,1],[peaks_trial(1,[1,3])],'black', 'filled'); hold on;
scatter([2,2],[peaks_trial(1,[2,4])],'red','filled');
xlim([0 3]);
xticks([1,2]);
xticklabels({'Laser Off', 'Laser On'});
ylabel('Peak response (zscore)');
title(id);
savefig('peak_response_laser.fig');