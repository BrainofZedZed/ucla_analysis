# -*- coding: utf-8 -*-
"""
Created on Wed Mar 24 09:07:07 2021

@author: Zach
"""
# import pandas
import pandas as pd
import matplotlib.pyplot as plt

# read in data
df = pd.read_excel(r"C:/Users/Zach/Box/Zach_repo/Projects/DA PMA/VTA-PL PMA inhibition pilot 022521/RTPP/RTPP results_v2.xlsx")
print(df)
df.head()
# forgot a genotype group, so declare the genotype values
gt = ['control','control', 'jaws','jaws','jaws','jaws','jaws','jaws']

# add the list as a new column in the dataframe
df['genotype'] = gt

#verify
print(df)

#plot
df.plot(x="genotype",y="change in NoStim:Stim")

# create different df with just data I want to use
df_vel = df[df.columns[1:4]]

# plot parallel lines using parallel_coordinates
fig = pd.plotting.parallel_coordinates(df_vel,'cond')

# add labels
fig.set_xlabel('baseline vs light on')
fig.set_ylabel('NoStim:Stim duration ratio')
fig.set_title('RTPP Duration')

# plot parallel lines using parallel_coordinates
ax = pd.plotting.parallel_coordinates(df_vel,'cond')

# add labels
ax.xlabel('baseline vs light on')
ax.ylabel('NoStim:Stim duration ratio')
ax.title('RTPP Duration')
