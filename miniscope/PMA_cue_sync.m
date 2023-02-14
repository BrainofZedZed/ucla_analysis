%convert timing of cues into seconds from start of day]
disp('Select Cue Onset file')
[f p] = uigetfile;  %load 'Cue_Onset' var from PMA file
load([p f]);

fps = 30;  %fps of miniscope recording
ds = 1;  % factor by which calcium analysis is downsampled
tone_time = 30;  % length of tone (s)


num_sec_per_day = 86400;
cue_times_hms = {'11:46:26.5'; '11:48:49.3'; '11:50:18.3'; '11:52:42.3'; '11:54:46.4'; '11:56:13.4'};
time_fraction_day = datenum(cue_times_hms);
cue_times = time_fraction_day * num_sec_per_day;

beh_start_hms = {'11:44:38'};  %time the behavior camera starts
cue_fraction_day = datenum(beh_start_hms);
beh_start = cue_fraction_day * num_sec_per_day;

beh_start_offset = 0;  % offset between system clocks of behavior and PMA computers **currently ignores small jitter between them**
beh_start = beh_start - beh_start_offset;

cue_times_elapsed = cue_times - beh_start;  % time (s) from start of behavior that tones occur
cue_times_elapsed = cue_times_elapsed * 1000;  %convert from (s) to (ms), same as timestamp
disp('Select miniscope timestamp file')
[f p] = uigetfile;  % point to timestamp file for behavior cam
ts = readmatrix([p f]);
ts = ts(2:end,:);

match = zeros(size(cue_times_elapsed));  % go through the cue times and find the smallest difference between frame timestamp and cue time. Save those frames at match
for i = 1:size(cue_times_elapsed,1)
    dif = ts(:,2)- cue_times_elapsed(i);
    [~, ind] = min(abs(dif));
    match(i) = ind;
end


tone_onoff = [match, (match+(tone_time*fps))];
tone_onoff_ds = round(tone_onoff/ds);

sig = readmatrix('PMA_Ret_traces.csv');

caplot(sig)
for i = 1:length(cue_times)
    xline(tone_onoff(i,1), ':');
    xline(tone_onoff(i,2), ':');
end

