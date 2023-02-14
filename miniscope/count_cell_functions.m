f_e = 0;
f_i = 0;
t_e = 0;
t_i = 0;
p_e = 0;
p_i = 0;
int_e = 0;
int_i = 0;
mult = 0;
nr = 0;


for i = 1:size(d1_table,1)
    z = d1_table{i,2:end};
    if z == [0 0 0 0 0]
        nr = nr+1;
    elseif nnz(z) > 1
        mult = mult +1;
    elseif z == [1 0 0 0 0]
        f_e = f_e+1;
    elseif z == [2 0 0 0 0]
        f_i = f_i+1;
    elseif z == [0 1 0 0 0]
        t_e = t_e+1;
    elseif z == [0 2 0 0 0]
        t_i = t_i+1;
    elseif z == [0 0 1 0 0]
        p_e = p_e+1;
    elseif z == [0 0 2 0 0]
        p_i = p_i +1;
    elseif (z == [0 0 0 1 0]) | (z == [0 0 0 0 1])
        int_e = int_e+1;
    elseif (z == [0 0 0 2 0]) | (z == [0 0 0 0 2])
        int_i = int_i+1;
    end
end

[f_e, f_i, t_e, t_i, p_e, p_i, int_e, int_i, mult, nr]