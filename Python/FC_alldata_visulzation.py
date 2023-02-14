# -*- coding: utf-8 -*-
"""
Created on Wed Mar 30 15:04:43 2022

@author: Zach
"""

# %% import modules
import pandas as pd
import scipy as sp
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

# %% load data
df = pd.read_csv(r"C:\Users\Zach\Desktop\summary_freezing.csv")

# %% clean data
df = df.dropna(axis=0, how='all')

# %% group data into rows for unique subject x event
# make empty dataframe for reorganized data
df2 = pd.DataFrame(columns = ['ID', 'event', 'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'])

# get unique ids and events
unique_id = pd.unique(df['ID'])
unique_event = pd.unique(df['event'])


# go through data and get all values for all unique combos of ID and event
for i in unique_id:
    for e in unique_event:
        hit = df['ID'].str.fullmatch(i) & df['event'].str.fullmatch(e)
        hit = hit[hit].index
        vals = df.loc[hit, ['freeze percent']].T.to_numpy()
        
        this_row = pd.DataFrame(columns = ['ID', 'event', 'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'],
                                index=range(1))
        this_row['ID'] = i
        this_row['event'] = e
        
        idx = 0
        for v in range(len(vals[0])):
            this_row.iloc[0,2+v] = vals[0,v]
        
        df2 = pd.concat([df2, this_row])
        
# go through df2 and create new col for laser
laser_ind = df2['event'].str.contains('laser')

# add new col in df2 for laser values
df2.insert(loc=2, column='laser', value=laser_ind)
# %% alternate approach:  rename events to have unique identifiers
df_melt = df2.melt(id_vars =['ID','event','laser'], value_vars =['e1','e2','e3'])
df_melt = df_melt.rename(columns={"variable" : "num", "value" : "freeze"})

# %% make plots for single animal
# mouse ID
mID = 'ZZ089_D28'
# event of interest
e0 = 'csp'

# get subset of data to plot
df_mouse = df_melt[df_melt['ID'] == mID]
df_plot = df_mouse[df_mouse['event'].str.contains(e0)]

# %% generate plot for one animal --- NOTE:cannot be run line by line, must be run altogehter, otherwise multiple plots will be generated
sns.lineplot(data=df_plot, 
                    x="num", 
                    y="freeze", 
                    hue="laser")
plt.title('test title')
plt.ylim(0, 1)


# %% generate plot across animals --- NOTE:cannot be run line by line, must be run altogehter, otherwise multiple plots will be generated
# plot across animals, all CS+, separated by laser

df_plot = df_melt[df_melt['event'].str.contains(e0)]

sns.lineplot(data=df_plot, 
                    x="num", 
                    y="freeze", 
                    hue="laser")
plt.title('test title')
plt.ylim(0, 1)

# %% make plot across animals
