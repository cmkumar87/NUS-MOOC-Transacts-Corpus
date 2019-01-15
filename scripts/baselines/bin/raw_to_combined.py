import numpy as np
import pandas as pd
import os,glob
import argparse
import re,sys,csv
csv.field_size_limit(sys.maxsize)

def get_broad_categories(df,combined=False):
    cats = { 0:'none',1: 'social', 2: 'requests',3: 'resolves', 4:'elaborates'}

    df = df.loc[df['AssignmentStatus'] != 'Rejected'] # Take only the raters who are approved
    threads = df['Input.threadtitle'].unique()	# List of unique threads
    fc_orig = filter_col = [col for col in df if col.startswith('Answer')]
    cols = ['Course','Input.threadtitle','Input.posts','Input.inst_post']
    thread_entries = [[df['Course'].iloc[0]]*len(threads) ,pd.Series(threads), pd.Series(df['Input.posts'].unique()),pd.Series(df['Input.inst_post'].unique())]
    entries = pd.DataFrame()
    cols.extend(filter_col)

    for c in range(len(cols)):
        if c<len(thread_entries):
            entries[cols[c]] = thread_entries[c]
        else:
            entries[cols[c]]=None

    #print(entries)
    for thread in threads:
        filter_col = fc_orig
        #post_with_max_markings = (np.argmax(np.array(df.loc[df['Input.threadtitle']==thread,filter_col].count())))
        maxes = np.array(df.loc[df['Input.threadtitle']==thread,filter_col].mode())
        #print(maxes)
        for f in range(len(filter_col)):
            entries.loc[entries['Input.threadtitle']==thread,filter_col[f]] = maxes[0][f]
    if combined:
        t =  entries.loc[entries['Input.threadtitle']==thread,filter_col].reset_index(drop=True).iloc[0]
        for x in range(len(t)):
            for k,v in cats.items():
                if t[x]==v:
                    t[x]= k
        # Get the deepest category from all the categories agreed upon in the post marked
        imp = (max([x for x in t if isinstance(x,int)]))
        entries['Categories']=cats[imp]
    return entries

if __name__=="__main__":
    #Set the folder with all the Task 2.1 course outputs
    files = glob.glob('./2.1/*.csv')
    parser = argparse.ArgumentParser()
    #Alternatively, give filename for the file to generate result for
    parser.add_argument("--file", "-f", type=str, required=False)
    args = parser.parse_args()
    df = pd.DataFrame()
    # Set combine = True to get the deepest category (which is most agreed upon) among all posts marked.
    # If False, gives most agreed category per post
    combine = True
    if args.file:
        temp = pd.read_csv(args.file)
        course_name =re.findall(r'^([^.]+)',args.file[6:])[0] 
        temp['Course'] = [course_name]*len(temp)
        df = get_broad_categories(temp,combine)
    else:
        for f in files:
            print('Reading ' + str(f))
            course_name=re.findall(r'^([^.]+)',f[6:])[0]
            print(course_name)
            temp = pd.read_csv(f, engine='python')
            temp['Course'] = [course_name]*len(temp)
            temp_res = get_broad_categories(temp, combine)
            df = df.append(temp_res, ignore_index=True)
    print(df.shape)
    #print(df)
    if combine:
        cols = [col for col in df if col.startswith('Answer')]
        df = df.drop(cols, axis=1)
        df.to_csv('results_combine.csv')
    else:
        df.to_csv('results_original.csv')
