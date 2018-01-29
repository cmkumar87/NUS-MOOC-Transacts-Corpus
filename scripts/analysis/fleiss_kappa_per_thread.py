import pandas as pd 
import os.path
import numpy as np
import csv
import math
from krippendorff import *
from statsmodels.stats.inter_rater import aggregate_raters
import mysql.connector,sqlite3 

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

data = pd.read_csv('warhol_task1.1.csv')
data = data.loc[:,'Input.threadtitle':'Answer.noreply']
titles = data['Input.threadtitle'].unique()
aggregate_dataframe = pd.DataFrame()
fks = []
for title in titles:
    df = data.loc[data['Input.threadtitle']==title]
    df = df.loc[:,'Answer.1':'Answer.noreply'].fillna(0)
    df = df.replace('unclear',1)
    df = df.replace('none',1)
    conn = sqlite3.connect('cs6207.db')
    c = conn.cursor()
    c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id where original=1 and post2.courseid like "%%warhol%%" and thread.title like '+'"%%'+title+'%%"') 
    thread_id = c.fetchone()
    c.execute("select count(1) from post2 where thread_id=? and courseid like '%warhol%'",
            thread_id)
    post2 = c.fetchone()
    c.execute("select count(1) from comment2 where thread_id=? and courseid like '%warhol%'", thread_id)
    comment2 = c.fetchone()
    length = post2[0]+comment2[0] 
    print(length)
    df1 = pd.DataFrame()
   
    for i in range(length):
        try:
            df1['Answer.'+ str(i+1)]  = df['Answer.'+ str(i+1)] 
        except:
            pass
       
    
    df1['Answer.noreply'] = df['Answer.noreply']
    aggregate = aggregate_raters(df1.T)

    #print(aggregate)
    fk = fleiss_kappa(aggregate[0])
    fks.append(fk.calc_fleiss_kappa())
    print(title+" -- "+str(fk.calc_fleiss_kappa()))
    
print("\nAverage Kappa:"+str(np.mean(fks)))
print("Std Dev:" + str(np.std(fks)))





















