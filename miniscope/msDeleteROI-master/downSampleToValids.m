function [ms,neuron] = downSampleToValids(path,overWriteFlag)

% Input:
% 1) path = path of the files used for downsample, i.e., 'ms.mat', 'neuronFull.mat', 
% and 'validROIs.mat'.
% 2) overWriteFlag = logical value which indicates whether 
% the current 'ms.mat' and
% 'neuronFull.mat' values will be overwritten, and the 'validROIs.mat' file 
% will be renamed when you select overWriteFlag as 1. (Default = 0)

% Output:
% 1) ms: new ms variable with info restricted to the valid ROIs
% 2) neuron: new neuron variable with info restricted to the valid ROIs
% Created by Daniel Almeida Filho, July, 9, 2019: almeidafilhodg@ucla.edu


if nargin<2
  overWriteFlag=0;
end
cd(path)
load('validROIs.mat')

% Correcting ms
load('ms.mat')
ms.FiltTraces = ms.FiltTraces(:,valid_roi);
ms.RawTraces = ms.RawTraces(:,valid_roi);
ms.SFPs = ms.SFPs(:,:,valid_roi);
ms.numNeurons = length(find(valid_roi));

% Correcting neuron
load('neuronFull.mat')
neuron.A = neuron.A(:,valid_roi);
neuron.C = neuron.C(valid_roi,:);
neuron.C_raw = neuron.C_raw(valid_roi,:);
neuron.S = neuron.S(valid_roi,:);
neuron.P.kernel_pars = neuron.P.kernel_pars(valid_roi);
neuron.P.neuron_sn = neuron.P.neuron_sn(valid_roi);
neuron.ids = neuron.ids(valid_roi);
neuron.tags = neuron.tags(valid_roi);


if overWriteFlag==1
   save('ms.mat','ms') 
   save('neuronFull.mat','neuron') 
   movefile('validROIs.mat','validROIs_USED.mat')
end





