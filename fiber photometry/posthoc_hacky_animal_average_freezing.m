% for zf2
dp066_d1_rows = [45:98];
dp066_d2_rows = [99:132];
dp066_d3_rows = [133:160];
dp068_d1_rows = [1:57];
dp068_d2_rows = [58:97];
dp068_d3_rows = [98:149];
dp069_d1_rows = [200:220];
dp069_d2_rows = [221:243];
dp069_d3_rows = [244:255];
dp088_d1_rows = [1:38];
dp088_d2_rows = [39:117];
dp088_d3_rows = [118:168];
dp090_d1_rows = [170:186];
dp090_d2_rows = [187:243];
dp090_d3_rows = [245:299];
dp091_d1_rows = [300:334];
dp091_d2_rows = [335:425];
dp091_d3_rows = [426:525];

%%

dp066_d1_frz_on = zf2_onset_out(dp066_d1_rows,:);
dp066_d2_frz_on = zf2_onset_out(dp066_d2_rows,:);
dp066_d3_frz_on = zf2_onset_out(dp066_d3_rows,:);

dp066_d1_frz_off = zf2_offset_out(dp066_d1_rows,:);
dp066_d2_frz_off = zf2_offset_out(dp066_d2_rows,:);
dp066_d3_frz_off = zf2_offset_out(dp066_d3_rows,:);

dp066_frz_on = [dp066_d1_frz_on; dp066_d2_frz_on; dp066_d3_frz_on];
dp066_frz_off = [dp066_d1_frz_off; dp066_d2_frz_off; dp066_d3_frz_off];

%%

dp068_d1_frz_on = zf2_onset_out(dp068_d1_rows,:);
dp068_d2_frz_on = zf2_onset_out(dp068_d2_rows,:);
dp068_d3_frz_on = zf2_onset_out(dp068_d3_rows,:);

dp068_d1_frz_off = zf2_offset_out(dp068_d1_rows,:);
dp068_d2_frz_off = zf2_offset_out(dp068_d2_rows,:);
dp068_d3_frz_off = zf2_offset_out(dp068_d3_rows,:);

dp068_frz_on = [dp068_d1_frz_on; dp068_d2_frz_on; dp068_d3_frz_on];
dp068_frz_off = [dp068_d1_frz_off; dp068_d2_frz_off; dp068_d3_frz_off];

%%
dp069_d1_frz_on = zf2_onset_out(dp069_d1_rows,:);
dp069_d2_frz_on = zf2_onset_out(dp069_d2_rows,:);
dp069_d3_frz_on = zf2_onset_out(dp069_d3_rows,:);

dp069_d1_frz_off = zf2_offset_out(dp069_d1_rows,:);
dp069_d2_frz_off = zf2_offset_out(dp069_d2_rows,:);
dp069_d3_frz_off = zf2_offset_out(dp069_d3_rows,:);

dp069_frz_on = [dp069_d1_frz_on; dp069_d2_frz_on; dp069_d3_frz_on];
dp069_frz_off = [dp069_d1_frz_off; dp069_d2_frz_off; dp069_d3_frz_off];

%%
dp088_d1_frz_on = zf2_onset_out(dp088_d1_rows,:);
dp088_d2_frz_on = zf2_onset_out(dp088_d2_rows,:);
dp088_d3_frz_on = zf2_onset_out(dp088_d2_rows,:);

dp088_d1_frz_off = zf2_offset_out(dp088_d1_rows,:);
dp088_d2_frz_off = zf2_offset_out(dp088_d2_rows,:);
dp088_d3_frz_off = zf2_offset_out(dp088_d3_rows,:);

dp088_frz_on = [dp088_d1_frz_on; dp088_d2_frz_on; dp088_d3_frz_on];
dp088_frz_off = [dp088_d1_frz_off; dp088_d2_frz_off; dp088_d3_frz_off];

%%

dp090_d1_frz_on = zf2_onset_out(dp090_d1_rows,:);
dp090_d2_frz_on = zf2_onset_out(dp090_d2_rows,:);
dp090_d3_frz_on = zf2_onset_out(dp090_d3_rows,:);

dp090_d1_frz_off = zf2_offset_out(dp090_d1_rows,:);
dp090_d2_frz_off = zf2_offset_out(dp090_d2_rows,:);
dp090_d3_frz_off = zf2_offset_out(dp090_d3_rows,:);

dp090_frz_on = [dp090_d1_frz_on; dp090_d2_frz_on; dp090_d3_frz_on];
dp090_frz_off = [dp090_d1_frz_off; dp090_d2_frz_off; dp090_d3_frz_off];
%%

dp091_d1_frz_on = zf2_onset_out(dp091_d1_rows,:);
dp091_d2_frz_on = zf2_onset_out(dp091_d2_rows,:);
dp091_d3_frz_on = zf2_onset_out(dp091_d3_rows,:);

dp091_d1_frz_off = zf2_offset_out(dp091_d1_rows,:);
dp091_d2_frz_off = zf2_offset_out(dp091_d2_rows,:);
dp091_d3_frz_off = zf2_offset_out(dp091_d3_rows,:);

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
