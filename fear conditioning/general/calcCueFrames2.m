% goal:  take timestamps and make them into cue files
% works for avi and mp4 vids

%function outfile ts2cue(indir)
% load experiment data
data = dir('*.mat');
load([data.folder '\' data.name]);

% get name of vid file
vid = dir('*.avi');
if isempty(vid)
    vid = dir('*.mp4');
end

% load vid file and get frame rate
thisvid = VideoReader([vid.folder '\' vid.name])';
fps = thisvid.framerate;


dt = regexp(vid.name,'....-..-..-......');
dt = vid.name(dt:dt+16);
d1 = string(dt(1:4));
d2 = string(dt(6:7));
d3 = string(dt(9:10));
d4 = string(dt(12:13));
d5 = string(dt(14:15));
d6 = string(dt(16:17));
vid0 = [d1, d2, d3, d4, d5, d6];

if isequal(cs_plus,"tone")
% find time dif for CS+ and convert to frames
    csm_frames = zeros(size(ts.csm_on,1),2);
    for i = 1:size(ts_baseline.light_on,1)
        csm_frames(i,1) = calcDifSeconds(vid0,ts_baseline.light_on(i,:));
        csm_frames(i,2) = calcDifSeconds(vid0,ts_baseline.light_off(i,:));
    end
    csm_frames = csm_frames * fps;
    csm_frames = round(csm_frames);
    meandif = round(mean(csm_frames(:,2) - csm_frames(:,1)));
    csm_frames = [csm_frames(:,1), csm_frames(:,1)+meandif];
    writematrix(csm_frames, 'CSm_cue_frames.csv');

% find time dif for CS- and convert to frames
    csp_frames = zeros(size(ts.csp_on,1),2);
    for i = 1:size(ts_baseline.tone_on,1)
        csp_frames(i,1) = calcDifSeconds(vid0,ts_baseline.tone_on(i,:));
        csp_frames(i,2) = calcDifSeconds(vid0,ts_baseline.tone_off(i,:));
    end
    csp_frames = csp_frames * fps;
    csp_frames = round(csp_frames);
    meandif = round(mean(csp_frames(:,2) - csp_frames(:,1)));
    csp_frames = [csp_frames(:,1), csp_frames(:,1)+meandif];
    writematrix(csp_frames, 'CSp_cue_frames.csv');
end

%% for light cs plus
if isequal(cs_plus, "light")
    % find time dif for CS+ and convert to frames
    csp_frames = zeros(size(ts.csp_on,1),2);
    for i = 1:size(ts_baseline.light_on,1)
        csp_frames(i,1) = calcDifSeconds(vid0,ts_baseline.light_on(i,:));
        csp_frames(i,2) = calcDifSeconds(vid0,ts_baseline.light_off(i,:));
    end
    csp_frames = csp_frames * fps;
    csp_frames = round(csp_frames);
    meandif = round(mean(csp_frames(:,2) - csp_frames(:,1)));
    csp_frames = [csp_frames(:,1), csp_frames(:,1)+meandif];
    writematrix(csp_frames, 'CSp_cue_frames.csv');

% find time dif for CS- and convert to frames
    csm_frames = zeros(size(ts.csm_on,1),2);
    for i = 1:size(ts_baseline.tone_on,1)
        csm_frames(i,1) = calcDifSeconds(vid0,ts_baseline.tone_on(i,:));
        csm_frames(i,2) = calcDifSeconds(vid0,ts_baseline.tone_off(i,:));
    end
    csm_frames = csm_frames * fps;
    csm_frames = round(csm_frames);
    meandif = round(mean(csm_frames(:,2) - csm_frames(:,1)));
    csm_frames = [csm_frames(:,1), csm_frames(:,1)+meandif];
    writematrix(csm_frames, 'CSm_cue_frames.csv');
end

%%
% find time dif for US and convert to frames
if ~isempty(ts.us_on)
    us_frames = zeros(size(ts.us_on,1),2);
    for i = 1:size(ts.us_on,1)
        us_frames(i,1) = calcDifSeconds(vid0,ts.us_on(i,:));
        us_frames(i,2) = calcDifSeconds(vid0,ts.us_off(i,:));
    end
    us_frames = us_frames * fps;
    us_frames = round(us_frames);
    writematrix(us_frames,'US_cue_frames.csv');
else
    us_frames = [];
end