%from Federico
% after saving minian data as NCread format, can load into MATLAB
% Adata will hold the footprint of each neuron.
% The structure of Adata is Adata(x,y,cell_number) 
% The structure of Cdata is Cdata(amplitude_frame,cell_number), where amplitude_frame will be the amplitude of C in that frame for a given cell_number.
clear;
minian_ds_dir = 'C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA cohort1\bdbatch\ZZ087_caroc\ZZ087_FC';
minian_ds_path = [minian_ds_dir '\minian_ds.nc'];

Adata  = ncread(minian_ds_path,'A');
Cdata  = ncread(minian_ds_path,'C');
Cdata = Cdata';
Sdata  = ncread(minian_ds_path,'S');
Sdata = Sdata';
bdata = ncread(minian_ds_path, 'b');
fdata = ncread(minian_ds_path, 'f');
max_proj = ncread(minian_ds_path, 'max_proj');

save([minian_ds_dir '\minian_data.mat'], 'Adata', 'Cdata', 'Sdata', 'bdata', 'fdata', 'max_proj')
dff = Cdata;
spkfn = Sdata;
save([minian_ds_dir '\minian_data_processed.mat'],"spkfn", "dff");