# -*- coding: utf-8 -*-
"""
Saves cell footprints from MiniAn output in MATLAB format
"""

import xarray as xr
import numpy as np
import scipy.io

sig = xr.open_zarr(r'C:\Users\Zach\Downloads\C.zarr')
sig_dict = sig.to_dict()
footprints = spatial_dict['data_vars']['A']['data']
fp_dict = {'footprints' : footprints}
scipy.io.savemat('footprints_updated.mat', fp_dict)