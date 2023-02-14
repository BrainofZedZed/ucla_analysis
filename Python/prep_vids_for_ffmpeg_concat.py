# -*- coding: utf-8 -*-
"""
Created on Fri Feb 18 08:52:45 2022

@author: Zach

GOAL:  creates cmd commands to use ffmpeg to concat all miniscope behavior 
videos, compress them, and then delete the original (large) concatenation.
Assumes default directory structure of miniscope recorded videos.

USE: edit path to be grandparent directory folder of with all the 'My_WebCam'
folders someone down that path. 'final_out' is char vector with commands.
"""
#%%  imports
import glob  # used to search for files
import ntpath # alternative to os.path that is OS agnostic
import natsort # for function natsorted

#%%  create output
path = r"G:\2023_02_09" # define path
path_wc = path + "\**\My_WebCam" # add search area:  ** indicates any number of subdir
cam_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

# for each cam_dir, get list of all avi files
out_full = ''  # initialize final output 
final_out = ''
for j in range(len(cam_dirs)):  # loop through each dir
    i_dir = cam_dirs[j]
    avi_files = glob.glob(i_dir + "/*.avi")  # go through dir and get paths of all avi files
    
    filenames = [None] * len(avi_files)  # create an empty list of size avi_files
    for i in range(len(avi_files)):  # loop through the size of avi_files
        if len(ntpath.basename(avi_files[i])) > 6:
            continue
        filenames[i] = ntpath.basename(avi_files[i])  # assign filename to new list
        
    filenames_sorted = natsort.natsorted(filenames) # natural language sort
    out_cat = ''  # initialize out string
    
    for x in filenames_sorted:
        out_cat = out_cat + x + '|'  # create string with bar between all names
    
    out_cat = out_cat[:-1] # remove last bar
    out_cat = 'ffmpeg -i "concat:' + out_cat + '"' + ' -c copy temp.avi \nffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi \n'  # put into ffmpeg command
    cd_line = 'cd ' + "\"" + i_dir + "\"" + '\n'
    del_line = 'del /f temp.avi\n\n'
    out_full = cd_line + out_cat + del_line
    final_out = final_out+out_full
    
#%% save

with open(path+'to_concat4.txt', 'w') as f:
    f.write(final_out)
