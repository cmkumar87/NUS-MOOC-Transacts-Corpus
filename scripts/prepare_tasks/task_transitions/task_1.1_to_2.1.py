#!/usr/anaconda3/bin/python

import pandas as pd
import numpy as np
import re
import sys
import argparse

""" Converts Task 1.1 output file from mturk to get marked posts to forward to Task 2.1 """

parser = argparse.ArgumentParser()
parser.add_argument("--file", "-f", type=str, required=True) 
args = parser.parse_args()

# Import Task 1.1 file
df = pd.read_csv(args.file)
df = df.loc[df['AssignmentStatus'] != 'Rejected'] # Take only the raters that were approved
threads = df['Input.threadtitle'].unique() #List unique threads
entries = []


for thread in threads:
    filter_col = [col for col in df if col.startswith('Answer')] # Get only columns that have "Answer" in col name
    counts  = (df.loc[df['Input.threadtitle']==thread, \
            filter_col].count(axis=0))
    if counts['Answer.noreply']!=7:
        del counts['Answer.noreply']
        counts_sorted= (counts.sort_values(ascending=False))

        if counts_sorted.iloc[1]>=counts.iloc[0]-2:
            #print(counts_sorted.iloc[:2])
            m=','.join( [(re.findall(r"[0-9]",i)[0]) for i in  counts_sorted.iloc[:2].index.values])
            m=np.array(m)

            entry = (''+ str(thread.translate(str.maketrans({"'": r"\'"}))) +'' \
                    + ': ' \
                    + str( m.ravel()[0]) + \
                            '')
        else:
            #print(counts_sorted.iloc[:1])
            m= re.findall(r"[0-9]", \
                    counts_sorted.iloc[:1].index.values[0])
            entry= (''+str(thread.translate(str.maketrans({"'": r"\'"})))+''    \
                    +': '+ str( m[0])+'')
        entries.append(entry)

# Send the most marked entries to Task 2.1 
#print('(')
for i in entries:
    print(i)
#print(')')
