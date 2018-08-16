import pandas as pd
import numpy as np
import csv
import math
from krippendorff import *
from statsmodels.stats.inter_rater import aggregate_raters
import os,re,sys
import glob, argparse
from statsmodels.stats.inter_rater import aggregate_raters
import mysql.connector, sqlite3

"""
Calculates Strict Fleiss Kappa for given input file and course ID

Run: python fleiss_kappa_per_thread.py -f= **file name** -c=**course id**
"""
# SET either cs6207.db or nusdata.db in below line 
DB = 'cs6207.db'


class fleiss_kappa:
    def __init__(self,data):
        self.data = data

    def calc_fleiss_kappa(self):
            """
        Referenced from
        http://www.statsmodels.org/dev/generated/statsmodels.stats.inter_rater.fleiss_kappa.html#statsmodels.stats.inter_rater.fleiss_kappa
        https://en.wikipedia.org/wiki/Fleiss%27_kappa
        """
            table = 1.0 * np.asarray(self.data)   #avoid integer division
            self.n_sub, self.n_cat =  table.shape
            self.n_total = table.sum()
            self.n_rater = table.sum(1)
            self.n_rat = self.n_rater.max()
            assert self.n_total == self.n_sub * self.n_rat
            self.p_cat = table.sum(0) / self.n_total
            #print(self.p_cat)    
            self.table2 = table * table
            self.p_rat = (self.table2.sum(1) - self.n_rat) / (self.n_rat*(self.n_rat - 1))
            self.p_mean = self.p_rat.mean()
            self.p_mean_exp = (self.p_cat*self.p_cat).sum()
            #print(self.p_mean,self.p_mean_exp)
            kappa = (self.p_mean - self.p_mean_exp) / (1- self.p_mean_exp)
            return kappa

    def calc_std_dev(self):

        """
        From https://i1.wp.com/www.real-statistics.com/wp-content/uploads/2013/11/image102c.png
        """
        self.var_num_1 = (self.p_mean_exp - (2*self.n_rater-3)*(self.p_mean_exp)**2)
        self.var_num_2 = 2*(self.n_rater-2)*(self.p_cat**3).sum()
        self.var_num = 2*(self.var_num_1+self.var_num_2)
        self.var_den = self.n_rater*self.n_sub*(self.n_rater-1)*(1-
                self.p_mean_exp)**2
        var = self.var_num/self.var_den
        return math.sqrt(var[0])



def get_kappa_marking(data):

    """ Fleiss' Kappa for marking task - Task 1.1 """

    data = data.loc[data['AssignmentStatus'] != 'Rejected'] #Taking only the raters that were approved
    titles = data['Input.threadtitle'].unique() #List of threads in batch
    aggregate_dataframe = pd.DataFrame()    
    fks = []
    if 'Answer.noreply' not in data.columns:
        data['Answer.noreply'] = ""
    for title in titles:
        df = data.loc[data['Input.threadtitle']==title]
        marked_posts = [col for col in df.columns if 'Answer.' in col]
        df = df.loc[:,marked_posts].fillna(0)
        df = df.replace('unclear',99)
        df = df.replace('none',99)
        conn = sqlite3.connect(DB)
        length=0
        c = conn.cursor()
        

        ### THREAD NAMES WITH QUOTES DOESN'T WORK IN SQLITE

        # c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id \
        #    where original=1 and post2.courseid=? and thread.title=?',('"%%'+course+'%%"','"%%'+title+'%%"'))
        
          
        ############################  Get the total number of posts+comments in that thread  ############################
        try:
            c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id \
                where original=1 and post2.courseid like '+'"%%'+course+'%%"'+' and thread.title like \
                '+'"%%'+title+'%%"')


            thread_id = c.fetchone()
            #print(thread_id)
            
            c.execute('select count(1) from post2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and \
                courseid like '+'"%%'+course+'%%"' )

            post2 = c.fetchone()
            c.execute('select count(1) from comment2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' \
                and courseid like '+'"%%'+course+'%%"' )
            comment2 = c.fetchone()
            length = post2[0]+comment2[0]

        except:
            continue

        #################################################################################################################
        
        #####################  Calculating Fleiss Kappa using the fleiss_kappa class above  #############################

        df1 = pd.DataFrame()

        for i in range(length):
            try:
                df1['Answer.'+ str(i+1)]  = df['Answer.'+ str(i+1)]
            except:
                pass
        df1['Answer.noreply'] = df['Answer.noreply']

        ## df1 is a dataframe with dimensions (raters X posts). aggregate_raters (below) converts that to  
        ## (posts X categories) with input as counts 

        aggregate = aggregate_raters(df1.T)

        fk = fleiss_kappa(aggregate[0])
        fks.append(fk.calc_fleiss_kappa())
        print(title+" -- "+str(fk.calc_fleiss_kappa()))

    #################################################################################################################         

    print("\nAverage Kappa:"+str(np.mean(fks)))
    print("Std Dev:" + str(np.std(fks)))

def get_kappa_categorization(data):

    """ Fleiss Kappa for categorisation tasks - Task 2.1 and Task 2.2 """

    data = data.loc[data['AssignmentStatus'] != 'Rejected']
    titles = data['Input.threadtitle'].unique()
    aggregate_dataframe = pd.DataFrame()
    fks = []
    ##########################  Mapping the categories to numbers for input into kappa  ####################################

    cat_to_num_2 = { # Categories for Task 2.1
                      "resolves":1,
                      "elaborates":2,
                      "requests":3,
                      "social":4,
                      "none":5,
                      #Categories for Task 2.2

                      #elaborates
                      "clarifies":1,
                      "extension":2,
                      "juxtaposition":3,
                      "refinement":4,
                      "critique":5,
                      
                      #resolves
                       "agreement":1,
                      "disagreement":2,
                      "generic":3,
                      "appreciation":4,
                      "completion":5,

                      "none":6,
                      "nota":6,

                }

    ########################################################################################################################            
    
    if 'Answer.noreply' not in data.columns: #Add Answer.noreply if it does not exist in the dataframe
        data['Answer.noreply'] = ""
    
    marked_posts = [col for col in data.columns if 'Answer.' in col]
    #print(marked_posts)
    for post in marked_posts:
        data[post] = data[post].map(cat_to_num_2).fillna(0).astype(int) # Substituting the categories to 
                                                                        #numbers above for input into kappa

    # The next block of code is same as above    

    for title in titles:

        df = data.loc[data['Input.threadtitle']==title]
        marked_posts = [col for col in df.columns if 'Answer.' in col]
        df = df.loc[:,marked_posts].fillna(0)
        conn = sqlite3.connect(DB)
        
        
        ############################  Get the total number of posts+comments in that thread  ############################
        try:
            c = conn.cursor()
            c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id \
                where original=1 and post2.courseid like '+'"%%'+course+'%%"'+' and thread.title like \
                '+'"%%'+title+'%%"')
            thread_id = c.fetchone()
            #print(thread_id)
            c.execute('select count(1) from post2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' \
                and courseid like '+'"%%'+course+'%%"' )

            post2 = c.fetchone()
            c.execute('select count(1) from comment2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' \
                and courseid like '+'"%%'+course+'%%"' )
            comment2 = c.fetchone()
            length = post2[0]+comment2[0]

        except:
            continue    

        #################################################################################################################

        #####################  Calculating Fleiss Kappa using the fleiss_kappa class above  #############################

        df1 = pd.DataFrame()
        #print(length)
        for i in range(length):
            try:
                df1['Answer.'+ str(i+1)]  = df['Answer.'+ str(i+1)+'_discourse_type'] 
            except:
                pass
        df1['Answer.noreply'] = df['Answer.noreply']
        #print(df1)

        ## df1 is a dataframe with dimensions (raters X posts). aggregate_raters (below) converts that to (posts X categories) 
        ## with input as counts 

        aggregate = aggregate_raters(df1.T) 
        #print(aggregate)
        fk = fleiss_kappa(aggregate[0])
        fks.append(fk.calc_fleiss_kappa())
        print(title+" -- "+str(fk.calc_fleiss_kappa()))

        #################################################################################################################      

    print("\nAverage Kappa:"+str(np.mean(fks)))
    #print("Std Dev:" + str(np.std(fks)))


if __name__ == "__main__":

    fks = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", "-f", type=str )
    parser.add_argument("--courseid","-c", type=str )
    parser.add_argument("--task","-t", type=str )
    args = parser.parse_args()
    course=args.courseid

    conn = sqlite3.connect(DB)
    n = conn.cursor()
    courses_in_DB = n.execute('select distinct courseid from post2').fetchall()
    #print(os.getcwd())
    course_match = "".join([c[0] for c in courses_in_DB if c[0]== course])
    
    ### Make sure that course mentioned in arguments is valid and a complete courseID

    if course_match!=course:
        parser.error('Incomplete or Invalid Course ID')

    ## Do not give --file arg if you want it to run on all batches of a course, set folder in next line

    files = glob.glob('/Users/radhikanikam/Desktop/Raw_files_courses_copy/1.1/'+ str(course)+'*.csv')

    #print(files)
    if args.file is not None:
        df = pd.read_csv(args.file)

        if args.task in ("1.1", "marking", "mark", "m"): # Marking Task
            get_kappa_marking(df)
        elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"): #Categorisation Task
            get_kappa_categorization(df)
    else:
        for f in files:
            df=pd.read_csv(f)
            if args.task in ("1.1", "marking", "mark", "m"):    # Marking Task
                get_kappa_marking(df)
            elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"):   #Categorisation Task
                get_kappa_categorization(df)

