function caplot(sig)
figure;

sigt = sig;

for i = 1:size(sig,1)
    sigt(i,:) = normalize(sig(i,:), 'range');
end

plot((sigt + (1: size(sigt,1))')');

axis tight;
axis square;
xlabel('frame #');
ylabel('unit ID');
end