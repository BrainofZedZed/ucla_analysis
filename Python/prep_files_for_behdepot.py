import os
import shutil
import glob

def create_dirs_and_move_files(list_of_strings, target_directory):
    # Make sure target_directory is a directory
    if not os.path.isdir(target_directory):
        print(f"Error: {target_directory} is not a directory.")
        return

    # For each string in the list
    for s in list_of_strings:
        # Look for .mat, .csv, and .avi files in the target directory
        for ext in ['.mat', '.csv', '.avi', '.txt']:
            files = glob.glob(f"{target_directory}/*{ext}")
            # If a matching file is found (case-insensitive), create a directory and move the file
            for file in files:
                if s.lower() in os.path.basename(file).lower():
                    new_dir = os.path.join(target_directory, s)
                    if not os.path.exists(new_dir):
                        os.makedirs(new_dir)
                        print(f"Created new directory: {new_dir}")
                    shutil.move(file, new_dir)

# Usage
names = ['DP067_PMA_D1', 'DP067_PMA_D2', 'DP067_PMA_D3', 'DP067_PMA_D4', 'DP067_PMA_D1', 'DP067_training_D2', 'DP067_training_D3', 'DP067_training_D4', 'DP067_training_D5','DP066_PMA_D1', 'DP066_PMA_D2', 'DP066_PMA_D3', 'DP066_PMA_D4', 'DP066_PMA_D1', 'DP066_training_D2', 'DP066_training_D3', 'DP066_training_D4', 'DP066_training_D5', 'DP065_PMA_D1', 'DP065_PMA_D2', 'DP065_PMA_D3', 'DP065_PMA_D4', 'DP065_PMA_D1', 'DP065_training_D2', 'DP065_training_D3', 'DP065_training_D4', 'DP065_training_D5', 'DP065_training_Redo2']
target_dir = r"E:\GRABDA_PMAR_closedLoop\males\batch for behdepot"
create_dirs_and_move_files(names, target_dir)
