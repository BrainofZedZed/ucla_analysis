function Features = applySession(Cues, Features)

session = Cues.Session;
info = fieldnames(Cues.Session);

vec_check = contains(info, 'vector', 'IgnoreCase', true);
session_labels = info(vec_check);

session_vectors = cell(sum(vec_check), 1);
count = 1;

% Collect all session vector data
for i = find(vec_check')
    session_vectors(count, 1) = {Cues.Session.(info{i})};
    count = count + 1;
end

% Create new vectors crossing session vectors with those in Features

feature_labels = fieldnames(Features);

for i = 1:size(session_labels, 1)
    for ii = 1:size(feature_labels, 1)
        
        feature_vec = Features.(feature_labels{ii});
        new_vec = double(feature_vec & session_vectors{i});
        new_label = newVecName(session_labels{i}, feature_labels{ii});
        Features.(new_label) = new_vec;
        
    end
end

end