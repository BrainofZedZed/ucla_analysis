function ms = FFTTraces(vmat, ms, thr, sa)
% input video path and ms file (or path), map ROIs back to video and output
% a copy of ms with a field named 'FFTTraces', containing the traces of all
% ROIs with their raw pixel value readout
% thr threshold of ROIs, to control the overlap: higher threshold, smaller 
% ROIs and lower overlap
% sa save or not? true/false

if ~isstruct(ms)
    if ischar(ms)
        ms = load(ms);
        ms = ms.ms;
    else
        error('invalid input\n');
    end
end

if nargin < 3
    thr = 0.5;
    sa = false;
elseif nargin < 4
    sa = false;
end
if ischar(vmat)
    vid = VideoReader(vmat);
    vmat = read(vid);
    delete(vid);
end
vmat = squeeze(vmat);
rois = ms.SFPs;
if any(size(rois,[1,2])~=size(vmat,[1,2]))
    error('dimension does not match\n');
end
FFTTraces = zeros(size(vmat,3), size(rois,3));
fw = waitbar(0, 'processing...');
for i = 1:size(rois,3)
   this_roi_raw = uint8(rois(:,:,i));
   cutoff = quantile(this_roi_raw, thr, 'all');
   this_roi = this_roi_raw;
   this_roi(this_roi<cutoff) = 0;
   trace = reshape(this_roi .* vmat,[],size(vmat,3));
   trace = sum(trace,1);
   trace = trace/sum(this_roi,'all');
   FFTTraces(:,i) = trace;
   disp(i);
   waitbar(i/size(rois,3),fw,[num2str(i),' of ', num2str(size(rois,3)),' processed']);
end

ms.FFTTraces = FFTTraces;
if sa
    waitbar(1,fw,'saving...');
    save([ms.dirName,'\ms.mat'],'ms');
end
close(fw);



end

