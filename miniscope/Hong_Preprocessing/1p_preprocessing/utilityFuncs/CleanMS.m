function ms = CleanMS(ms,c_label)
% Clean ms, only keep good cells


if ischar(ms)
   ms = load(ms);
   fnames = fields(ms);
   ms = ms.(fnames{1});
end

if nargin < 2
    c_label = ms.cell_label;
end

if ischar(c_label)
    c_label = load(c_label);
    fnames = fields(c_label);
    c_label = c_label.(fnames{1});
end
if length(c_label) ~= size(ms.SFPs,3)
    error('file does not match');
end


ms.Centroids = ms.Centroids(c_label > 0,:);
ms.FiltTraces = ms.FiltTraces(:, c_label>0);
ms.RawTraces = ms.RawTraces(:, c_label>0);
ms.SFPs = ms.SFPs(:,:,c_label>0);
ms.numNeurons = sum(c_label);
ms.S = ms.S(c_label>0,:);
ms.cell_label = ms.cell_label(c_label>0);
if isfield(ms,'FFTTraces')
    ms.FFTTraces = ms.FFTTraces(:, c_label>0);
end
if isfield(ms,'centroids_xz')
   ms.centroids_xz = ms.centroids_xz(c_label>0,:); 
end
save('ms_cleaned.mat','ms');



end

