import scipy.io
from scipy.io.matlab import mat_struct

def get_struct_names(item, struct_names, current_path):
    if isinstance(item, mat_struct):
        struct_names.append(current_path)
        field_names = item._fieldnames
        for field_name in field_names:
            field_item = item[field_name][0, 0]
            get_struct_names(field_item, struct_names, f"{current_path}.{field_name}")

file_path = r"C:\Users\Zach\Box\Zach_repo\Projects\DA PMA\fiber photometry\GRABDA PMA REWARD\batch\D1\DP060_D1\DP060_D1_analyzed\Behavior.mat"
matlab_data = scipy.io.loadmat(file_path)

struct_names = []

# List top-level keys (excluding metadata keys)
top_level_keys = [key for key in matlab_data.keys() if not key.startswith('__')]

# Recursively check each level of the keys and save struct names
for key in top_level_keys:
    item = matlab_data[key]
    get_struct_names(item, struct_names, key)

# Print struct names
print("Struct names:")
for struct_name in struct_names:
    print(f"  {struct_name}")

