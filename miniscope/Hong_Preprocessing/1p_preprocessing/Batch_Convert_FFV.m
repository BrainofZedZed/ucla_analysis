folders = {
'D:\Xingjian\MiniscopeData\raw_data\dual_animal_newcage_free\mDLX_v_mDLX\2021_03_03' ;
'D:\Xingjian\MiniscopeData\raw_data\dual_animal_newcage_free\mDLX_v_mDLX\2021_03_11';
'D:\Xingjian\MiniscopeData\raw_data\dual_animal_newcage_free\mDLX_v_mDLX\2021_03_12';
'D:\Xingjian\MiniscopeData\raw_data\dual_animal_newcage_free\mDLX_v_mDLX\2021_03_17';
}

fin = {};
for i = 1:length(folders)
    temp = dir([folders{i},'\**\']);
    temp = temp([temp(:).isdir]);
    for j = 1:length(temp)
        if contains(temp(j).name, 'Minis')
            fin = [fin; [temp(j).folder,'\',temp(j).name]];
        end
    end
end

fout = fin;
outpath = 'E:\MiniscopeData(processed)\NewCage_free_dual\mDLX_vs_mDLX';

for i = 1:length(fout)
    for j = 1:length(folders)
        if contains(fout{i}, folders{j})
            break
        end
    end
    fout{i} = strrep(fout{i},folders{j}, outpath);
end

%%
addpath(genpath('D:\Xingjian\Repositories\1p_preprocessing\Toolboxes\'));
convert_msCam1(fin, fout)