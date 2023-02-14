
x = [];
y = [];
for i = 1:6
    x = [x; tone_onoff(i,:)];
    y = [y; -1 6];
end

figure; plot(zsig(68,:), 'b');

for i = 1:6 
   patch([x(i,1) x(i,2) x(i,2) x(i,1)], [0 0 69 69], [0.5 0.5 0.5], 'FaceAlpha', 0.3, 'EdgeAlpha', 0)
end

figure; 
hold on
plot(roc(:,1,68), roc(:,2,68), 'r', 'LineWidth', 1);
plot(roc(:,1,64), roc(:,2,64), 'b', 'LineWidth', 1);
plot(roc(:,1,50), roc(:,2,50), 'k', 'LineWidth', 1);