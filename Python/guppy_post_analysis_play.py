# -*- coding: utf-8 -*-
"""
Created on Mon Jun 13 15:12:04 2022

@author: Zach
"""
# %% imports
import h5py
import matplotlib.pyplot as plt
import numpy as np

#%% functions
def read_h5(fname):
# reads fib pho signal data
    with h5py.File(fname, "r") as f:
    # list all groups
        print("Keys: %s" % f.keys())
        a_group_key = list(f.keys())[0] 
    #get the data
        data = list(f[a_group_key])
    return data

def plot_fibpho(data, title='untitled'):
# plots fibpho data
    plt.plot(data)
    plt.title(title)
    plt.xlabel('frames')
    plt.ylabel('signal (AU')
    
def downsample(data, factor=10):
    ds_data = data[0::factor]
    return ds_data
    
#%% files
# meant to be pointed to guppy output files (hdf5)
sig_file = r'C:/Users/Zach/Documents/DP035_PMA-220519-111507/DP035_PMA-220519-111507_output_1/signal_ch.hdf5'
pc0_file = r'C:/Users/Zach/Documents/DP035_PMA-220519-111507/DP035_PMA-220519-111507_output_1/PC0_.hdf5'
zscore_file =  r'C:/Users/Zach/Documents/DP035_PMA-220519-111507/DP035_PMA-220519-111507_output_1/z_score_ch.hdf5'
tone_file = r'C:/Users/Zach/Documents/DP035_PMA-220519-111507/DP035_PMA-220519-111507_output_1/tone_ch.hdf5'
dff_file = r"C:\Users\Zach\Documents\DP035_PMA-220519-111507\DP035_PMA-220519-111507_output_1\dff_ch.hdf5"
ctrl_sig_fit_file = r"C:\Users\Zach\Documents\DP035_PMA-220519-111507\DP035_PMA-220519-111507_output_1\cntrl_sig_fit_ch.hdf5"

# %% get data
sig_data = read_h5(sig_file)
sig_ds = downsample(sig_data)
plot_fibpho(sig_ds, 'signal channel')

# get ctrl sig fit data
ctrl_sig_fit_data = read_h5(ctrl_sig_fit_file)
csfit_ds = downsample(ctrl_sig_fit_data)
plot_fibpho(csfit_ds,'ctrl sig fit data')

# get zscore data
z_data = read_h5(zscore_file)
z_ds = downsample(z_data)
plot_fibpho(z_ds, 'zscore signal')

# get dff data
dff_data = read_h5(dff_file)
dff_ds = downsample(dff_data)
plot_fibpho(dff_ds, 'dff data')

# pc0 file is ttl input. doesn't have same structure
#pc0_data = read_h5(pc0_file)

# %% test space
x = [1, 2, 3]
y = np.array([[1, 2], [3, 4], [5, 6]])
plt.plot(x, y)

plt.plot(z_ds)
plt.plot(dff_ds)
