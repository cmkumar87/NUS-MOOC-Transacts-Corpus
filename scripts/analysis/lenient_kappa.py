import numpy as np
import pandas as pd
import os,re,sys
import glob, argparse
from statsmodels.stats.inter_rater import aggregate_raters
import mysql.connector, sqlite3

class fleiss_kappa:
	def __init__(self,data):
		self.data = data

	def calc_fleiss_kappa(self):

		#From http://www.statsmodels.org/dev/stats.html

		table = 1.0 * np.asarray(self.data)   #avoid integer division
		self.n_sub, self.n_cat =  table.shape
		self.n_total = table.sum()
		self.n_rater = table.sum(1)
		self.n_rat = self.n_rater.max()
		assert self.n_total == self.n_sub * self.n_rat
		self.p_cat = table.sum(0) / self.n_total

		self.table2 = table * table
		self.p_rat = (self.table2.sum(1) - self.n_rat) / (self.n_rat *
                        (self.n_rat - 1))
		self.p_mean = self.p_rat.mean()

		self.p_mean_exp = (self.p_cat*self.p_cat).sum()

		kappa = (self.p_mean - self.p_mean_exp) / (1- self.p_mean_exp)

		return kappa

	def calc_std_dev(self):

#From https://i1.wp.com/www.real-statistics.com/wp-content/uploads/2013/11/image102c.png

		self.var_num_1 = (self.p_mean_exp - (2*self.n_rater-3)*(
			self.p_mean_exp)**2)
		self.var_num_2 = 2*(self.n_rater-2)*(self.p_cat**3).sum()
		self.var_num = 2*(self.var_num_1+self.var_num_2)
		self.var_den = self.n_rater*self.n_sub*(self.n_rater-1)*(1-
			self.p_mean_exp)**2
		var = self.var_num/self.var_den
		return math.sqrt(var[0])


def get_kappa(df):
    df = df.loc[df['AssignmentStatus'] != 'Rejected']
    threads = df['Input.threadtitle'].unique()
    entries = []

    for thread in threads:
        filter_col = [col for col in df if col.startswith('Answer')]
        counts = (df.loc[df['Input.threadtitle'] == thread, \
            filter_col].count(axis = 0))
        if counts['Answer.noreply']!=df.loc[df['Input.threadtitle']==thread].shape[0]:
            del counts['Answer.noreply']
        counts_sorted = (counts.sort_values(ascending = False))
        #print(counts_sorted)
        post_max_agreement = (counts_sorted.argmax())
        print(post_max_agreement)
        #df[filter_col] = df[filter_col].fillna(0)
        conn = sqlite3.connect('cs6207.db')
        c = conn.cursor()
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
        df2['Agree'] = df1[post_max_agreement].fillna(0).astype(bool)#.astype(int)
        df2['Disagree'] = ~df2['Agree']
        df_num = ((df2).astype(int)).sum(axis=0)
        df3 = pd.DataFrame()
        #print(df_num)
        df3=df3.append(df_num,ignore_index=True)

        #print(df3)
        entries.append(df3)
    df_final = pd.concat(entries).reset_index(drop=True)
    print(df_final)
    aggregate = aggregate_raters(df_final.T)
    fk = fleiss_kappa(aggregate[0])
    fks.append(fk.calc_fleiss_kappa())
    #print(thread+ "("+str(length)+")"+" -- "+str(fk.calc_fleiss_kappa())+"\n")
    print("Average Kappa:"+str(np.mean(fks)))


fks = []
parser = argparse.ArgumentParser()
parser.add_argument("--file", "-f", type=str )
parser.add_argument("--course","-c",type=str )
args = parser.parse_args()
#print(os.getcwd())
files = glob.glob('/Users/radhikanikam/Desktop/Courses/ml/task1.1_results/*.csv')
course = args.course
#print(files)
if args.file is not None:
    df = pd.read_csv(args.file)
    get_kappa(df)
else:
    for f in files:
        df=pd.read_csv(f)
        get_kappa(df)

print(type(course))
