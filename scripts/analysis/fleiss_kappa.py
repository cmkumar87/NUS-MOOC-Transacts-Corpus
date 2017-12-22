import pandas as pd 
import os.path
import numpy as np
import csv
import math

class fleiss_kappa:
	def __init__(self,data):
		self.data = data

	def calc_fleiss_kappa(self):
		table = 1.0 * np.asarray(self.data)   #avoid integer division
		self.n_sub, self.n_cat =  table.shape
		self.n_total = table.sum()
		self.n_rater = table.sum(1)
		self.n_rat = self.n_rater.max()
		assert self.n_total == self.n_sub * self.n_rat
		self.p_cat = table.sum(0) / self.n_total

		self.table2 = table * table
		self.p_rat = (self.table2.sum(1) - self.n_rat) / (self.n_rat * (self.n_rat - 1))
		self.p_mean = self.p_rat.mean()

		self.p_mean_exp = (self.p_cat*self.p_cat).sum()

		kappa = (self.p_mean - self.p_mean_exp) / (1- self.p_mean_exp)
		
		return kappa

	def calc_std_dev(self):
		"""
		https://i1.wp.com/www.real-statistics.com/wp-content/uploads/2013/11/image102c.png
		"""
		self.var_num_1 = (self.p_mean_exp - (2*self.n_rater-3)*(
			self.p_mean_exp)**2)
		self.var_num_2 = 2*(self.n_rater-2)*(self.p_cat**3).sum()
		self.var_num = 2*(self.var_num_1+self.var_num_2)
		self.var_den = self.n_rater*self.n_sub*(self.n_rater-1)*(1-
			self.p_mean_exp)**2
		var = self.var_num/self.var_den
		return math.sqrt(var[0])
				
# Ordering the data for analysis

data=pd.DataFrame()
data = pd.read_csv('ui_result_task1.csv')
data = data.loc[:,'Input.threadtitle':'Answer.noreply']

data_matrix = data.loc[:,'Answer.1':'Answer.noreply'].as_matrix()
titles = data['Input.threadtitle'].unique()

aggregate_dataframe = pd.DataFrame()

for title in titles:
	df = (data.loc[data['Input.threadtitle']==title])
	non_null_posts= pd.DataFrame((df.loc[:,col] for col in df.columns[1:] 
		if df[col].count()>0)).T.columns
	for col in non_null_posts:		
		aggregate_dataframe= aggregate_dataframe.append({'post':title, 
			'marked':df[col].count(), 'unmarked':7-df[col].count()},
			ignore_index=True)
del aggregate_dataframe['post']

# Calculating Fleiss Kappa, standard deviation

fk = fleiss_kappa(aggregate_dataframe)

print("Fleiss' Kappa: " + str(fk.calc_fleiss_kappa()))
print("Std Dev: " + str(fk.calc_std_dev()))





