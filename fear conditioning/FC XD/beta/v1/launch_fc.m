% Fear conditioning script
% started ZZ 12/7/20 
% Goal:  make fear conditioning script to work with modern MATLAB Arduino
% interface, and provide way to also do light cue

% hardware setup on arduino:  pin 4 - tone, pin 5 - shock, pin 6 - light,
% pin 7 - opto
%% setup params
% experiment structure
function launch_fc(P)
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
    csp_p.name = 'Tone';
elseif isequal(cs_plus,'Tone2')
    csp_p.tone_freq = tone_freq2;
    csp_p.name = 'Tone';
elseif isequal(cs_plus,'FM Sweep1')
    csp_p.start_freq = start_freq1;
    csp_p.end_freq = end_freq1;
    csp_p.sweep_dur = sweep_dur;
    csp_p.name = 'FM';
elseif isequal(cs_plus,'FM Sweep2')
    csp_p.start_freq = start_freq2;
    csp_p.end_freq = end_freq2;
    csp_p.sweep_dur = sweep_dur;
    csp_p.name = 'FM';
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
    csm_p.name = 'Tone';
elseif isequal(cs_minus,'Tone2')
    csm_p.tone_freq = tone_freq2;
    csm_p.name = 'Tone';
elseif isequal(cs_minus,'FM Sweep1')
    csm_p.start_freq = start_freq1;
    csm_p.end_freq = end_freq1;
    csm_p.sweep_dur = sweep_dur;
    csm_p.name = 'FM';
elseif isequal(cs_minus,'FM Sweep2')
    csm_p.start_freq = start_freq2;
    csm_p.end_freq = end_freq2;
    csm_p.sweep_dur = sweep_dur;
    csm_p.name = 'FM';
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


% opto settings  %%NOT INCORPORATED YET%%
opto.on_prior_cs = 1; %(s) timing of light on, relative to cs plus on
opto.off_post_cs = 1; % (s) timing of light off, relative to cs plus off

%% initialization
a = arduino('COM4');

a.pinMode(2,'output');
a.pinMode(3,'output');
a.pinMode(4,'output');
a.pinMode(5,'output');
a.pinMode(6,'output');
a.pinMode(7,'output');

a.digitalWrite(2,0);
a.digitalWrite(3,0);
a.digitalWrite(4,0);
a.digitalWrite(5,0);
a.digitalWrite(6,0);
a.digitalWrite(7,0);

tonep = 3;  %tonepin
shockp = 4;  %shockpin
lightp = 6;  %lightpin
optop = 7; % opto pin
int_range = [min_trial_int, max_trial_int];

disp('Arduino connected');
if isequal(cs_plus,'T')
    csp = tonep;  % csplus
    csm = lightp; % csminus
elseif isequal(cs_plus, 'light')
    csp = lightp;
    csm = tonep;
else
    disp('error. incorrect cs plus choice')
end
ts = struct;
ts.csp_on = [];  
ts.csp_off = [];
ts.csm_on = [];  
ts.csm_off = [];
ts.us_on = [];
ts.us_off = [];
ts.laser_on = [];
ts.laser_off = [];


%% baseline
if t_baseline > 0
    disp(['baseline period. No stimulus presentations for ' num2str(t_baseline) ' seconds'])
    pause(t_baseline)
end

%% do presentations
disp('Now doing events')
    for i = 1:size(xd,2)
        pause(randi(int_range));
        disp(['Now doing event #' num2str(i)]);
        
        if isequal(this,[1;0;0;0])
            ts = doStim(csp, csp_p, a, tonep, lightp, cs_dur, ts);
        elseif isequal(this,[0;1;0;0])
            ts = doStim(csm, csm_p, a, tonep, lightp, cs_dur, ts);
        elseif isequal(this,[1;0;1;0])
            ts = doStimShock(csp, csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts);  
        elseif isequal(this,[0;1;1;0])
            ts = doStimShock(csm, csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, ts);
        elseif isequal(this,[1;0;0;1])
            ts = doStimLaser(csp, csp_p, a, tonep, lightp, cs_dur, optop, ts);
        elseif isequal(this,[0;1;0;1])
            ts = doStimLaser(csm, csm_p, a, tonep, lightp, cs_dur, optop, ts);
        elseif isequal(this,[1;0;1;1])
            ts = doStimShockLaser(csp, csp_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts)
        elseif isequal(this,[0;1;1;1])
            ts = doStimShockLaser(csm, csm_p, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts)
        end
        disp(['Done ' num2str(i) ' of ' num2str(size(xd,2)) ' events']);
    end


disp('experiment complete')

%% post processing
time = datestr(clock,'YYYY-mm-dd_HH-MM-SS');
savename = [exp_ID '_' time '.mat'];
save(savename);
clear;
%% functions

% for doing just stimulus presentation. input: cs (csp or csm),
% cs_params, arduino handle, tonepin, lightpin)
function ts = doStim(cs, csP, a, tonep, lightp, cs_dur, ts)
%%
    if isequal(csP.name, 'Tone')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        playSineWave(csP.tone_freq,cs_dur)
        pause(cs_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%
    elseif isequal(csP.name, 'FM')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        
        playFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
        pause(cs_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%
    elseif isequal(csP.name, 'Light')
        a.digitalWrite(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur)
        a.digitalWrite(lightp,0);
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
function ts = doStimShock(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, ts)
    if isequal(csP.name, 'Tone')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        playSineWave(csP.tone_freq,cs_dur)
        pause(cs_dur-us_dur);
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp, 0);
        ts.us_off = [ts.us_off; clock];
%%
    elseif isequal(csP.name, 'FM')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        
        playFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
        pause(cs_dur-us_dur);
        a.digitalWrite(shockp, 1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp, 0);
        ts.us_off = [ts.us_off; clock];

%%
    elseif isequal(csP.name, 'Light')
        a.digitalWrite(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur-us_dur)
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(lightp,0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp,0);
        ts.us_off = [ts.us_off; clock];
%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur-us_dur);
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, us_dur);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end      
        a.digitalWrite(shockp,0);
        ts.us_off = [ts.us_off; clock];
    end
end

%%
function ts = doStimLaser(cs, csP, a, tonep, lightp, cs_dur, optop, ts)
    a.digitalWrite(optop, 1);
    ts.laser_on = [ts.laser_on; clock];
    if isequal(csP.name, 'Tone')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        playSineWave(csP.tone_freq,cs_dur)
        pause(cs_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%
    elseif isequal(csP.name, 'FM')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        
        playFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
        pause(cs_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
%%
    elseif isequal(csP.name, 'Light')
        a.digitalWrite(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur)
        a.digitalWrite(lightp,0);
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
    a.digitalWrite(optop,0);
    ts.laser_off = [ts.laser_off; clock];
end

%%
function ts = doStimShockLaser(cs, csP, a, tonep, lightp, shockp, cs_dur, us_dur, optop, ts)
    a.digitalWrite(optop,1);
    ts.laser_on = [ts.laser_on; clock];
    if isequal(csP.name, 'Tone')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        playSineWave(csP.tone_freq,cs_dur)
        pause(cs_dur-us_dur);
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp, 0);
        ts.us_off = [ts.us_off; clock];
%%
    elseif isequal(csP.name, 'FM')
        a.digitalWrite(tonep, 1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        
        playFMSweep(csP.start_freq, csP.end_freq, csP.sweep_dur, cs_dur);
        pause(cs_dur-us_dur);
        a.digitalWrite(shockp, 1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(tonep, 0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp, 0);
        ts.us_off = [ts.us_off; clock];

%%
    elseif isequal(csP.name, 'Light')
        a.digitalWrite(lightp,1);
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        pause(cs_dur-us_dur)
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        pause(us_dur);
        a.digitalWrite(lightp,0);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end
        a.digitalWrite(shockp,0);
        ts.us_off = [ts.us_off; clock];
%%        
    elseif isequal(csP.name, 'Pulsed Light')
        if isequal(cs, 'csp')
            ts.csp_on = [ts.csp_on; clock];
        else
            ts.csm_on = [ts.csm_on; clock];
        end
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, cs_dur-us_dur);
        a.digitalWrite(shockp,1);
        ts.us_on = [ts.us_on; clock];
        flickerLight(csP.flicker_freq, csP.light_dc, a, lightp, us_dur);
        if isequal(cs, 'csp')
            ts.csp_off = [ts.csp_off; clock];
        else
            ts.csm_off = [ts.csm_off; clock];
        end      
        a.digitalWrite(shockp,0);
        ts.us_off = [ts.us_off; clock];
    end
    a.digitalWrite(optop,0);
    ts.laser_off = [ts.laser_off; clock];
    
end
end