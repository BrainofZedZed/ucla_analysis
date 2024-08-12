%from Federico
% after saving minian data as NCread format, can load into MATLAB
% Adata will hold the footprint of each neuron.
% The structure of Adata is Adata(x,y,cell_number) 
% The structure of Cdata is Cdata(amplitude_frame,cell_number), where amplitude_frame will be the amplitude of C in that frame for a given cell_number.
clear;
minian_ds_path = 'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\cohort7_20231018\ZZ208_D28_2\2023_12_05\13_48_33\My_V4_Miniscope\minian';
minian_ds_file = [minian_ds_path '\minian_dataset.nc'];
Adata  = ncread(minian_ds_file,'A');
Cdata  = ncread(minian_ds_file,'C');
Cdata = Cdata';
Sdata  = ncread(minian_ds_file,'S');
Sdata = Sdata';
bdata = ncread(minian_ds_file, 'b');
fdata = ncread(minian_ds_file, 'f');
max_proj = ncread(minian_ds_file, 'max_proj');
%vid = ncread(minian_ds_path, 'varr');

savename = strcat(minian_ds_path, "\minian_data_cnmf.mat");
save(savename, 'Adata', 'Cdata', 'Sdata', 'bdata', 'fdata', 'max_proj')



%% 
% format for CScreener
ms.FiltTraces = Cdata';
ms.RawTraces = Cdata';
ms.S = Sdata';
ms.numNeurons = size(Cdata,1);
ms.cell_label = ones([ms.numNeurons,1]);

for i = 1:size(Adata,3)
    Atmp = flipud(Adata(:,:,i));
    Atmp = Atmp';
    Atmp = fliplr(Atmp);
    ms.SFPs(:,:,i) = Atmp;
end
savename = strcat(minian_ds_path, "\ms.mat");
save(savename,"ms", '-v7.3');