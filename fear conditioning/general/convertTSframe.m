%% goal is to align cue times to frame numbers

%manual vid info
fps = 39; %vid fps
ts_vid = [2021 01 11 12 18 20]; % vid start time [YYYY MM DD HH MM SS]

% get timestamps
tone_on = ts_baseline.tone_on;
tone_off = ts_baseline.tone_off;
light_on = ts_baseline.light_on;
light_off = ts_baseline.light_off;

% calculate difference between vid start and timestamp
cds = @calcDifSeconds;

tone_on_elapsed = cds(ts_vid, tone_on);
tone_off_elapsed = cds(ts_vid, tone_on);
light_on_elapsed = cds(ts_vid, light_on);
light_off_elapsed = cds(ts_vid, light_off);

tone_on_ef = tone_on_elapsed * fps;
tone_off_ef = tone_off_elapsed * fps;
light_on_ef = light_on_elapsed * fps;
light_off_ef = light_off_elapsed * fps;
