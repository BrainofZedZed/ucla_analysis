function Features = genFeatures(Cues, caBehavior)

% Initialize Features structure
Features = struct();

% Make a list of cue vectors to combine
cue_fields = fieldnames(Cues);
vec_test = contains(cue_fields, 'vector', 'IgnoreCase', true);
cue_labels = cue_fields(vec_test);

for i = 1:size(cue_labels, 1)
    cue_vectors{i,1} = Cues.(cue_labels{i});
end

% Make a list of behavior vectors to combine
beh_labels = fieldnames(caBehavior);
beh_vectors = cell(size(beh_labels,1), 1);

% Collect vector data from caBehavior 
for i = 1:size(beh_labels, 1)
    beh_vectors{i} = caBehavior.(beh_labels{i}).Vector;
end

% Make vectors for base cue/behavior sets
base_vectors = [cue_vectors; beh_vectors];
base_labels = [cue_labels; beh_labels];

% Prep vector names for base vectors
for i = 1:size(base_vectors, 1)
    base_labels{i} = newVecName(base_labels{i});
end

% Record base vectors in Features struct
for i = 1:size(base_vectors, 1)
    Features.(base_labels{i}) = base_vectors{i};
end

%% Combine all base_vectors and save into Features

for i = 1:(size(base_vectors, 1) - 1)
    for ii = (i + 1):size(base_vectors, 1)
        
        new_vec = double(base_vectors{i} & base_vectors{ii});
        new_label = newVecName(base_labels{i}, base_labels{ii});
        Features.(new_label) = new_vec;
        
    end
end

end