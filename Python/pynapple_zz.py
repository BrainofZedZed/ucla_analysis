# -*- coding: utf-8 -*-
"""
Created on Tue May 17 16:43:03 2022

@author: Zach
"""

#%% imports
import pynapple as nap

#%% load data
data_directory = r'C:\Users\Zach\Box\Zach_repo\Projects\Remote memory\Miniscope data\PL_TeA cohort1\hab1\17_04_12\My_V4_Miniscope\0_4'
data = nap.load_session(data_directory, 'minian')

