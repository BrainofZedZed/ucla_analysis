regions = nrrdread("C:\Users\boba4\Documents\GitHub\DeepTraCE\Models\annotation_10_lsfm_collapse_crop_flip_newf.nrrd");
regions = double(regions);
disp('annotation nrrd file loaded');

annotated = readtable("C:\Users\boba4\Documents\GitHub\DeepTraCE\Code\annotation_info_0118_1327_collapseDeNardoLabMGnew.csv");
sz = size(regions);
%each = cell(height(annotated),8);
each = cell(height(annotated),1);
disp('annotated atlas spreadsheet loaded');


%%
folders = {"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\1A_segmented\deeptrace_analysis\488_flipped", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\1C\488\deeptrace_analysis\230510_1C_488_09-57-05", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\3A_Dec23\deeptrace_analysis\231215_3A_488_13-43-39", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\2A\488\deeptrace_analysis\Flipped_488", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\3A_Dec23\deeptrace_analysis\231215_3A_488_13-43-39", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\3C_redo_Nov23\deeptrace_analysis\231128_3C_08x_480_17-08-27", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\3D\deeptrace_analysis\488_reversed", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\4A\deeptrace_analysis\flipped_480", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\5A\deeptrace_analysis\Flipped_488", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\5B\488_redo\deeptrace_analysis\230515_5B_488_15-29-24", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\5C\488\deeptrace_analysis\230503_5C_488_0_8x_10-29-38", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\6A\488\deeptrace_analysis\230516_6A_488_14-50-12", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\6B_Nov23\deeptrace_analysis\231129_6B_08x_480_08-53-57", ...
"D:\Whole Brain DeNardo 2023\T2Ai14_PFC_inhib_7d\7A_Dec23_redo\deeptrace_analysis\231215_7A_488_08-37-55"};


for brain = 1:numel(folders)
    w = folders{brain};
    for j = 1:1
        j
        tic
        cd(w)
        s = imfinfo('maxpoints.tif');
        test = uint8(zeros(s(1).Height,s(1).Width,numel(s)));
        for i = 1:numel(s)
            test(:,:,i) = imread('maxpoints.tif',i);
        end
        disp('finished reading file maxpoints');

        parfor i = 1:height(annotated)
            each{i,j} = test(regions == double(annotated.id(i))); %each saves intensity value for each pixel in a region
        end
        toc
        disp('finished saving intensity values')
    end

    % eachmin = min(cell2mat(each), [], 'all');
    % eachmax = max(cell2mat(each), [], 'all');

    %%
    size1 = size(each(1,1));
    size2 = size(each(2,1));
    size216 = size(each(216,1));
    size604 = size(each(604,1));
    size605 = size(each(605,1));
    size610 = size(each(610,1));
    size1328 = size(each(1328,1));
    size1251 = size(each(1251,1));

    each{1,1}=zeros(size1);
    each{2,1}=zeros(size2);
    each{216,1}=zeros(size216);
    each{604,1}=zeros(size604);
    each{605,1}=zeros(size605);
    each{610,1}=zeros(size610);
    each{1328,1}=zeros(size1328);
    each{1251,1}=zeros(size1251);

    clear RegionalDensity NormalizedRegionalDensity
    for j = 1:1
    for i = 1:length(each)
        RegionalDensity(i,j) = sum(each{i,j}>0)/numel(each{i,j}); %counts # of pixels above 0 and divides by total number of pixels in that region
    end
    end

    for i = 1:1
    NormalizedRegionalDensity(:,i) = RegionalDensity(:,i)/nansum(RegionalDensity(:,i));
    end
    disp('finished analyzing regional densities');


    clear AxonsByRegion NormalizedInnervation
    for j=1:1
        for i=1:length(each)
            AxonsByRegion(i,j) = sum(each{i,j}>0);
        end
    end

    for i=1:1
        NormalizedInnervation(:,i) = AxonsByRegion(:,i)/nansum(AxonsByRegion(:,i));
    end
    disp('finished analyzing axons by region');


    for j = 1:1
    for i = 1:length(each)
        rawCounts(i,j) = sum(each{i,j}>0); %counts # of pixels above 0
    end
    end
    disp('finished analyzing raw counts');


    % group1d = [1 2 3 7 8];
    % group14d = [4 5 6 9];


    ids = find(~isnan(RegionalDensity(:,1)));
    all = RegionalDensity(ids,:);
    % [~,regionalP] = ttest2(all(:,group1d)', all(:,group14d)');
    % sorted = [ids annotated.id(ids) mean(all(:,group1d),2) mean(all(:,group14d),2) regionalP'];
    % sorted = [sorted sorted(:,3)>sorted(:,4) all];
    % % annotatedcopy = annotated;
    % % annotatedcopy(~ismember(annotated.id,annotated.id(ids)),:) = [];
    % % annotatedcopy(653:end,:) = []; %fibertracts
    idsN = find(~isnan(NormalizedRegionalDensity(:,1)));
    allN = NormalizedRegionalDensity(ids,:);
    % [~,regionalP] = ttest2(allN(:,group1d)', allN(:,group14d)');
    % sortedN = [idsN annotated.id(idsN) mean(allN(:,group1d),2) mean(allN(:,group14d),2) regionalP'];
    % sortedN = [sortedN sortedN(:,3)>sortedN(:,4) allN];
    idsNN = find(~isnan(NormalizedInnervation(:,1)));
    allNN = NormalizedInnervation(ids,:);
    allRaw = rawCounts(ids,:);



    parentList = [];
    regionIDs = annotated.id(ids);
    sorted = [num2cell(ids), annotated.name(ids), num2cell(annotated.id(ids)), num2cell(all), num2cell(allN), num2cell(allNN), num2cell(allRaw)];
    for i = 1:length(sorted)
        clear parent
        if ismember(regionIDs(i), annotated.id) == 1
        parent = find(regionIDs(i) == annotated.id);
        parentList(i) = annotated.parent_id(parent);
        else parentList(i) = NaN;
        end
    end
    disp('finished sorting region IDs');


    sorted(:,8) = num2cell(parentList);
    % sortedCopy = sorted;
    % sortedCopy(1:2,1:length(sortedCopy)) = NaN; %remove background, fiber tracts, check numbers for each nrrd
    % sortedCopy(108:109,1:length(sortedCopy)) = NaN; %remove ventricles, fiber tracts, check numbers for each nrrd
    % for i = 1:16
    %     sortedCopy(:,i) = sortedCopy(~isnan(sortedCopy));
    % end
    %%
    sorted([1,2,3,63,64,65,130,149],:) = [];
    headers = {'ids', 'name', 'atlas number', 'cell counts normalized by region volume', 'cell counts normalized by region volume and total cells', 'cell counts normalized by total cells', 'raw cell counts', 'parent'};
    output = [headers; sorted];
    xlswrite('CellCounts.xlsx', output);
end