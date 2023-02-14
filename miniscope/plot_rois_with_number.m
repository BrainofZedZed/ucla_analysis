%% plot two ROIs from miniscope rois and overlay cell number


%plot ROIs with cell IDs on top
roi1 = zz106d1roi;
roi2 = zz106d28roi;

roi1_orig = roi1;
roi2_orig = roi2;

% sum and squeeze ROIs across cell dimension
roi1 = sum(roi1);
roi1 = squeeze(roi1);
roi1(roi1~=0) = 1;

% calculate centers of objects
for i = 1:size(roi1_orig)
    tmp = squeeze(roi1_orig(i,:,:));
    [x y] = find(tmp);
    meanx = round(mean(x));
    meany = round(mean(y));
    cntrs1(i,1) = meanx;
    cntrs1(i,2) = meany;
end

imshow(roi1);
labels = num2cell([1:length(cntrs1)]);
h = text(cntrs1(:,2),cntrs1(:,1),labels);
set(h, 'Color', 'red');

% do same for second rois
roi2 = sum(roi2);
roi2 = squeeze(roi2);
roi2(roi2~=0) = 1;

% calculate centers of objects
for i = 1:size(roi2_orig)
    tmp = squeeze(roi2_orig(i,:,:));
    [x y] = find(tmp);
    meanx = round(mean(x));
    meany = round(mean(y));
    cntrs2(i,1) = meanx;
    cntrs2(i,2) = meany;
end

% plot
figure;
imshow(roi2);
labels = num2cell([1:length(cntrs2)]);
h = text(cntrs2(:,2),cntrs2(:,1),labels);
set(h, 'Color', 'blue');