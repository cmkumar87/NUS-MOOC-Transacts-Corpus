#!/usr/anaconda3/bin/python

import pandas as pd
import numpy as np
import re
import sys
import argparse

""" Converts Task 2.1 output file from mturk to get marked posts to forward to Task 2.2"""
parser = argparse.ArgumentParser()
parser.add_argument("--file", "-f", type=str, required=True)
args = parser.parse_args()

# Import Task 2.1 file
df = pd.read_csv(args.file)
df = df.loc[df['AssignmentStatus'] != 'Rejected'] # Take only the raters who are approved
threads = df['Input.threadtitle'].unique()	# List of unique threads 
entries = []
forward = ['resolves','elaborates'] # Only forward these two categories
for thread in threads:
    filter_col = [col for col in df if col.startswith('Answer')]
    maxes = np.array(df.loc[df['Input.threadtitle']==thread,filter_col].mode())
    maxes = np.delete(maxes, -1, axis=1)
    #print(maxes[0])

    # Print thread name with marked post and category to forward
    
    print(thread, end = ': ')
    [print(str(i+1)+','+str(word), end=' ') for i,word in enumerate(maxes[0]) if word in forward]
    print('\n')
