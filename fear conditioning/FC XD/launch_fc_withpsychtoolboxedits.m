% Version 1.41
% last update:  2022 05 09
% updated to make timestamps and tones more in line with each other using
% psychtoolbox
% 

% Fear conditioning script
% started ZZ 5/13/21
% Goal:  make fear conditioning script to work with modern MATLAB Arduino
% interface, and provide way to also do light cue

% hardware setup on arduino:  pin 4 - shock, pin 5 - tone/blank, pin 6 - laser,
% pin 7 - light, pin 13, miniscope trigger
%% setup params
% experiment structure
function launch_fc(P)
% load params
a = P.a;
exp_ID = P.exp_ID;
cs_plus = P.cs_plus;
cs_minus = P.cs_minus;

t_baseline = P.t_baseline; % (s) baseline time before use

min_trial_int = P.min_trial_int;  % (s)
max_trial_int = P.max_trial_int;  % (s)


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
xd_labels = ["CS+";"CS-";"Shock";"Laser"];


%% initialization
tonep = 'D3';  %tonepin
shockp = 'D4';  %shockpin
lightp = 'D7';  %lightpin
optop = 'D6'; % opto pin
minip = 'D13'; % pin to trigger miniscipe
int_range = [min_trial_int, max_trial_int];

ts = struct;  % timestamp struct
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

first_csp = 1;  % used to create wav file for low latency audio presentation
first_csm = 1;
InitializePsychSound(1); % from psychtoolbox

%% trigger miniscope
if P.doMiniscope
    a.writeDigitalPin(minip, 1);
    ts.miniscope_on = clock;
    disp('Miniscope recording initiated')
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
        if isequal(this,[1;0;0;0])
            ts = doStim('csp', csp_p, a, tonep, lightp, cs_dur, ts, first_csp, first_csm);
        elseif isequal(this,[0;1;0;0])
            ts = doStim('csm', csm_p, a, tonep, lightp, cs_dur, ts, first_csp, first_csm);
        elseif isequal(this,[1;0;1;0])
            ts = doStimShock('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, first_csp, first_csm);  
        elseif isequal(this,[0;1;1;0])
            ts = doStimShock('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts, first_csp, first_csm);
        elseif isequal(this,[1;0;0;1])
            ts = doStimLaser('csp', csp_p, a, tonep, lightp, cs_dur, optop, ts);
        elseif isequal(this,[0;1;0;1])
            ts = doStimLaser('csm', csm_p, a, tonep, lightp, cs_dur, optop, ts);
        elseif isequal(this,[1;0;1;1])
            ts = doStimShockLaser('csp', csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, first_csp, first_csm);
        elseif isequal(this,[0;1;1;1])
            ts = doStimShockLaser('csm', csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, first_csp, first_csm);
        elseif isequal(this,[2;2;0;1])
            ts = doLaser(a, cs_dur, optop, ts);
        elseif isequal(this, [2;2;1;0])
            ts = doShock(a, shockp, cs_dur, us_dur, ts);
        elseif isequal(this, [2;2;1;1])
            ts = doLaserShock(a, shockp, optop, cs_dur, us_dur, ts);
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
    
disp('experiment complete')

%% post processing
time = datestr(clock,'YYYY-mm-dd_HH-MM-SS');
savevars = {'cs_dur', 'cs_minus', 'cs_plus', 'csm_p', 'csp_p', 'exp_ID', 'min_trial_int', 'max_trial_int', 't_baseline', 'ts', 'us_dur', 'xd', 'xd_labels'};
savename = [exp_ID '_' time '.mat'];
save(savename, savevars{:});
clear;

end
%% functions

% for doing just stimulus presentation. input: cs (csp or csm),
% cs_params, arduino handle, tonepin, lightpin)
function ts = doStim(cs, csP, a, tonep, lightp, cs_dur, ts, first_csp, first_csm)
%%
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
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur);
        a.writeDigitalPin(tonep, 0);

        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; audiotime];
        else
            ts.csm_off = [ts.csm_off; audiotime];
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
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur);
        a.writeDigitalPin(tonep, 0);
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
function ts = doStimShock(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, ts, first_csp, first_csm)
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
        
        a.writeDigitalPin(tonep, 1);

        pause(cs_dur-us_dur);
        a.writeDigitalPin(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        
        a.writeDigitalPin(shockp,0);
        a.writeDigitalPin(tonep, 0);
        
        ts.us_off = [ts.us_off; clock];
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; audiotime];
        else
            ts.csm_off = [ts.csm_off; audiotime];
        end

        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; audiotime];
        else
            ts.csm_off = [ts.csm_off; audiotime];
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
            ts.csp_off = [ts.csp_off; audiotime];
        else
            ts.csm_off = [ts.csm_off; audiotime];
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
function ts = doStimLaser(cs, csP, a, tonep, lightp, cs_dur, optop, ts)
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

        pause(cs_dur);

        a.writeDigitalPin(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; audiotime];
        else
            ts.csm_off = [ts.csm_off; audiotime];
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
function ts = doStimShockLaser(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts, first_csp, first_csm)
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
    
    a.writeDigitalPin(optop,0);
    ts.laser_off = [ts.laser_off; clock];   
end

%%
function ts = doLaser(a, cs_dur, optop, ts)
    a.writeDigitalPin(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    pause(cs_dur);
    a.writeDigitalPin(optop, 0);
    ts.laser_off = [ts.laser_off; clock];
end

%% 
function ts = doShock(a, shockp, cs_dur, us_dur, ts)
    pause(cs_dur-us_dur);
    a.writeDigitalPin(shockp,1);
    ts.us_on = [ts.us_on; clock];
    pause(us_dur);
    a.writeDigitalPin(shockp, 0);
    ts.us_off = [ts.us_off; clock];
end

%%
function ts = doLaserShock(a, shockp, optop, cs_dur, us_dur, ts)
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
    %  hidden feature to generate filtered white noise
    if tone_freq == 1
        [y, Fs] = prepNoise(cs_dur);
    else
        Fs = 44100;  % sampling freq (hz) NOTE: tone limit is 24 kHz
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
    t = 0 : 1/Fswn : (length(s)-1)/Fswn;
    ywn = filtfilt(hh, 1, s);                                     % Filter Signal
    
end
%%
function audiotime = psychsound(wavfilename)  
    [y, Fs] = psychwavread(wavfilename);  % read wav file
    wavedata = y';  % transpose 
    wavedata = [wavedata; wavedata];  % audio devices have 2 output channels; provide stream for both
    pahandle = PsychPortAudio('Open',3); % open audio device NB: must be WASAPI API, see PsychPortAudio('GetDevices') for device index 
    PsychPortAudio('FillBuffer', pahandle, wavedata);  % prep the sound 
    startTime = PsychPortAudio('Start', pahandle, 1, 0, 1);
    audiotime = clock;
end