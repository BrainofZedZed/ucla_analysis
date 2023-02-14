# -*- coding: utf-8 -*-
"""
A Python replication of the Matlab-based MiniPC

"""

# %% imports 
import numpy as np
from loadmatfile import loadmat
import matplotlib.pyplot as plt
import MiniPyceCell_functions as mpcfun


# %% set things up
# path to data files.  NB: on windows, the path needs to be preceeded by an r
path_dict = {
    'ca_data_path' : r"C:\Users\KMLabZZ\Python scripts\MiniPYC\misc089 data\msCam_data_processed_v7.mat",
    'ms_timestamp' : r'C:\Users\KMLabZZ\Python scripts\MiniPYC\misc089 data\timestamp_ms.dat',
    'beh_timestamp' : r'C:\Users\KMLabZZ\Python scripts\MiniPYC\misc089 data\timestamp_beh.dat',
    'loc_track_dir' : r'G:\cohort3\3_22_2020\behavior\89 simplex training behavior',
    }


gen_params = {
    'px2cm' : 8, # pixel to cm conversion
    'binsz' : 2.5, # size of bin (cm x cm) for spatial layout
    'spdreq' : 2.5, # min instantaneous speed in cm/s for inclusion in spatial information
    'fps_beh' : 30, # fps of behavcam 
    'numshuf' : 500, # number of shuffles for spatial info analysis
    'do_raw_ca2' : False,  # choose to use raw (true) or deconvolved (false) data
    'dosave' : True,
    'normal_arena': True,
    'alt_vid_dim' : []
    }

# params for the videos
vid_params = {
    'frame_beh_sync' : 471,  # behavcam frame with sync cue
    'frame_aligncam_sync' : 715, # aligncam frame with sync cue
    'frame_start': 1094,  # frame (wrt behavior camera) to begin on ([] = beginning)
    'frame_end' : [], # frame (wrt behavior camera) to begin on ([] = end)
    'mscam_num' : 0,  # number ID of miniscope camera
    'aligncam_num': 1, # number ID of alignment camera (if used)
    'behavcam_num': 0,   # numver ID of behavior camera
    }

# enter animal and session id
id_dict = {
    'id' : '87s',
    'session' : 'test'
    }


# %% load calcium data from minipipe
matdata = loadmat(path_dict['ca_data_path'])
vid_params.update({'fps_orig' : matdata['Params']['Fsi']})
vid_params.update({'fps_new' : matdata['Params']['Fsi_new']})

if gen_params['do_raw_ca2'] == True:
    sigfn = matdata['sigfn']
else:
    sigfn = matdata['spkfn']

nn =  sigfn.shape[0]   

# %% align timestamps for behavcam and mscam
print('Aligning behavior and miniscope frames')
ms2behframe = mpcfun.alignTimestamps(vid_params, gen_params, path_dict)

# %% load behavior data
locs = mpcfun.loadBehTrack(path_dict)

# take only relevant frames
print('Cropping data to only examine relevant time periods')
sigfn_x, locX = mpcfun.trimRecording(locs, vid_params, sigfn, ms2behframe) 
        
    
# %% look for tracking errors and remove points
print('Looking for overt tracking errors')
sigfn_x, loc_x = mpcfun.speedTrap(locX, sigfn_x, gen_params, vid_params, id_dict)


# %% bin space and make activity maps
print('Binning and summating spatial and neural activity')
mpcfun.binNFire(sigfn_x, locX, gen_params, vid_params)
#START HERE AND IMPLEMENT GAUSSIAN BLURRING IN FUNCTION

# %%
def plotca(sigfn):
    for c in range(sigfn.shape[0]):
        c_sig = sigfn[c,:]
        c_sig = c_sig / np.max(c_sig)  # normalize to max value of sig, so range is [0 1]
        c_sig = c_sig + c
        plt.plot(c_sig)
        
    plt.ylabel('Cell #')
    plt.xlabel('Frame #')
    plt.show()
    
    