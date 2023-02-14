function new_vec_name = newVecName(vec_name1, varargin)

if nargin == 1
    key1 = lower(erase(vec_name1, {'Vector', 'vector'}));
    keys = {key1};
    
elseif nargin == 2

    vec_name2 = varargin{1};
    
    key1 = lower(erase(vec_name1, {'Vector', 'vector'}));   
    key2 = lower(erase(vec_name2, {'Vector', 'vector'}));

    if size(key1, 2) ~= 2
        keys = sort({key1, key2});
        keys(2) = {[upper(keys{2}(1)), keys{2}(2:end)]};
    else
        keys = {[upper(key1), key2]};
    end
    
elseif nargin == 3
    key1 = vec_name1;
    key2 = lower(erase(varargin{1}, {'Vector', 'vector'}));
    key3 = lower(erase(varargin{2}, {'Vector', 'vector'}));
    
    keys = sort({key2, key3});
    keys(2) = {[upper(keys{2}(1)), keys{2}(2:end)]};
    keys = {key1, keys{1}, keys{2}};
end
    
    new_vec_name = [keys{:} 'Vector'];

end