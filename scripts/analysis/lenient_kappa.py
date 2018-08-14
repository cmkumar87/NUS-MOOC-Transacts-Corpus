import numpy as np
import pandas as pd
import os,re,sys,warnings
import glob, argparse
from statsmodels.stats.inter_rater import aggregate_raters
import mysql.connector, sqlite3
pd.options.mode.chained_assignment = None

"""Calculates Lenient Fleiss Kappa for given input file and course ID

Run: python lenient_kappa.py -f= **file name** -c=**course id**"""

class fleiss_kappa:
        def __init__(self,data):
                self.data = data

        def calc_fleiss_kappa(self):

                #From http://www.statsmodels.org/dev/stats.html
                warnings.simplefilter("error", RuntimeWarning)
                table = 1.0 * np.asarray(self.data)   #avoid integer division
                self.n_sub, self.n_cat =  table.shape
                self.n_total = table.sum()
                self.n_rater = table.sum(1)
                self.n_rat = self.n_rater.max()
                assert self.n_total == self.n_sub * self.n_rat

                self.p_cat = table.sum(0) / self.n_total
                #print(table)
                self.table2 = table * table
                self.p_rat = (self.table2.sum(1) - self.n_rat) / (self.n_rat * (self.n_rat - 1))
                self.p_mean = self.p_rat.mean()

                self.p_mean_exp = (self.p_cat*self.p_cat).sum()
                # print(self.p_cat)
                # print(self.p_mean,self.p_mean_exp)
                try:
                    #print(self.p_mean,self.p_mean_exp)
                    kappa = (self.p_mean - self.p_mean_exp) / (1- self.p_mean_exp)
                        
                    
                except RuntimeWarning:
                    kappa = 1.0
                   
                return kappa

        def calc_std_dev(self):

#From https://i1.wp.com/www.real-statistics.com/wp-content/uploads/2013/11/image102c.png

                self.var_num_1 = (self.p_mean_exp - (2*self.n_rater-3)*(self.p_mean_exp)**2)
                self.var_num_2 = 2*(self.n_rater-2)*(self.p_cat**3).sum()
                self.var_num = 2*(self.var_num_1+self.var_num_2)
                self.var_den = self.n_rater*self.n_sub*(self.n_rater-1)*(1-
                        self.p_mean_exp)**2
                var = self.var_num/self.var_den
                return math.sqrt(var[0])


def get_kappa_marking(df):
    df = df.loc[df['AssignmentStatus'] != 'Rejected']
    threads = df['Input.threadtitle'].unique()
    entries = []
    fks = []

    for thread in threads:
        filter_col = [col for col in df if col.startswith('Answer')]
        counts = (df.loc[df['Input.threadtitle'] == thread, \
            filter_col].count(axis = 0))
        
        counts_sorted = (counts.sort_values(ascending = False))
        
        post_max_agreement = np.argwhere(counts == np.max(counts)).flatten().tolist()
        #print(post_max_agreement)
        post_max_agreement = ((counts.iloc[post_max_agreement].index.values))
        
        df = df.replace('unclear',99)
        df = df.replace('none',99)
        conn = sqlite3.connect('cs6207.db')
        c = conn.cursor()
        try:
            c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id where original=1 and post2.courseid like '+'"%%'+course+'%%"'+' and thread.title like '+'"%%'+thread+'%%"')
            thread_id = c.fetchone()
            #print(thread_id)
            c.execute('select count(1) from post2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and courseid like '+'"%%'+course+'%%"' )

            post2 = c.fetchone()
            c.execute('select count(1) from comment2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and courseid like '+'"%%'+course+'%%"' )
            comment2 = c.fetchone()
            length = post2[0]+comment2[0]
            #print(length)
            df1 = df.loc[df['Input.threadtitle'] == thread]
            df2 = pd.DataFrame()
          # print(df1[post_max_agreement])
            for p in (post_max_agreement):
                #print(p)
                df2['Agree'+str(p)] = df1.loc[:,p].fillna(0).astype(bool).astype(int)
                #df2['Disagree' + str(p)] = ~df2['Agree'+ str(p)]
            for i in range(length-len(post_max_agreement)):
                df2['Disagree'+str(i)] = 0
            
            #print(df2)

            aggregate = aggregate_raters(df2.T)
            fk = fleiss_kappa(aggregate[0])
            #print(aggregate)
            fks.append(fk.calc_fleiss_kappa())
            print(thread+ "("+str(length)+")"+" -- "+str(fk.calc_fleiss_kappa())+"\n")
        except:
            pass    
           
    print("Average Kappa:"+str(np.mean(fks)))


def get_kappa_categorization(df):
    df = df.loc[df['AssignmentStatus'] != 'Rejected']
    threads = df['Input.threadtitle'].unique()
    entries = []
    fks = []
    cat_to_num_2 = { # Categories for Task 2.1
                      "resolves":1,
                      "elaborates":2,
                      "requests":3,
                      "social":4,
                      "none":99,
                      #Categories for Task 2.2
                      "clarifies":5,
                      "extension":6,
                      "juxtaposition":7,
                      "refinement":8,
                      "critique":9,
                      "agreement":10,
                      "disagreement":11,
                      "generic":12,
                      "appreciation":13,
                      "completion":14,
                      "nota":99,
                }

    if 'Answer.noreply' not in df.columns:
        df['Answer.noreply'] = ""
    marked_posts = [col for col in df.columns if 'Answer.' in col]
    #print(marked_posts)
    for post in marked_posts:
        df[post] = df[post].map(cat_to_num_2).fillna(0).astype(int)

    for thread in threads:
        filter_col = [col for col in df if col.startswith('Answer')]
        df1 = df[filter_col]
        df[filter_col] =df[filter_col].replace(0, np.nan)
        counts = (df.loc[df['Input.threadtitle'] == thread, \
            filter_col].count(axis = 0))
        #Ignore the 'none's unless everyone has answered that
        if counts['Answer.noreply']!=df.loc[df['Input.threadtitle']==thread].shape[0]:
            del counts['Answer.noreply']
        counts_sorted = (counts.sort_values(ascending = False))
        #print(counts_sorted)
        post_max_agreement = np.argwhere(counts == np.max(counts)).flatten().tolist()
        #print(post_max_agreement)
        post_max_agreement = ((counts.iloc[post_max_agreement].index.values))
        post_max_agreement=np.append(post_max_agreement,'Answer.noreply')
        #print(post_max_agreement)
        length = len(filter_col)
        #print(length)
        df1 = df.loc[df['Input.threadtitle'] == thread]
        df2 = pd.DataFrame()
        for p in (post_max_agreement):
           #print(p)
           df2['Agree'+str(p)] = df1.loc[:,p].fillna(0)#.astype(int)#.astype(bool).astype(int)
          
        aggregate = aggregate_raters(df2.T)
        #print(aggregate[0])
        fk = fleiss_kappa(aggregate[0])
        fks.append(fk.calc_fleiss_kappa())
        #print(thread+ "("+str(length)+")"+" -- "+str(fk.calc_fleiss_kappa())+"\n")
    print("Average Kappa:"+str(np.mean(fks)))
    #print(str(np.mean(fks))+',')


        


   
if __name__ == "__main__":
    fks = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", "-f", type=str )
    parser.add_argument("--course","-c", type=str )
    parser.add_argument("--task","-t", type=str )
    args = parser.parse_args()
    course=args.course
    #print(os.getcwd())
    files = glob.glob('/Users/radhikanikam/Desktop/Raw_files_courses_copy/2.1/'+ str(course)+'*.csv')

    #print(files)
    if args.file is not None:
        df = pd.read_csv(args.file)

        if args.task in ("1.1", "marking", "mark", "m"):
            get_kappa_marking(df)
        elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"):
            get_kappa_categorization(df)
    else:
        for f in files:
            df=pd.read_csv(f)
            if args.task in ("1.1", "marking", "mark", "m"):
                get_kappa_marking(df)
            elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"):
                get_kappa_categorization(df)
