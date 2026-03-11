"""
Concatenate behavioral video files from miniscope experiments.

This script recursively searches for 'My_WebCam' folders and concatenates
all individual video frames (e.g., 0.avi, 1.avi, 2.avi) into a single
output file (concat_beh.avi) using FFmpeg's concat demuxer. This is useful
for combining frame-by-frame video recordings from miniscope behavior
tracking sessions.

The script uses stream copying (-c copy) for fast concatenation without
re-encoding, which preserves video quality and minimizes processing time.

Requirements:
    - FFmpeg must be installed and accessible in the system PATH
    - Input videos should be named with numeric prefixes (e.g., 0.avi, 1.avi)

Example:
    python concat_beh_vids.py
    
Then update the target_dir variable with your input folder path.
"""

import os
import subprocess


def concatenate_with_ffmpeg(root_folder):
    """
    Recursively find and concatenate video files in 'My_WebCam' folders.
    
    Searches through all subdirectories for 'My_WebCam' folders. For each
    found, it collects all .avi files (except 'concat_beh.avi'), sorts
    them numerically, and concatenates them into a single output file using
    FFmpeg's concat demuxer.
    
    Args:
        root_folder (str): The root directory path to search recursively.
                          Should contain 'My_WebCam' subdirectories.
    
    Returns:
        None. Prints status messages to stdout and creates output files
        in the 'My_WebCam' directories.
    
    Raises:
        subprocess.CalledProcessError: If FFmpeg command fails (caught and
                                      printed to stdout).
    
    Output:
        - Creates 'concat_beh.avi' in each 'My_WebCam' folder
        - Prints processing status and success/error messages
        - Cleans up temporary file list after concatenation
    """
    for root, dirs, files in os.walk(root_folder):
        if os.path.basename(root) == 'My_WebCam':
            # Filter for .avi files and exclude the output file to avoid recursion
            avi_files = [f for f in files if f.endswith('.avi') and f != 'concat_beh.avi']
            
            # Sort files numerically by their stem (0, 1, 2, ...) for correct order
            # This ensures frames are concatenated in the correct sequence
            avi_files.sort(key=lambda x: int(os.path.splitext(x)[0]))

            if not avi_files:
                # Skip directories with no video files
                continue

            print(f"Processing: {root}")
            
            # Create a temporary text file containing the list of videos to concatenate
            # FFmpeg's concat demuxer requires a specific format for the file list
            list_file_path = os.path.join(root, 'files_to_join.txt')
            with open(list_file_path, 'w') as f:
                for filename in avi_files:
                    # FFmpeg concat demuxer format: "file '<filename>'"
                    f.write(f"file '{filename}'\n")

            output_file = os.path.join(root, 'concat_beh.avi')
            
            # Build FFmpeg command for stream copying concatenation
            # Benefits: Fast (no re-encoding), lossless, preserves original quality
            # -f concat: Use the concat demuxer to join multiple files
            # -safe 0: Allow unsafe file paths (required for relative paths)
            # -i <file>: Input file (the text file listing videos to concatenate)
            # -c copy: Copy streams without re-encoding (much faster)
            # -y: Overwrite output file if it already exists
            command = [
                'ffmpeg', '-y', '-f', 'concat', '-safe', '0',
                '-i', list_file_path, '-c', 'copy', output_file
            ]

            try:
                # Execute FFmpeg command from the My_WebCam directory so relative paths work
                # This ensures FFmpeg can find the video files referenced in files_to_join.txt
                original_dir = os.getcwd()
                os.chdir(root)
                subprocess.run(command, check=True, capture_output=True)
                os.chdir(original_dir)
                print(f"Successfully created: {output_file}")
            except subprocess.CalledProcessError as e:
                # Print FFmpeg error message if concatenation fails
                print(f"Error in {root}: {e.stderr.decode()}")
            finally:
                # Return to original directory and clean up temporary list file
                os.chdir(original_dir)
                if os.path.exists(list_file_path):
                    os.remove(list_file_path)


if __name__ == "__main__":
    # Update this path to point to your root data directory
    # The script will recursively search for 'My_WebCam' folders within this directory
    target_dir = r'C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\discrimination\ZZ363\D28'
    concatenate_with_ffmpeg(target_dir)