

   % load 465 from 405 signal and downsample
    s465 = data.streams.x465A.data;
    s405 = data.streams.x405A.data;

    % downsample
    s465 = s465(1:P2.fp_ds_factor:end);
    s405 = s405(1:P2.fp_ds_factor:end);


        %%
        figure; plot(s405, 'm');
        title('405 signal');
        xlim([1100 44000]);
        label = {'laser on', 'laser off','laser on', 'laser off','laser on', 'laser on','laser on', 'laser on','laser on', 'laser on'};
        lasercues = reshape(cueframes.laser,[],1);
        lasercues = beh2fp(lasercues);
        lasercues = sort(lasercues, 'ascend');
        xline(lasercues,'r', label)

        figure; plot(s465, 'b');
        title('465 signal');
        xlim([1100 44000]);
        label = {'laser on', 'laser off','laser on', 'laser off','laser on', 'laser on','laser on', 'laser on','laser on', 'laser on'};
        lasercues = reshape(cueframes.laser,[],1);
        lasercues = beh2fp(lasercues);
        lasercues = sort(lasercues, 'ascend');
        xline(lasercues,'r', label)
       
    