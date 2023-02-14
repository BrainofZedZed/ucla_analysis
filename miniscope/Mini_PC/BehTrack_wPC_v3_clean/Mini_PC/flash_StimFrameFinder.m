%% initialization
clear;
tic;
ID = 'misc101 simplex OF_OLM training';
savename = [ID '_stimframes.mat'];

[path_name, file_base, file_fmt] = vid_info;
file_base = char(file_base);
file_fmt = char(file_fmt);
dirst = dir([path_name, file_base, '*', '.avi']); % struct containing directory of all files

bmean_rec = [];

%% nat sort file names
for i = 1:length(dirst)
    names(i) = {dirst(i).name};
end
names_natsort = natsortfiles(names);
%% go through vids, create reference, find blue brightness

for i = 1:size(dirst,1)
    
    filename = [dirst(i).folder '\' char(names_natsort(i))];
    v = VideoReader(filename);
    ct = 1;
    while hasFrame(v)
            frame = readFrame(v);
            frame_blue = frame(:,:,3); % keep only the blue channel;
            collection(:,:,ct) = frame_blue;
            ct = ct+1;
    end
    
    collection = uint8(collection);
    reference = median(collection,3);

    col2 = collection - reference;
    collection = zeros(size(col2,1), size(col2,2), size(col2,3));
    
    bmean = zeros(size(col2,3),1);

    for j = 1:size(col2,3)
        bmean(j) = mean(mean(col2(:,:,j)));
    end
    
    bmean_rec = [bmean_rec; bmean];
    disp(['Done with video ' num2str(i) ' of ' num2str(size(dirst,1))]);
end

%% look for periods of increased brightness
cutoff = 0.5;
minframedist = 30;

bmean_rec2(bmean_rec > (max(bmean_rec)*cutoff)) = 1;
bmean_rec2(bmean_rec <= (max(bmean_rec)*cutoff)) = 0;

ind = find(bmean_rec2 == 1);
inddif = ind(1:end-1) - ind(2:end);

fins = find(abs(inddif) > minframedist);
fins = ind(fins);
fins = [fins ind(end)];

starts = find(abs(inddif) > minframedist);
starts = starts + 1;
starts = ind(starts);
starts = [ind(1) starts];

starts = starts';
fins = fins';

stimframes = [starts fins];

%% save 
save([path_name savename], 'stimframes');
save([path_name ID '_stimframes_rawdata.mat'], 'bmean_rec', 'bmean_rec2', 'stimframes');
disp('File saved')
disp(' >^•?•^>   ~~all done~~    <^•?•^<');
toc
