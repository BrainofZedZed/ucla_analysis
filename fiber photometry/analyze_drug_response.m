t = cueframes.US(1:5,:);
pre_sig = [];
for i = 1:size(t,1)
    pre_sig(i,:) = bhsig(t(i,1)-100:t(i,1)+500);
end

t = cueframes.US(6:10,:);
post_sig = [];
for i = 1:size(t,1)
    post_sig(i,:) = bhsig(t(i,1)-100:t(i,1)+500);
end
    
z = zscore_matrix(pre_sig,[1 100]);
z2 = zscore_matrix(post_sig,[1 100]);

linePlot(z,100);
linePlot(z2,100);