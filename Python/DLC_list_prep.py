# -*- coding: utf-8 -*-
"""
Created on Sun Jun 26 16:12:10 2022

@author: DeNardoLab1
"""

# -*- coding: utf-8 -*-
"""
Created on Fri Feb 18 08:52:45 2022

@author: Zach

GOAL:  creates cmd commands to get all videos with certain title for use in DLC

USE: edit path to be grandparent directory folder to search within all subdir.
edit path_wc to include name of file you want to get path of"""
#%%  imports
import glob  # used to search for files
import ntpath # alternative to os.path that is OS agnostic

#%%  create output
path = r"C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\miniscope data_revision\TeNT"  # define path
path_wc = path + "\**\concat_beh.avi" # add search area:  ** indicates any number of subdir
cam_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

final_out = ''
line = ''

for x in cam_dirs:
    line = 'r"' + x + '",\n'
    final_out = final_out + line
    
#%% save
with open(path + '\\to_dlc.txt', 'w') as f:
    f.write(final_out)
