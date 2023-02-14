# -*- coding: utf-8 -*-
"""
Created on Thu Jun 30 13:36:19 2022

@author: DeNardoLab
"""

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
import natsort # for function natsorted
import re

#%%  create output
path = r"C:\Users\DeNardoLab\Box\Zach_repo\Projects\Remote_memory\Miniscope data\miniscope cohort4"  # define path
path_wc = path + "\**\My_V4_Miniscope" # add search area:  ** indicates any number of subdir
cam_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

final_out = ''
line = ''

for x in cam_dirs:
   line = "\nfile_name = 'v0.avi';\npath_name =\'" + x + "\';\n[fname, frawname, fregname] = min1pipe_CUSTOM(Fsi, Fsi_new, spatialr, se, ismc, flag, file_name, path_name);\n"
   final_out = final_out + line
    
#%% save
with open('to_min1pipe.txt', 'w') as f:
    f.write(final_out)
