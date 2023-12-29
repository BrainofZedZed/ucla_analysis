
folders = {"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\7A_Dec23_redo\deeptrace_analysis\231215_7A_488_08-37-55"};
dif_thresh = 5;  % default 50 for axon; 5 for ZZ fos

w = folders{1};
cd(w)
seg_file_name = 'z_best_weights_checkpoint_FOS_seg_231215_7A_640_08-45-50_aligned.tiff';
s = imfinfo(seg_file_name);
test = uint8(zeros(s(1).Height,s(1).Width,numel(s)));

for brain = 1:length(folders)
    w = folders{brain};
    for j = 1:1
        brain
        tic
        cd(w)
        s = imfinfo(seg_file_name);
        for i = 1:numel(s)
            test(:,:,i) = imread(seg_file_name,i);
        end
        BW = imextendedmax(test,dif_thresh);
        CC = bwconncomp(BW);
        
        %%
        for i = 1:CC.NumObjects
            index = CC.PixelIdxList{i};
            if (numel(index) > 1 && (rem(numel(index),2) == 1))
                indexmed = median(index);
                indexnonmed = index(index~=indexmed);
                BW(indexnonmed) = false;
            else
            if (numel(index) > 1)
                indexmedeven = numel(index)/2;
                indexmed = index(indexmedeven);
                indexnonmed = index(index~=indexmed);
                BW(indexnonmed) = false;
            end
            end
        end
        BW8 = uint8(BW);
        options.compress = 'lzw';
        options.color = 0;
        options.overwrite = true;
        %%
        saveloc = strcat(string(folders(brain)), "\maxpoints.tif");
        saveastiff(BW8, saveloc{1}, options)
        %%
    end
end

%%
cccheck = bwconncomp(BW);