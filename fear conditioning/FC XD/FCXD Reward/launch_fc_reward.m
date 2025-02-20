% Version 1.5.1
% last update:  2022 10 18
% integrated reward pump and reward port light
% Fear conditioning script
% started ZZ 5/13/21
% Goal:  make fear conditioning script to work with modern MATLAB Arduino
% interface, and provide way to also do light cue

% hardware setup on arduino:  pin 4 - shock, pin 3 - CS+, pin 5, CS- , 
% pin 6 - laser, pin 7 - light, pin 13, miniscope trigger
%% setup params
% experiment structure
function launch_fc_reward(P)
% SET MANUAL AUDIO API 
% if manual_audio set to 0, triese to identify correct device
% use PsychPortAudio('GetDevices') to find device ID for preferred WASAPI
% API speaker
manual_audio = 0;
if manual_audio
    devID = 7;
end

% load params
a = P.a;
exp_ID = P.exp_ID;
cs_plus = P.cs_plus;
cs_minus = P.cs_minus;

t_baseline = P.t_baseline; % (s) baseline time before use

min_trial_int = P.min_trial_int;  % (s)
max_trial_int = P.max_trial_int;  % (s)

reward_dur = P.reward_dur;


% tone settings
tone_freq1 = P.tone_freq1; %(hz) for pure tone
tone_freq2 = P.tone_freq2;

start_freq1 = P.start_freq1; % f0 for FM sweep
start_freq2 = P.start_freq2;
end_freq1 = P.end_freq1; % f_end for FM sweep
end_freq2 = P.end_freq2;
sweep_dur = P.sweep_dur; %(s) duration of sweep, repeated over cs_dur.  NB must evenly divide with cs_dur


% light settings
flicker_freq1 = P.flicker_freq1 ;% (hz) from on to off to back on again
flicker_freq2 = P.flicker_freq2;
light_dc1 = P.light_dc1; %duty cycle of light (0.5 = 50% duty cycle)
light_dc2 = P.light_dc2;

% get CS+ and CS- params
if isequal(cs_plus,'Tone1')
    csp_p.tone_freq = tone_freq1;
    csp_p.name = "Tone";
elseif isequal(cs_plus,'Tone2')
    csp_p.tone_freq = tone_freq2;
    csp_p.name = "Tone";
elseif isequal(cs_plus,'FM Sweep1')
    csp_p.start_freq = start_freq1;
    csp_p.end_freq = end_freq1;
    csp_p.sweep_dur = sweep_dur;
    csp_p.name = "FM";
elseif isequal(cs_plus,'FM Sweep2')
    csp_p.start_freq = start_freq2;
    csp_p.end_freq = end_freq2;
    csp_p.sweep_dur = sweep_dur;
    csp_p.name = "FM";
elseif isequal (cs_plus, 'Light')
    csp_p = [];
    csp_p.name = 'Light';
elseif isequal(cs_plus, 'Pulsed Light1')
    csp_p.flicker_freq = flicker_freq1;
    csp_p.light_dc = light_dc1;
    csp_p.name = 'Pulsed Light';
elseif isequal(cs_plus, 'Pulsed Light2')
    csp_p.flicker_freq = flicker_freq2;
    csp_p.light_dc = light_dc2;
    csp_p.name = 'Pulsed Light';
end

% do cs_minus
if isequal(cs_minus,'Tone1')
    csm_p.tone_freq = tone_freq1;
    csm_p.name = "Tone";
elseif isequal(cs_minus,'Tone2')
    csm_p.tone_freq = tone_freq2;
    csm_p.name = "Tone";
elseif isequal(cs_minus,'FM Sweep1')
    csm_p.start_freq = start_freq1;
    csm_p.end_freq = end_freq1;
    csm_p.sweep_dur = sweep_dur;
    csm_p.name = "FM";
elseif isequal(cs_minus,'FM Sweep2')
    csm_p.start_freq = start_freq2;
    csm_p.end_freq = end_freq2;
    csm_p.sweep_dur = sweep_dur;
    csm_p.name = "FM";
elseif isequal(cs_minus, 'Light')
    csm_p = [];
    csm_p.name = 'Light';
elseif isequal(cs_minus, 'Pulsed Light1')
    csm_p.flicker_freq = flicker_freq1;
    csm_p.light_dc = light_dc1;
    csm_p.name = 'Pulsed Light';
elseif isequal(cs_minus, 'Pulsed Light2')
    csm_p.flicker_freq = flicker_freq2;
    csm_p.light_dc = light_dc2;
    csm_p.name = 'Pulsed Light';
end

% cs and us settings
cs_dur = P.cs_dur;  % (s)
us_dur = P.us_dur;


xd = P.expdesign;
xd_labels = ["CS+";"CS-";"Shock";"Laser";"Reward"];


%% initialization
tonep_csp = 'D3';  %tonepin for CS+
tonep_csm = 'D5'; %tonepin for CS-
tonep = tonep_csp; %default to CS+
shockp = 'D4';  %shockpin
lightp = 'D7';  %lightpin
optop = 'D6'; % opto pin
minip = 'D13'; % pin to trigger miniscipe
rewardp = 'D9'; % pin to trigger reward !!NB on is low, off is high
reward_lightp = 'D10';

pins.tonep_csp = tonep_csp;
pins.tonep_csm = tonep_csm;
pins.tonep = tonep;
pins.shockp = shockp;
pins.lightp = lightp;
pins.optop = optop;
pins.minip = minip;
pins.rewardp = rewardp;
pins.reward_lightp = reward_lightp;

int_range = [min_trial_int, max_trial_int];

ts = struct;
ts.csp_on = [];  
ts.csp_off = [];
ts.csm_on = [];  
ts.csm_off = [];
ts.us_on = [];
ts.us_off = [];
ts.laser_on = [];
ts.laser_off = [];
ts.miniscope_on = [];
ts.miniscope_off = [];
ts.reward_on = [];
ts.reward_off = [];

global first_csp;
global first_csm;
global pahandle;
InitializePsychSound(1); % from psychtoolbox, for low latency sound delivery

first_csp = 1;  % used to create wav file for low latency audio presentation
first_csm = 1;

%% initialize audio device
audio_devices = PsychPortAudio('GetDevices');
if ~manual_audio
for i = 1:size(audio_devices,2)
    if audio_devices(i).HostAudioAPIName == "Windows WASAPI"
        devID = i-1;
        disp(['Using ' audio_devices(devID).DeviceName 'with Windows WASAPI API']);
        disp('if different speakers desired, edit manual_audio and devID at top of launch_fc.m function');
        break
    end
end
end
pahandle = PsychPortAudio('Open',devID); % open audio device NB: must be WASAPI audio subsystem, see PsychPortAudio('GetDevices') for device index 


%% trigger miniscope
if P.doMiniscope
    a.writeDigitalPin(minip, 1);
    ts.miniscope_on = clock;
    disp('Miniscope recording initiated')
end

%% trigger PointGray
% save to memory and disk to extract timestamps
if P.run_PG
    P.vid.LoggingMode = 'disk';
    time = datestr(clock,'YYYY-mm-dd_HH-MM-SS');
    savenamepg = [exp_ID '_camera_' time '.avi'];
    diskLogger = VideoWriter(savenamepg, 'Motion JPEG AVI');
    diskLogger.FrameRate = 50;
    diskLogger.Quality = 75;
    P.vid.DiskLogger = diskLogger;

    ts.camera_on = clock;
    start(P.vid);
    disp('Pointgray vid started with Zachs default settings');
end

%% baseline
if t_baseline > 0
    disp(['baseline period. No stimulus presentations for ' num2str(t_baseline) ' seconds'])
    pause(t_baseline)
end

%% do presentations
% presentation are decoded from the four digit code in xd, indicating which
% cs, if shock, and if laser. For each combination of cs, shock, and laser,
% there is a specific function

first = 1; % skip ITI for first run

disp('Now doing events')
    for i = 1:size(xd,2)
        
        % on first run, skip ITI
        if first == 0
            pause(randi(int_range));
        elseif first == 1
            first = 0;
        end
        disp(['Now doing event #' num2str(i)]);
        this = xd(:,i);
        if isequal(this,[1;0;0;0;0])
            tonep = tonep_csp;
            reward_flag=0;
            ts = doStim('csp', csp_p, a, tonep, lightp, cs_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;0;0;0])
            tonep = tonep_csm;
            reward_flag=0;
            ts = doStim('csm', csm_p, a, tonep, lightp, cs_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;1;0;0])
            tonep = tonep_csp;
            reward_flag=0;
            ts = doStimShock('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);  
        elseif isequal(this,[0;1;1;0;0])
            tonep = tonep_csm;
            reward_flag=0;
            ts = doStimShock('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;0;1;0])
            tonep = tonep_csp;
            reward_flag=0;
            ts = doStimLaser('csp', csp_p, a, tonep, lightp, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;0;1;0])
            tonep = tonep_csm;
            reward_flag=0;
            ts = doStimLaser('csm', csm_p, a, tonep, lightp, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;1;1;0])
            tonep = tonep_csp;
            reward_flag=0;
            ts = doStimShockLaser('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;1;1;0])
            tonep = tonep_csm;
            reward_flag=0;
            ts = doStimShockLaser('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[2;2;0;1;0])
            reward_flag=0;
            ts = doLaser(a, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this, [2;2;1;0;0])
            reward_flag=0;
            ts = doShock(a, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this, [2;2;1;1;0])
            reward_flag=0;
            ts = doLaserShock(a, shockp, optop, cs_dur, us_dur, ts, reward_flag, rewardp, pins);

        % copy of everything with reward on
        elseif isequal(this,[2;2;0;0;1])
            ts = doReward(a, ts, rewardp, reward_dur, pins);
        elseif isequal(this,[1;0;0;0;1])
            tonep = tonep_csp;
            reward_flag=1;
            ts = doStim('csp', csp_p, a, tonep, lightp, cs_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;0;0;1])
            tonep = tonep_csm;
            reward_flag=1;
            ts = doStim('csm', csm_p, a, tonep, lightp, cs_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;1;0;1])
            tonep = tonep_csp;
            reward_flag=1;
            ts = doStimShock('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);  
        elseif isequal(this,[0;1;1;0;1])
            tonep = tonep_csm;
            reward_flag=1;
            ts = doStimShock('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;0;1;1])
            tonep = tonep_csp;
            reward_flag=1;
            ts = doStimLaser('csp', csp_p, a, tonep, lightp, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;0;1;1])
            tonep = tonep_csm;
            reward_flag=1;
            ts = doStimLaser('csm', csm_p, a, tonep, lightp, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[1;0;1;1;1])
            tonep = tonep_csp;
            reward_flag=1;
            ts = doStimShockLaser('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[0;1;1;1;1])
            tonep = tonep_csm;
            reward_flag=1;
            ts = doStimShockLaser('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this,[2;2;0;1;1])
            reward_flag=1;
            ts = doLaser(a, cs_dur, optop, ts, reward_flag, rewardp, pins);
        elseif isequal(this, [2;2;1;0;1])
            reward_flag=1;
            ts = doShock(a, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins);
        elseif isequal(this, [2;2;1;1;1])
            reward_flag=1;
            ts = doLaserShock(a, shockp, optop, cs_dur, us_dur, ts, reward_flag, rewardp, pins);
        end

        disp(['Done ' num2str(i) ' of ' num2str(size(xd,2)) ' events']);
    end

if P.postHoldTime > 0
    pause(P.postHoldTime);
end
 
if P.doMiniscope
    a.writeDigitalPin(minip, 0);
    ts.miniscope_off = clock;
    disp('Miniscope recording ended')
end

if P.run_PG
    disp('Now saving video. Can be slow (~5min for a 30min video)');
    disp('do not interrupt until "experiment complete" is displayed');
    disp('(no video being recorded. safe to futz with recording area)');
    ts.camera_off = clock;
    stop(P.vid);
    %[~,ts.pg_frames] = getdata(P.vid);
    disp('Point Gray recording ended');
else
    %ts.pg_frames = [];
end
    
disp('experiment complete')

%% post processing
time = datestr(clock,'YYYY-mm-dd_HH-MM-SS');
savevars = {'cs_dur', 'cs_minus', 'cs_plus', 'csm_p', 'csp_p', 'exp_ID', 'min_trial_int', 'max_trial_int', 't_baseline', 'ts', 'us_dur', 'xd', 'xd_labels'};
savename = [exp_ID '_' time '.mat'];
save(savename, savevars{:});
clear;

end
%% functions

function ts = doStim(cs, csP, a, tonep, lightp, cs_dur, ts, reward_flag, rewardp, pins)
%%
    global first_csp
    global first_csm
    if isequal(csP.name, 'Tone')
        if isequal(cs, 'csp')
            if first_csp
                [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                audiowrite('csp.wav',y,Fs);
                first_csp = 0;
            end
            audiotime = psychsound('csp.wav');
        elseif isequal(cs, 'csm')
            if first_csm
                [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                audiowrite('csm.wav',y,Fs);
                first_csm = 0;
            end
            audiotime = psychsound('csm.wav');
        end
        
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
            
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        if reward_flag
            ts.reward_on = [ts.reward_on; clock];
            a.writeDigitalPin(rewardp,0);
            a.writeDigitalPin(pins.reward_lightp,0);

        end
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur);
        a.writeDigitalPin(tonep, 0);
        
        if reward_flag
            ts.reward_off = [ts.reward_off; clock];
            a.writeDigitalPin(rewardp,1);
            a.writeDigitalPin(pins.reward_lightp,1);

        end
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];

        else
            ts.csm_off = [ts.csm_off; clock];
        end
        

%%
    elseif isequal(csP.name, 'FM') 
        %%
        if isequal(cs, 'csp')
            if first_csp
                [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                audiowrite('csp.wav',y,Fs);
                first_csp = 0;
            end
        audiotime = psychsound('csp.wav');
        elseif isequal(cs, 'csm')
            if first_csm
                [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                audiowrite('csm.wav',y,Fs);
                first_csm = 0;
            end
            audiotime = psychsound('csm.wav');
        end
        
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
            if reward_flag
                ts.reward_on = [ts.reward_on; clock];
                a.writeDigitalPin(rewardp,0);
                a.writeDigitalPin(pins.reward_lightp,0);

            end
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur);
        a.writeDigitalPin(tonep, 0);
        if reward_flag
            ts.reward_off = [ts.reward_off; clock];
            a.writeDigitalPin(rewardp,1);
            a.writeDigitalPin(pins.reward_lightp,1);

        end
%%
    elseif isequal(csP.name, 'Light')
        a.writeDigitalPin(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur)
        a.writeDigitalPin(lightp,0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end                
    end
end
%%
function ts = doStimShock(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins)
    global first_csp
    global first_csm
    if isequal(csP.name, 'Tone')
        %%
        if isequal(cs, 'csp')
            if first_csp
                [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                audiowrite('csp.wav',y,Fs);
                first_csp = 0;
            end
            audiotime = psychsound('csp.wav');
        elseif isequal(cs, 'csm')
            if first_csm
                [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                audiowrite('csm.wav',y,Fs);
                first_csm = 0;
            end
            audiotime = psychsound('csm.wav');
        end
        
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        
        if reward_flag
            ts.reward_on = [ts.reward_on; clock];
            a.writeDigitalPin(rewardp,0);
            a.writeDigitalPin(pins.reward_lightp,0);
        end
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur-us_dur);
        a.writeDigitalPin(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        
        a.writeDigitalPin(shockp,0);
        a.writeDigitalPin(tonep, 0);
        
        if reward_flag
            ts.reward_off = [ts.reward_off; clock];
            a.writeDigitalPin(rewardp,1);
            a.writeDigitalPin(pins.reward_lightp,1);

        end
        
        ts.us_off = [ts.us_off; clock];
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
       
%%
    elseif isequal(csP.name, 'FM')
       %%
       if isequal(cs, 'csp')
            if first_csp
                [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                audiowrite('csp.wav',y,Fs);
                first_csp = 0;
            end
        audiotime = psychsound('csp.wav');
        elseif isequal(cs, 'csm')
            if first_csm
                [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                audiowrite('csm.wav',y,Fs);
                first_csm = 0;
            end
        audiotime = psychsound('csm.wav');
       end

        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        
        pause(cs_dur-us_dur);
        
        a.writeDigitalPin(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        
        a.writeDigitalPin(shockp,0);
        a.writeDigitalPin(tonep, 0);
        
        ts.us_off = [ts.us_off; clock];
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%
    elseif isequal(csP.name, 'Light')
        a.writeDigitalPin(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur-us_dur)
        a.writeDigitalPin(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.writeDigitalPin(lightp,0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.writeDigitalPin(shockp,0);
        ts.us_off = [ts.us_off; clock];
%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur-us_dur);
        a.writeDigitalPin(shockp,1);
        ts.us_on = [ts.us_on; clock];
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, us_dur);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end      
        a.writeDigitalPin(shockp,0);
        ts.us_off = [ts.us_off; clock];
    end
end

%%
function ts = doStimLaser(cs, csP, a, tonep, lightp, cs_dur, optop, ts, reward_flag, rewardp, pins)
    global first_csp
    global first_csm    
    a.writeDigitalPin(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    
    if ismember(csP.name, ["Tone", "FM"])
        if isequal(csP.name, 'Tone')
            if isequal(cs, 'csp')
                if first_csp
                    [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                    audiowrite('csp.wav',y,Fs);
                    first_csp = 0;
                end
                audiotime = psychsound('csp.wav');
            elseif isequal(cs, 'csm')
                if first_csm
                    [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                    audiowrite('csm.wav',y,Fs);
                    first_csm = 0;
                end
                audiotime = psychsound('csm.wav');
            end 
          
        elseif isequal(csP.name, 'FM')
            if isequal(cs, 'csp')
                if first_csp
                    [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                    audiowrite('csp.wav',y,Fs);
                    first_csp = 0;
                end
                audiotime = psychsound('csp.wav');
            elseif isequal(cs, 'csm')
                if first_csm
                    [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                    audiowrite('csm.wav',y,Fs);
                    first_csm = 0;
                end
                audiotime = psychsound('csm.wav');
            end
        end

        a.writeDigitalPin(tonep,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        
        if reward_flag
            ts.reward_on = [ts.reward_on; clock];
            a.writeDigitalPin(rewardp,0);
            a.writeDigitalPin(pins.reward_lightp,0);

        end

        pause(cs_dur);

        a.writeDigitalPin(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        
        if reward_flag
            ts.reward_off = [ts.reward_off; clock];
            a.writeDigitalPin(rewardp,1);
            a.writeDigitalPin(pins.reward_lightp,1);

        end
        
    
%%
    elseif isequal(csP.name, 'Light')
        a.writeDigitalPin(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur)
        a.writeDigitalPin(lightp,0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end                
    end
    
    a.writeDigitalPin(optop,0);
    ts.laser_off = [ts.laser_off; clock];
end

%%
function ts = doStimShockLaser(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, reward_flag, rewardp, pins)
    global first_csp
    global first_csm    
    a.writeDigitalPin(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    
    if ismember(csP.name, ["Tone", "FM"])
        if isequal(csP.name, 'Tone')
            if isequal(cs, 'csp')
                if first_csp
                    [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                    audiowrite('csp.wav',y,Fs);
                    first_csp = 0;
                end
                audiotime = psychsound('csp.wav');
            elseif isequal(cs, 'csm')
                if first_csm
                    [y, Fs] = prepSineWave(cs_dur, csP.tone_freq);
                    audiowrite('csm.wav',y,Fs);
                    first_csm = 0;
                end
                audiotime = psychsound('csm.wav');
            end 
          
        elseif isequal(csP.name, 'FM')
            if isequal(cs, 'csp')
                if first_csp
                    [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                    audiowrite('csp.wav',y,Fs);
                    first_csp = 0;
                end
                audiotime = psychsound('csp.wav');
            elseif isequal(cs, 'csm')
                if first_csm
                    [y, Fs] = prepFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
                    audiowrite('csm.wav',y,Fs);
                    first_csm = 0;
                end
                audiotime = psychsound('csm.wav');
            end
        end

        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; audiotime];
        else
            ts.csm_on = [ts.csm_on; audiotime];
        end
        a.writeDigitalPin(tonep,1);
        
        if reward_flag
            ts.reward_on = [ts.reward_on; clock];
            a.writeDigitalPin(rewardp,0);
            a.writeDigitalPin(pins.reward_lightp,0);

        end

        
%%
    elseif isequal(csP.name, 'Light')
        a.writeDigitalPin(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end

%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur);
    end
   %%
    pause(cs_dur-us_dur);

    a.writeDigitalPin(shockp, 1);
    ts.us_on = [ts.us_on; clock];
    pause(us_dur);
    a.writeDigitalPin(shockp, 0);
    a.writeDigitalPin(tonep, 0);
    a.writeDigitalPin(lightp, 0);
    ts.us_off = [ts.us_off; clock];
    if isequal(cs, 'csp')
        ts.csp_off = [ts.csp_off; clock];
    else
        ts.csm_off = [ts.csm_off; clock];
    end
    
    if reward_flag
        ts.reward_off = [ts.reward_off; clock];
        a.writeDigitalPin(rewardp,1);
        a.writeDigitalPin(pins.reward_lightp,1);
    end
    
    a.writeDigitalPin(optop,0);
    ts.laser_off = [ts.laser_off; clock];   
end

%%
function ts = doLaser(a, cs_dur, optop, ts, reward_flag, rewardp, pins)
    a.writeDigitalPin(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    if reward_flag
        ts.reward_on = [ts.reward_on; clock];
        a.writeDigitalPin(rewardp,0);
        a.writeDigitalPin(pins.reward_lightp,0);

    end
    pause(cs_dur);
    a.writeDigitalPin(optop, 0);
    ts.laser_off = [ts.laser_off; clock];
    if reward_flag
        ts.reward_off = [ts.reward_off; clock];
        a.writeDigitalPin(rewardp,1);
        a.writeDigitalPin(pins.reward_lightp,1);

    end
end

%% 
function ts = doShock(a, shockp, cs_dur, us_dur, ts, reward_flag, rewardp, pins)
    if reward_flag
        ts.reward_on = [ts.reward_on; clock];
        a.writeDigitalPin(rewardp,0);
        a.writeDigitalPin(pins.reward_lightp,0);

    end    
    pause(cs_dur-us_dur);
    a.writeDigitalPin(shockp,1);
    ts.us_on = [ts.us_on; clock];
    pause(us_dur);
    a.writeDigitalPin(shockp, 0);
    ts.us_off = [ts.us_off; clock];
    if reward_flag
        ts.reward_off = [ts.reward_off; clock];
        a.writeDigitalPin(rewardp,1);
        a.writeDigitalPin(pins.reward_lightp,1);

    end
end

%%
function ts = doReward(a, ts, rewardp, reward_dur, pins)
    a.writeDigitalPin(rewardp,0);
    a.writeDigitalPin(pins.reward_lightp,0);
    ts.reward_on = [ts.reward_on; clock];
    pause(reward_dur);
    a.writeDigitalPin(rewardp, 1);
    ts.reward_off = [ts.reward_off; clock];
    a.writeDigitalPin(pins.reward_lightp,1);

end
%%
function ts = doLaserShock(a, shockp, optop, cs_dur, us_dur, ts, reward_flag, rewardp, pins)
    if reward_flag
        ts.reward_on = [ts.reward_on; clock];
        a.writeDigitalPin(rewardp,0);
        a.writeDigitalPin(pins.reward_lightp,0);

    end    

    a.writeDigitalPin(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    pause(cs_dur-us_dur);
    a.writeDigitalPin(shockp,1);
    ts.us_on = [ts.us_on; clock];
    pause(us_dur);
    a.writeDigitalPin(shockp, 0);
    ts.us_off = [ts.us_off; clock];
    a.writeDigitalPin(optop, 0);
    ts.laser_off = [ts.laser_off; clock];  

    if reward_flag
        ts.reward_off = [ts.reward_off; clock];
        a.writeDigitalPin(rewardp,1);
        a.writeDigitalPin(pins.reward_lightp,1);

    end
end
%%
function flickerLight(flicker_freq, light_dc, a, lightp, cs_dur)
    count = 0;
    while count < cs_dur
        a.writeDigitalPin(lightp, 1);
        pause((1/flicker_freq)*light_dc);
        a.writeDigitalPin(lightp,0);
        pause((1/flicker_freq)*(1-light_dc));
        count = count + (1/flicker_freq);
    end
end
%%
function [y, Fs] = prepSineWave(cs_dur,tone_freq)
    %  feature to generate filtered white noise
    if tone_freq == 1
        [y, Fs] = prepNoise(cs_dur);
    else
        Fs = 48000;  % sampling freq (hz) NOTE: tone limit is 22 kHz
        Ts = 1/Fs;  % sampling interval (s)
        T = 0:Ts:(Fs*Ts*cs_dur);
        y = sin(2*pi*tone_freq*T); % tone
        %hardcode adjustment to match freq response of 5kHz to 12kHz, based on
        %response profile of Amazon Basics bluetooth speaker
        %if tone_freq == 5000
        %    y=y/10;
        %end
    end
end
%%
function [y_cs, Fs] = prepFMSweep(start_freq, end_freq, sweep_dur, cs_dur)
    Fs = 44100;
    t = 0:1/Fs:sweep_dur;
    f_in_start = start_freq;
    f_in_end = end_freq;
    f_in = linspace(f_in_start, f_in_end, length(t));
    phase_in = cumsum(f_in/Fs);
    y = sin(2*pi*phase_in);
    if sweep_dur ~= 1
        dif = Fs - length(y);
        y = [y, zeros(1,dif)];
    end
    rep = round(cs_dur/1);  % edit this line to include hz in future upload
    y_cs = repmat(y,[1,rep]);
end
%%
function [ywn, Fswn] = prepNoise(cs_dur)
% creates filtered white noise between 5kHz and 10kHz
% modified from MATLAB forum user Star Strider
% https://www.mathworks.com/matlabcentral/answers/324226-hi-could-you-please-help-me-generate-a-white-noise-or-any-kind-of-noise-with-a-given-minimum-and#answer_254109
    Fswn = 44100;                                                     % Sampling Frequency (Hz)
    dur = cs_dur; %s, duration of noise
    fstart = 5000; % hz, filter start
    fstop = 10000; % hz, filter stop
    fcuts = [fstart-100  fstart  fstop  fstop+100];                 % Frequency Vector (Hz)
    mags =   [0 1 0];                                               % Magnitude (Defines Passbands & Stopbands)
    devs = [0.05  0.01  0.05];                                      % Allowable Deviations
    [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fswn);
    n = n + rem(n,2);
    hh = fir1(n,Wn,ftype,kaiser(n+1,beta),'scale');
    s = randn(1, dur*Fswn);                                             % Gaussian White Noise
    %St = 0 : 1/Fswn : (length(s)-1)/Fswn;
    ywn = filtfilt(hh, 1, s);                                     % Filter Signal
    
end
%%
function audiotime = psychsound(wavfilename)
    global pahandle;
    [y, ~] = psychwavread(wavfilename);  % read wav file
    wavedata = y';  % transpose 
    wavedata = [wavedata; wavedata];  % audio devices have 2 output channels; provide stream for both
    PsychPortAudio('FillBuffer', pahandle, wavedata);  % prep the sound 
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    audiotime = clock;
end