# functions for MiniPyceCell

import numpy as np
import matplotlib.pyplot as plt
from scipy.spatial import  distance
from scipy.ndimage import gaussian_filter as gaussfilt
import pandas as pd
from natsort import natsorted
import fnmatch
import os


# %%
def alignTimestamps(vid_params, gen_params, path_dict):
    """
    Gets synchronization info and aligns behavior cam to miniscope cam
    """
    
    # read timestamp files for behavcam and mscam
    behframes = pd.read_table(path_dict['beh_timestamp'])
    ms_ts = pd.read_table(path_dict['ms_timestamp'])
    
    # first frame is trash, BUT keep to adjust for zero indexing in Python
    behframes = behframes.drop(index=0)  # first frame is trash
    ms_ts = ms_ts.drop(index=0)
    
    # seperate out mscam frames and aligncam frames
    msframes = ms_ts.loc[ms_ts['camNum'] == vid_params['mscam_num']]
    alignframes = ms_ts.loc[ms_ts['camNum'] == vid_params['aligncam_num']]

    # drop frames that would be dropped if temporally downsampled during calcium video processing   
    # (does nothing if fps_orig == fps_new)
    ds = int(vid_params['fps_orig'] / vid_params['fps_new'])
    msframes = msframes.iloc[::ds,:]
    
    # get timestamp for frames with sync cue and find offset
    beh_sync_ts = int(behframes.sysClock.loc[behframes['frameNum'] == vid_params['frame_beh_sync']])
    align_sync_ts = int(alignframes.sysClock.loc[alignframes['frameNum'] == vid_params['frame_aligncam_sync']])
    offset =  beh_sync_ts - align_sync_ts
    
    # adjust behcam sysClock to match mscam sysClock
    behframes.sysClock = behframes.sysClock - offset

    # for each mscam frame, find closest behcam frame
    # create new array to hold corresponding beh frames
    ms2behframes = np.zeros([len(msframes),1], dtype=int)
    for f in range(len(msframes)):
        t = msframes.sysClock.iloc[f]
        dif = abs(behframes.sysClock - t)
        match = np.where(dif == min(dif))
        try:
            ms2behframes[f] = match
        except:
            match = match[0]
            match = match[0]
            ms2behframes[f] = match

    print('Aligned behavior and miniscope frames')

    return ms2behframes
    
# %%    
def loadBehTrack(path_dict):
    """ loads behavior data files and concatenates them """
    if os.path.isdir(path_dict['loc_track_dir']):
        dir_files = os.listdir(path_dict['loc_track_dir'])
        beh_files = fnmatch.filter(dir_files, '*LocationOutput.csv')  
        beh_files = natsorted(beh_files) # nat sort filenames of only tracking files

        # load and concatenate the tracking files
        mm = True        
        for f in beh_files:
            if mm == True:
                this_loc = pd.read_csv(os.path.join(path_dict['loc_track_dir'], f))
                locs = this_loc[['X', 'Y']]
                mm = False
            else:
                this_loc = pd.read_csv(os.path.join(path_dict['loc_track_dir'], f))
                this_loc = this_loc[['X', 'Y']]
                locs = locs.append(this_loc)
                
    else:
        raise FileNotFoundError('{path} not found. Double check it is correct'.format(path=path_dict['loc_track_dir']))
        
    return locs

# %%
def trimRecording(locs, vid_params, sigfn, ms2behframe):
    """ reduces the data (calcium & behavior) only to parts of interest """
    
    # find miniscope frame corresponding to behavior frame
    # because not all behavior frames align with miniscope frames, need to find 
    # closest beh frame to specified start frame
    if vid_params['frame_start'] != []:
        dif = abs(ms2behframe - vid_params['frame_start'])
        match1 = np.where(dif == min(dif))
        match1 = match1[0][0]
    else:
        match1 = 0
        
    if vid_params['frame_end'] != []:
        dif = abs(ms2behframe - vid_params['frame_end'])
        match2 = np.where(dif == min(dif))
        match2 = match2[0][0]
    else:
        match2 = sigfn.shape[1]
        
    # trim calcium and behavior info
    sigfn_x = sigfn[:,match1:match2]
    ms2behframe = ms2behframe[match1:match2]
    ms2behframe = ms2behframe.reshape(len(ms2behframe))
    
    locX = locs.iloc[ms2behframe]
    locX = locX.reset_index()
    locX = locX.rename(columns={'index' : 'orig_beh_frame'})
    
    # recalcuate distance
    d = np.zeros(len(locX))
    xy = np.array(locX[['X','Y']])
    
    for i in range(len(locX)-1):
        pt = [xy[i], xy[i+1]]
        d[i+1] = distance.pdist(pt)
        
    locX['Distance'] = d
        
        
    return sigfn_x, locX
    
# %% 
def speedTrap(locX, sigfn_x, gen_params, vid_params, id_dict):
    """ looks for frames with very high distance and removes them with adjacent frames"""
    
    spdlim = 100 # in cm/s
    spdlim = spdlim * gen_params['px2cm'] / vid_params['fps_new'] # convert spdlim to px/frame
    
    speeders = np.where(locX['Distance'] > spdlim)
    speeders = speeders[0] # np.where returns two values, we only want the first

    if speeders.size > 0:
        print('Tracking errors likely occurred. Number of unreasonably fast frames:')
        print(len(speeders))
        print('Now removing offending frames plus adjacents. Double check tracking integrity.')
        speeders_up = speeders + 1
        speeders_down = speeders - 1
        speeders = speeders.append(speeders, speeders_down)
        speeders = speeders.append(speeders, speeders_up)
        
        sigfn_x = np.delete(sigfn_x, speeders, axis=1)  #remove speeding frame and adjacent ones
        locX = locX.drop(labels = speeders, axis = 0)  
    else:
        print('No overt tracking errors found')
        
    colors = np.linspace(1,100,len(locX['Distance']))
    plt.scatter(locX['X'], locX['Y'], s=10, c=colors)
    plt.title('Location tracking of ' + id_dict['id'] + ' ' + id_dict['session'])
    return sigfn_x, locX


# %%
def binNFire(sigfn_x, locX, gen_params, vid_params):
    """ divide arena into bins, generate spatial and signal bin counts """
    # convert instantaneous speed requirement to from cm/s to px/frame, then drop slow frames from spatial info consideration
    spdreq = gen_params['spdreq'] * gen_params['px2cm'] / vid_params['fps_new']
    slow_frames = np.where(locX['Distance'] < spdreq)
    slow_frames = slow_frames[0]
    sigfn_fp = np.delete(sigfn_x, slow_frames, axis=1)
    loc_fp = locX.drop(labels=slow_frames, axis=0)
    
    # generate empty grids to hold location and activity counts
    if gen_params['normal_arena'] == True:
        bin_sz = round(450/(gen_params['binsz']*gen_params['px2cm']))
        grid_count = np.zeros((bin_sz, bin_sz))
        sig_count = np.zeros((bin_sz, bin_sz, len(sigfn_fp)))
    else:
        sz = gen_params['alt_vid_dim']
        bin_sz = round(sz/(gen_params['binsz']*gen_params['px2cm']))
        grid_count = np.zeros((bin_sz, bin_sz))
        sig_count = grid_count
    
    # sum number of frames spent in each bin
    for i in range(len(loc_fp)):
        i_x_bin = int(loc_fp.iloc[i]['X'] // bin_sz)
        i_y_bin = int(loc_fp.iloc[i]['Y'] // bin_sz)
        grid_count[i_x_bin][i_y_bin] += 1
      
    # sum activity in each bin for each cell
    for i_c in range(len(sigfn_fp)):
        for i_f in range(len(loc_fp)):
             i_x_bin = int(loc_fp.iloc[i_f]['X'] // bin_sz)
             i_y_bin = int(loc_fp.iloc[i_f]['Y'] // bin_sz)
             sig_count[i_x_bin][i_y_bin][i_c] += sigfn_fp[i_c][i_f]
             
    # apply Gaussian to smooth maps
    
    
# %%