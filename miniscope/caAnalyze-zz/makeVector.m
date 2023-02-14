%makeVector

function vector = makeVector(inds, length)
vector = zeros(1, length);

for i = 1:size(inds, 1)
    vector( inds(i,1):inds(i,2) ) = 1;
end
end