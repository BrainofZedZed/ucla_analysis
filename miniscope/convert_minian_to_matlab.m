%from Federico
% after saving minian data as NCread format, can load into MATLAB
% Adata will hold the footprint of each neuron.
% The structure of Adata is Adata(x,y,cell_number) 
% The structure of Cdata is Cdata(amplitude_frame,cell_number), where amplitude_frame will be the amplitude of C in that frame for a given cell_number.
clear;

minian_ds_path = "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\soma_gcamp_PL\miniscope data\hab\ZZ228_hab\2024_03_12\15_36_41\My_V4_Miniscope\minian_OneTemporalNoSpatialUpdate\minian_dataset.nc";
Adata  = ncread(minian_ds_path,'A');
Cdata  = ncread(minian_ds_path,'C');
Cdata = Cdata';
Sdata  = ncread(minian_ds_path,'S');
Sdata = Sdata';
bdata = ncread(minian_ds_path, 'b');
fdata = ncread(minian_ds_path, 'f');
%vid = ncread(minian_ds_path, 'Y_fm_chk');
max_proj = ncread(minian_ds_path, 'max_proj');


[minian_ds_dir, ~, ~] = fileparts(minian_ds_path);

savename = strcat(minian_ds_dir, "\minian_data_cnmf.mat");
save(savename, 'Adata', 'Cdata', 'Sdata', 'bdata', 'fdata', 'max_proj')
dff = Cdata;
spkfn = Sdata;

savename = strcat(minian_ds_dir, "\minian_data_processed_cnmf.mat");

save(savename,"spkfn", "dff");

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
savename = strcat(minian_ds_dir, "\ms.mat");
save(savename,"ms", '-v7.3');