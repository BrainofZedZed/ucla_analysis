# -*- coding: utf-8 -*-
"""
Created on Thu Oct 27 15:25:09 2022

@author: Zach
"""

# %% imports
import mat4py
import numpy as np
import scipy.stats as stats
import pickle
from scipy import interpolate


import plotly.express as px
# this code is needed to make Plotly render in browser, because these plots don't work within Spyder Notebook IDE
import plotly.io as pio
#pio.renderers.default='browser' # this line renders in browser and is interactive

pio.renderers.default='svg' # this line renders in Spyder and is static
# %%  supporting functions
def align_ms_beh_interp(ms_tsfile, beh_tsfile, sig, behsize):
    """
    

    Parameters
    ----------
    ms_tsfile : csv file
        file from V4 miniscope containing timestamp info for acquired frames.
    beh_tsfile : csv file
        file from behavior camera containing timestamp info for acquired frames.
    sig : numpy matrix
        [frame x neuron] matrix containing calcium signal data.
    behsize : int
        length of behavior frames to interpolate sig.

    Returns
    -------
    sig_interp:  interpolated calcium frames to match behsize

    """
    import pandas as pd
    import numpy as np
    ms_ts = pd.read_csv(ms_tsfile)
    beh_ts = pd.read_csv(beh_tsfile)
    
    ms_ts2 = ms_ts.iloc[:,1]
    beh_ts2 = beh_ts.iloc[:,1]
    
    nn = sig.shape[1]

    # for each miniscope frame find nearest behavior frame
    ms_to_beh = np.zeros([len(ms_ts2),2])
    for i in range(len(ms_ts2)):
        t = ms_ts2[i]
        ms_to_beh[i,1] = np.argmin(np.abs(beh_ts2-t))
        ms_to_beh[i,0] = i
        
    new_sig=np.empty([behsize,nn])
    new_sig[:,:] = np.nan
    for n in range(nn):
        for i in range(len(ms_ts2)):
            new_sig[ms_to_beh.astype(int)[i,1],n] = sig[i,n]

    new_sig_df = pd.DataFrame(new_sig)
    sig_interp = new_sig_df.interpolate(method='linear', axis=0)
    sig_interp = sig_interp.to_numpy()
    return sig_interp
# %% 
# load matlab data using loadmat. MATLAB data loaded as python dictionaries
beh_mat_file = r"C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\PL_TeA cohort1\bdbatch\ZZ087_caroc\ZZ087_D28\D28_analyzed\Behavior.mat"
ms_data_file = r"C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\PL_TeA cohort1\bdbatch\ZZ087_caroc\ZZ087_D28\minian_data_processed.mat"
ms_ts_file = r"C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\PL_TeA cohort1\D28 miniscope\13_25_24\My_V4_Miniscope\timeStamps.csv"
beh_ts_file = r"C:\Users\Zach\Box\Zach_repo\Projects\Remote_memory\Miniscope data\PL_TeA\PL_TeA cohort1\D28 miniscope\13_25_24\My_WebCam\timeStamps.csv"

behdata = mat4py.loadmat(beh_mat_file)
ms_data = mat4py.loadmat(ms_data_file)

# %%
# access data of interest
frz_vec = behdata["Behavior"]["Freezing"]["Vector"]
csp_vec = behdata['Behavior']['Temporal']['csp']['Vector']
csm_vec = behdata['Behavior']['Temporal']['csm']['Vector']

# combine into list
beh_vec_names = ["Freezing","CSp","CSm"]
beh_vecs = np.vstack([frz_vec, csp_vec, csm_vec])
beh_vecs = beh_vecs.transpose()
nbehs = beh_vecs.shape[1]

# convert lists to arrays
frz_vec = np.array(frz_vec)
csp_vec = np.array(csp_vec)
csm_vec = np.array(csm_vec)

sig_og = ms_data['dff']
sig_og = np.array(sig_og)
sig_og = np.transpose(sig_og)

# get common numbers
nn = sig_og.shape[1]  # number of neurons
nf = frz_vec.shape[0] # number of behavior frames

# %% align and interpolate calcium signals to match behavior frames
sig = align_ms_beh_interp(ms_ts_file, beh_ts_file, sig_og, nf)

# generate some plots
fig = px.line(sig_og[:,0]) 
fig.update_layout(xaxis_title="Frame", yaxis_title="sig [au]", title_text="example calcium signal (cell 0) - pre alignment, interpolation")
fig.show()

fig = px.line(sig[:,0]) 
fig.update_layout(xaxis_title="Frame", yaxis_title="sig [au]", title_text="example calcium signal (cell 0) - post alignment, interpolation")
fig.show()


# %% # Step 1:  Process signal
#Goal is to filter high frequency activity, look for large (> 2SD) amplitude signals, then look for rising periods. Signal periods satisfying those criteria are binarized.
# find rising periods by looking for positive difference
sig_diff = np.diff(sig,axis=0)

# add an extra row to compensate for the off by 1 
tmp = np.ones(sig.shape[1])
sig_diff = np.vstack((sig_diff, tmp))

# visualize
fig = px.line(sig_diff[:,0])
fig.update_layout(xaxis_title="Frame", yaxis_title="sig", title_text="signal difference (approximation of derivative) of cell 0")
fig.show()

# %% find indices that are positive, reflecting increase in signal, and signal is large, reflecting meaningful signal

# find postitive
pos_diff = np.zeros(sig_diff.shape)
for i in range(sig_diff.shape[1]): # for each cell
    for j in range(sig_diff.shape[0]):
        if sig_diff[j][i] > 0:
            pos_diff[j][i] = 1
            
zsig = stats.zscore(sig)

# find large signals
big_sig = np.zeros(sig.shape)
for i in range(sig.shape[1]):
    for j in range(sig.shape[0]):
        if zsig[j][i] > 2:
            big_sig[j][i] = 1
            
# find periods where sig is increasing AND sig is large
bin_sig = np.zeros(sig.shape)
bin_sig = pos_diff + big_sig
bin_sig[bin_sig<2] = 0
bin_sig[bin_sig==2] = 1

# visualize
fig = px.line(bin_sig[:,0]) 
fig.update_layout(xaxis_title="Frame", yaxis_title="large positive signal present", title="Rising periods with >2SD signal of cell 0")


# %% Step 2:  Calculate probabilities:  activity, behavior state, joint probability
# calculate probability of neuron being active (marginal likelihood)
p_active = np.zeros(bin_sig.shape[1])
for i in range(bin_sig.shape[1]):
    p_active[i] = np.sum(bin_sig[:,i] / bin_sig.shape[0])

# visualize overall activity levels (y axis) of each neuron (x axis)
fig = px.scatter(p_active)
fig.update_layout(title="activity probability of all neurons", xaxis_title ="neuron ID", yaxis_title="proportion frames active")

# probability of behavior states (ie prior probability)
p_state = np.zeros(nbehs)
for i in range(nbehs):
    p_state[i] = np.sum(beh_vecs[:,i]) / nf
    

# calculate joint probability (time neuron is active in state relative to total time)
p_sa = np.zeros([nn,nbehs])
for b in range(nbehs):
    for n in range(nn):
        tmp = beh_vecs[:,b] + bin_sig[:,n]
        tmp[tmp<2] = 0
        tmp[tmp==2] = 1
        p_sa[n,b] = np.sum(tmp) / nf
        
# compute tuning curve (time neuron is active while in state, relative to total state time)
p_as = np.zeros([nn,nbehs])
for b in range(nbehs):
    for n in range(nn):
        tmp = beh_vecs[:,b] + bin_sig[:,n]
        tmp[tmp<2] = 0
        tmp[tmp==2] = 1
        p_as[n,b] = np.sum(tmp) / np.sum(beh_vecs[:,b])





