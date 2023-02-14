% create table to identify cell functional properties
% 0 = no effect; 1 = excited; 2 = suppressed
nn = size(dff,1);
d = 'd1';
cell_id = 1:nn;
cell_id = cell_id';
freeze = zeros(nn,1);
tone = freeze;
platform = freeze;
tone_platform = freeze;
tone_freeze = freeze;
platform_freeze = freeze;


freeze(d0.freeze.excited) = 1;
freeze(d0.freeze.suppressed) = 2;
tone(d0.tone.excited) = 1;
tone(d0.tone.suppressed) = 2;
platform(d0.platform.excited) = 1;
platform(d0.platform.suppressed) = 2;
tone_platform(d0.tone_platform.excited) = 1;
tone_platform(d0.tone_platform.suppressed) = 2;
tone_freeze(d0.tone_freeze.excited) = 1;
tone_freeze(d0.tone_freeze.suppressed) = 2;
platform_freeze(d0.platform_freeze.excited) = 1;
platform_freeze(d0.platform_freeze.suppressed) = 2;


d0_table = table(cell_id, freeze, tone, platform, tone_freeze, platform_freeze);
