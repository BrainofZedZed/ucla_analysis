# -*- coding: utf-8 -*-
"""
Created on Tue Apr 12 16:35:26 2022

@author: Zach
"""

# %% FC_posthoc_analysis_batch
# % batch version of script

#% ASSUMPTIONS:
#% 1) BehDEPOT was used to do cued analysis, with CS+ labeled as "CSp", CS-
#% as "CSm", laser as "laser", shock as "shock"
#% 2) BehDEPOT output folder is labeled '*_analyzed' and resides within
#% animal folder, which contains video, .mat experiment file, and CSV DLC
#% output

#%INSTRUCTIONS: 
#% Point to grandparent folder, containing individual animals organized as
#% described above. Let run. Creates 'out_all' and 'out_avg' table, with
#% freezing rates for different events

# %% IMPORTS
import os
import glob

# %% BATCH SETUP
path = r"C:\Users\Zach\Box\Zach_repo\Projects\Remote memory\TeA inhibition\pilot cohorts\TeA inhibition cohort2\cohort 2 0_1_2d\batch\0d ctrl"
path_wc = path + "\**\*_analyzed" # add search area:  ** indicates any number of subdir
analyzed_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

os.chdir(analyzed_dirs[0])  # change dirs to behdepot output
path_parent = os.path.dirname(os.getcwd())
os.chdir(path_parent)

