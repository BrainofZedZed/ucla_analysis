% for zf2
dp066_d1_rows = [249:264]; % good
dp066_d2_rows = [265:279]; % good 
dp066_d3_rows = [280:307]; % good
dp068_d1_rows = [1:17]; % good
dp068_d2_rows = [18:54]; % good
dp068_d3_rows = [55:91]; % good
dp069_d1_rows = [92:111]; % good
dp069_d2_rows = [112:143]; % good
dp069_d3_rows = [144:193]; % good
dp088_d1_rows = [308:328]; % good
dp088_d2_rows = [329:350]; % good
dp088_d3_rows = [351:378]; % good
dp090_d1_rows = [376:394]; % good
dp090_d2_rows = [395:403]; % good
dp090_d3_rows = [404:410]; % good
dp091_d1_rows = [411]; % good
dp091_d2_rows = [412]; % good
dp091_d3_rows = []; % good

%%

dp066_d1_frz_on = z_entry_all(dp066_d1_rows,:);
dp066_d2_frz_on = z_entry_all(dp066_d2_rows,:);
dp066_d3_frz_on = z_entry_all(dp066_d3_rows,:);

dp066_d1_frz_off = z_exit_all(dp066_d1_rows,:);
dp066_d2_frz_off = z_exit_all(dp066_d2_rows,:);
dp066_d3_frz_off = z_exit_all(dp066_d3_rows,:);

dp066_frz_on = [dp066_d1_frz_on; dp066_d2_frz_on; dp066_d3_frz_on];
dp066_frz_off = [dp066_d1_frz_off; dp066_d2_frz_off; dp066_d3_frz_off];

%%

dp068_d1_frz_on = z_entry_all(dp068_d1_rows,:);
dp068_d2_frz_on = z_entry_all(dp068_d2_rows,:);
dp068_d3_frz_on = z_entry_all(dp068_d3_rows,:);

dp068_d1_frz_off = z_exit_all(dp068_d1_rows,:);
dp068_d2_frz_off = z_exit_all(dp068_d2_rows,:);
dp068_d3_frz_off = z_exit_all(dp068_d3_rows,:);

dp068_frz_on = [dp068_d1_frz_on; dp068_d2_frz_on; dp068_d3_frz_on];
dp068_frz_off = [dp068_d1_frz_off; dp068_d2_frz_off; dp068_d3_frz_off];

%%
dp069_d1_frz_on = z_entry_all(dp069_d1_rows,:);
dp069_d2_frz_on = z_entry_all(dp069_d2_rows,:);
dp069_d3_frz_on = z_entry_all(dp069_d3_rows,:);

dp069_d1_frz_off = z_exit_all(dp069_d1_rows,:);
dp069_d2_frz_off = z_exit_all(dp069_d2_rows,:);
dp069_d3_frz_off = z_exit_all(dp069_d3_rows,:);

dp069_frz_on = [dp069_d1_frz_on; dp069_d2_frz_on; dp069_d3_frz_on];
dp069_frz_off = [dp069_d1_frz_off; dp069_d2_frz_off; dp069_d3_frz_off];

%%
dp088_d1_frz_on = z_entry_all(dp088_d1_rows,:);
dp088_d2_frz_on = z_entry_all(dp088_d2_rows,:);
dp088_d3_frz_on = z_entry_all(dp088_d2_rows,:);

dp088_d1_frz_off = z_exit_all(dp088_d1_rows,:);
dp088_d2_frz_off = z_exit_all(dp088_d2_rows,:);
dp088_d3_frz_off = z_exit_all(dp088_d3_rows,:);

dp088_frz_on = [dp088_d1_frz_on; dp088_d2_frz_on; dp088_d3_frz_on];
dp088_frz_off = [dp088_d1_frz_off; dp088_d2_frz_off; dp088_d3_frz_off];

%%

dp090_d1_frz_on = z_entry_all(dp090_d1_rows,:);
dp090_d2_frz_on = z_entry_all(dp090_d2_rows,:);
dp090_d3_frz_on = z_entry_all(dp090_d3_rows,:);

dp090_d1_frz_off = z_exit_all(dp090_d1_rows,:);
dp090_d2_frz_off = z_exit_all(dp090_d2_rows,:);
dp090_d3_frz_off = z_exit_all(dp090_d3_rows,:);

dp090_frz_on = [dp090_d1_frz_on; dp090_d2_frz_on; dp090_d3_frz_on];
dp090_frz_off = [dp090_d1_frz_off; dp090_d2_frz_off; dp090_d3_frz_off];
%%

dp091_d1_frz_on = z_entry_all(dp091_d1_rows,:);
dp091_d2_frz_on = z_entry_all(dp091_d2_rows,:);
dp091_d3_frz_on = z_entry_all(dp091_d3_rows,:);

dp091_d1_frz_off = z_exit_all(dp091_d1_rows,:);
dp091_d2_frz_off = z_exit_all(dp091_d2_rows,:);
dp091_d3_frz_off = z_exit_all(dp091_d3_rows,:);

dp091_frz_on = [dp091_d1_frz_on; dp091_d2_frz_on; dp091_d3_frz_on];
dp091_frz_off = [dp091_d1_frz_off; dp091_d2_frz_off; dp091_d3_frz_off];

%%

dp066_frz_on_avg = mean(dp066_frz_on,1);
dp068_frz_on_avg = mean(dp068_frz_on,1);
dp069_frz_on_avg = mean(dp069_frz_on,1);
dp088_frz_on_avg = mean(dp088_frz_on,1);
dp090_frz_on_avg = mean(dp090_frz_on,1);
dp091_frz_on_avg = mean(dp091_frz_on,1);

dp066_frz_off_avg = mean(dp066_frz_off,1);
dp068_frz_off_avg = mean(dp068_frz_off,1);
dp069_frz_off_avg = mean(dp069_frz_off,1);
dp088_frz_off_avg = mean(dp088_frz_off,1);
dp090_frz_off_avg = mean(dp090_frz_off,1);
dp091_frz_off_avg = mean(dp091_frz_off,1);

frz_on_avg = [dp066_frz_on_avg; dp068_frz_on_avg; dp069_frz_on_avg; dp088_frz_on_avg; dp090_frz_on_avg; dp091_frz_on_avg];
frz_off_avg = [dp066_frz_off_avg; dp068_frz_off_avg; dp069_frz_off_avg; dp088_frz_off_avg; dp090_frz_off_avg; dp091_frz_off_avg];

%% plot and quantify
pf_on_offset = mean(frz_on_avg(:,100:150),2);
pf_on_avg = frz_on_avg - pf_on_offset;

pf_off_offset = mean(frz_off_avg(:,100:150),2);
pf_off_avg = frz_off_avg - pf_off_offset;


figure;
hold on;
plot(pf_on_avg', 'Color', [0.5, 0.5, 0.5]);
plot(mean(pf_on_avg,1),'Color',[1,0,0],'LineWidth',2);
xlim([100 300]);
ylim([-1 1]);
xline(200)
title('animal average platform on');
ylabel('DA response (zscore)')
xlabel('frames at 50fps')


figure;
hold on;
plot(pf_off_avg', 'Color', [0.5, 0.5, 0.5]);
plot(mean(pf_off_avg,1),'Color',[1,0,0],'LineWidth',2);
xlim([100 300]);
xline(200)
title('animal average platform off');
ylabel('DA response (zscore)')
xlabel('frames at 50fps')

%% numbers
pf_on_pre = mean(pf_on_avg(:,100:124),2);
pf_on_event = mean(pf_on_avg(:,165:190),2);
pf_on_post = mean(pf_on_avg(:,275:300),2);
pf_on_quant = [pf_on_pre, pf_on_event, pf_on_post];

pf_off_pre = mean(pf_off_avg(:,100:124),2);
pf_off_event = mean(pf_off_avg(:,165:190),2);
pf_off_post = mean(pf_off_avg(:,275:300),2);
pf_off_quant = [pf_off_pre, pf_off_event, pf_off_post];

