# -*- coding: utf-8 -*-
"""
Created on Thu Apr  8 08:02:56 2021

@author: Zach
"""

#%% import modules
import pandas as pd
import seaborn as sns

#%% load data
#df_all = pd.read_csv(r'C:/Users/Zach/Documents/Python Scripts/Work/datasets/TeA inhibition pilot/sameContext/summary_freezing.csv')
df_avg = pd.read_csv(r"D:\fc pl tea cohort2 recent\analysis summary_frz20\summary_freezing_avg.csv")

#%% rename columns
colnames = ['id','condition','event','freezing']
df_all.columns = colnames
df_avg.columns = colnames

#%%
df_test = pd.DataFrame()