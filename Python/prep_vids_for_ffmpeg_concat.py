# -*- coding: utf-8 -*-
"""
Created on Fri Feb 18 08:52:45 2022

@author: Zach

GOAL:  uses ffmpeg to concat all miniscope behavior videos, compress them,
and then delete the original (large) concatenation.
Assumes default directory structure of miniscope recorded videos.

USE: edit path to be grandparent directory folder of with all the 'My_WebCam'
folders somewhere down that path.
"""
#%%  imports
import glob  # used to search for files
import ntpath # alternative to os.path that is OS agnostic
import natsort # for function natsorted
import subprocess  # for executing ffmpeg commands
import os  # for file deletion

#%%  create output
path = r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\TeNT" # define path
path_wc = path + "\**\My_WebCam" # add search area:  ** indicates any number of subdir
cam_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

# for each cam_dir, get list of all avi files and run ffmpeg
for j in range(len(cam_dirs)):  # loop through each dir
    i_dir = cam_dirs[j]
    if glob.glob(i_dir + "/*concat_beh*"):  # skip if concat_beh file already exists
        print(f"Skipping (already done): {i_dir}")
        continue
    avi_files = glob.glob(i_dir + "/*.avi")  # go through dir and get paths of all avi files
    
    filenames = [None] * len(avi_files)  # create an empty list of size avi_files
    for i in range(len(avi_files)):  # loop through the size of avi_files
        if len(ntpath.basename(avi_files[i])) > 6:
            continue
        filenames[i] = ntpath.basename(avi_files[i])  # assign filename to new list
    
    filenames_sorted = [f for f in natsort.natsorted(filenames) if f is not None]  # sort and drop Nones
    concat_str = '|'.join(filenames_sorted)  # build concat string
    
    print(f"Processing: {i_dir}")
    
    # Step 1: concat all clips into a lossless temp file
    cmd1 = ['ffmpeg', '-i', f'concat:{concat_str}', '-c', 'copy', 'temp.avi']
    subprocess.run(cmd1, cwd=i_dir, check=True)
    
    # Step 2: compress temp file into final concat_beh.avi
    cmd2 = ['ffmpeg', '-i', 'temp.avi', '-c:v', 'libx264', '-preset', 'fast', '-crf', '17', '-c:a', 'copy', 'concat_beh.avi']
    subprocess.run(cmd2, cwd=i_dir, check=True)
    
    # Step 3: delete the large temp file
    os.remove(os.path.join(i_dir, 'temp.avi'))
    print(f"Done: {i_dir}")

# %%
