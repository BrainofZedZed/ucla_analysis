allFs = dir('*.mat');
allFs = {allFs.name};
% sort all Fs
n = [];
for i = 1:length(allFs)
    temp1 = strsplit(allFs{i},'_');
    temp1 = temp1{1};
    num = regexp(temp1,'\d*');
    num = str2num(temp1(num:end));
    n = [n,num];
end
[~,si] = sort(n);
allFs = allFs(si);
allPairs = cell(1,length(allFs)/2);
for i = 1:2:length(allFs)
    tempcell = cell(1,2);
    load(allFs{i});
    F.ExperimentID = F.ExperimentID(1:end-2); % remove '_F'
    tempcell{1} = F;
    if length(F.videoInfo.session) == 2
        F.videoInfo.session = {'sep';'exp'};
    end
    load(allFs{i+1});
    F.ExperimentID = F.ExperimentID(1:end-2); % remove '_F'
    if length(F.videoInfo.session) == 2
        F.videoInfo.session = {'sep';'exp'};
    end
    tempcell{2} = F;
    allPairs{ceil(i/2)} = tempcell;
    
end
for i = 1:length(allPairs)
   for j = 1:2
      animalID = allPairs{i}{j}.videoInfo.MouseID{1};
      allPairs{i}{j}.AnimalID = animalID;
   end
end

for i = 1:length(allPairs)
    for j = 1:2
        allPairs{i}{j}.videoInfo.session = {'sep';'exp'};
        allPairs{i}{j}.ExperimentID = allPairs{i}{j}.ExperimentID(1:end-2);
    end
end