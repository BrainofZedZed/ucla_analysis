function [ms_sep, ms_exp] = ParseMS(ms, f)
% parse ms to sep and exp
% f, frame number to make the cut
if ischar(ms)
    load(ms);
end


ms_sep = ms;
ms_exp = ms;
ms_sep.FiltTraces = ms_sep.FiltTraces(1:f,:);
ms_exp.FiltTraces = ms_exp.FiltTraces(f+1:end,:);
ms_sep.RawTraces = ms_sep.RawTraces(1:f,:);
ms_exp.RawTraces = ms_exp.RawTraces(f+1:end,:);
ms_sep.S = ms_sep.S(:,1:f);
ms_exp.S = ms_exp.S(:, f+1:end);

ms = ms_sep;
save('ms_sep.mat','ms');
ms = ms_exp;
save('ms_exp.mat','ms');


end

