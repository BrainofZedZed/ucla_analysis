import os

def rename_videos(folder_path, prefix):
    # List all files in the directory
    files = os.listdir(folder_path)
    
    # Filter for .avi files and sort them numerically based on the file name
    avi_files = [f for f in files if f.endswith('.avi')]
    avi_files.sort(key=lambda x: int(x.split('.')[0]))

    # Rename each file
    for file in avi_files:
        # Extract the base number from the file name
        num = int(file.split('.')[0])
        # Format new file name to be exactly 4 digits long with custom prefix
        new_name = f"{prefix}{num:02}.avi"
        # Create full old and new file paths
        old_file = os.path.join(folder_path, file)
        new_file = os.path.join(folder_path, new_name)
        # Rename the file
        os.rename(old_file, new_file)
        print(f"Renamed {old_file} to {new_file}")

# Example usage:
folder1 = r'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\Miniscope data\soma_gcamp_PL\miniscope data\ZZ228 concat\D28'
#folder2 = 'path_to_second_folder'
#folder3 = 'path_to_third_folder'
#folder4 = 'path_to_fourth_folder'

rename_videos(folder1, '03')
#rename_videos(folder2, '01')
#rename_videos(folder3, '02')
#rename_videos(folder4, '03')
