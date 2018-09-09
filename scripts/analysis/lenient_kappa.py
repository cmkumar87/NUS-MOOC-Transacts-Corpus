import numpy as np
import pandas as pd
import os,re,sys,warnings
import glob, argparse
from statsmodels.stats.inter_rater import aggregate_raters
#import mysql.connector, sqlite3
import sqlite3
pd.options.mode.chained_assignment = None

"""
Calculates Lenient Fleiss Kappa for given input file and course ID

Run: python lenient_kappa.py -f= **file name** -c=**course id**
"""
# SET either cs6207.db or nusdata.db in below line 
# cmkumar: changing this to cmd line argument
#DB = 'cs6207.db'


class fleiss_kappa:
        def __init__(self,data):
                self.data = data

        def calc_fleiss_kappa(self):

                #From http://www.statsmodels.org/dev/stats.html
                
                warnings.simplefilter("error", RuntimeWarning)
                table = 1.0 * np.asarray(self.data)   #avoid integer division
                #print(table)
                self.n_sub, self.n_cat =  table.shape
                self.n_total = table.sum()
                #print(self.n_total)
                self.n_rater = table.sum(1)
                #print(self.n_rater)
                self.n_rat = self.n_rater.max()
                assert self.n_total == self.n_sub * self.n_rat

                self.p_cat = table.sum(0) / self.n_total
                #print(self.p_cat)
                self.table2 = table * table
                #print(self.table2)
                self.p_rat = (self.table2.sum(1) - self.n_rat) / (self.n_rat * (self.n_rat - 1))
                self.p_mean = self.p_rat.mean()
                #print(self.p_rat)
                #print(self.p_mean)
                self.p_mean_exp = (self.p_cat*self.p_cat).sum()
                #print(self.p_cat)
                #print(self.p_mean,self.p_mean_exp)
                try:
                    #print(self.p_mean,self.p_mean_exp)
                    kappa = (self.p_mean - self.p_mean_exp) / (1- self.p_mean_exp)


                except RuntimeWarning:
                    kappa = 1.0 #Fix for cases where this is only one post (1 subject), chance agreements 
                                #also equal 1 making the kappa=NaN.

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


def get_kappa_marking(df,c):

    """ Lenient Fleiss' Kappa for marking task - Task 1.1 """

    df = df.loc[df['AssignmentStatus'] != 'Rejected'] #Taking only the mturk assignments that were accepted
    threads = df['Input.threadtitle'].unique()  #Getting a list of unique threads in the list
    fks = [] #List of kappas in each thread in the given batch
    if 'Answer.noreply' not in df.columns:
        df['Answer.noreply'] = ""

    for thread in threads:
        
        ############################  Get the total number of posts+comments in that thread  ############################
        
        try:    
            c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id where \
                original=1 and post2.courseid like '+'"%%'+course+'%%"'+' and thread.title like '+'"%%'+ \
                thread+'%%"')
            thread_id = c.fetchone()
            
            c.execute('select count(1) from post2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and \
                courseid like '+'"%%'+course+'%%"' )

            post2 = c.fetchone()
            c.execute('select count(1) from comment2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and \
                courseid like '+'"%%'+course+'%%"' )
            comment2 = c.fetchone()
            length = post2[0]+comment2[0]
        
        except:
            continue     

        #################################################################################################################

        ###############################  Selecting post(s) with maximum markings  ########################################

        filter_col = [col for col in df if col.startswith('Answer')]
        counts = (df.loc[df['Input.threadtitle'] == thread, \
            filter_col].count(axis = 0))

        counts_sorted = (counts.sort_values(ascending = False))

        post_max_agreement = np.argwhere(counts == np.max(counts)).flatten().tolist()

        post_max_agreement = ((counts.iloc[post_max_agreement].index.values))
        #print(post_max_agreement)
        df = df.replace('unclear',99)
        df = df.replace('none',99)

        ##################################################################################################################
        
        #####################  Calculating Fleiss Kappa using the fleiss_kappa class above  #############################
        
        #df1 = df.loc[df['Input.threadtitle'] == thread]
        df1 = pd.DataFrame()
      
        
        for i in range(length):
            if 'Answer.'+ str(i+1) in df.columns:
                    df1['Answer.'+ str(i+1)]  = 0
            else:
                pass
        df1['Answer.noreply'] = 0
        df1[post_max_agreement] = df.loc[df['Input.threadtitle'] == thread, post_max_agreement]  
        
        

        #print(df1.fillna(0).astype(int))

        aggregate = aggregate_raters(df1.fillna(0).astype(int).T)
        fk = fleiss_kappa(aggregate[0])
        #print(aggregate)
        fks.append(fk.calc_fleiss_kappa())
        print(thread+ "("+str(length)+")"+" -- "+str(fk.calc_fleiss_kappa())+"\n")


        #################################################################################################################

    print("\nAverage Kappa:"+str(np.mean(fks)))


def get_kappa_categorization(df,c):

    """ Fleiss Kappa for categorisation tasks - Task 2.1 and Task 2.2 """

    df = df.loc[df['AssignmentStatus'] != 'Rejected']
    threads = df['Input.threadtitle'].unique()
    #print(len(threads))
    entries = []
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

    if 'Answer.noreply' not in df.columns: # Add Answer.noreply if it does not exist in the dataframe
        df['Answer.noreply'] = ""
    marked_posts = [col for col in df.columns if 'Answer.' in col]

    for post in marked_posts:
        df[post] = df[post].map(cat_to_num_2) # Substituting the categories to numbers
    
    for thread in threads:
        
            ############################  Get the total number of posts+comments in that thread  ############################
        
        try: 
            c.execute('select thread_id from post2 inner join thread on post2.thread_id= thread.id where \
                original=1 and post2.courseid like '+'"%%'+course+'%%"'+' and thread.title like '+'"%%'+thread+'%%"')
            thread_id = c.fetchone()
            #print(thread_id)
            c.execute('select count(1) from post2 where thread_id like'+'"%%'+str(thread_id[0])+'%%"'+ ' and \
                courseid like '+'"%%'+course+'%%"' )
            post2 = c.fetchone()
            c.execute('select count(1) from comment2 where thread_id like '+'"%%'+str(thread_id[0])+'%%"'+ ' and \
                courseid like '+'"%%'+course+'%%"' )
            comment2 = c.fetchone()
            length = post2[0]+comment2[0]
        
        except:
            continue    
        
        #################################################################################################################

        ###############################  Selecting post(s) with maximum markings  #######################################

        counts = (df.loc[df['Input.threadtitle'] == thread, \
            marked_posts].count(axis = 0))

        counts_sorted = (counts.sort_values(ascending = False))

        post_max_agreement = np.argwhere(counts == np.max(counts)).flatten().tolist()
        post_max_agreement = ((counts.iloc[post_max_agreement].index.values))

        #################################################################################################################

        #####################  Calculating Fleiss Kappa using the fleiss_kappa class above  #############################
        #print(post_max_agreement)
        df1 = pd.DataFrame()
        for i in range(length) :
            if 'Answer.'+ str(i+1)+'_discourse_type' in df.columns:
                    df1['Answer.'+ str(i+1)+'_discourse_type']  = 0
            else:
                pass
        df1['Answer.noreply'] = 0
        df1[post_max_agreement] = df.loc[df['Input.threadtitle'] == thread, post_max_agreement]
        
        #print(df1)
        aggregate = aggregate_raters(df1.fillna(0).astype(int).T)
        #print(aggregate[0])
        fk = fleiss_kappa(aggregate[0])
        fks.append(fk.calc_fleiss_kappa())
        print(thread+ "("+str(length)+")"+" -- "+str(fk.calc_fleiss_kappa()))
  
    #################################################################################################################
        
    print("\nAverage Kappa:"+str(np.mean(fks))+"\n")


if __name__ == "__main__":

   
    fks = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", "-f", type=str )
    parser.add_argument("--courseid","-c", type=str )
    parser.add_argument("--task","-t", type=str )
    parser.add_argument("--dbname","-db", type=str)
    args = parser.parse_args()
    course = args.courseid
    
    DB = args.dbname
    if DB is None:
        print("Please enter a valid sqlite database file name")
        exit(0)

    dirname = os.path.dirname(os.path.realpath('__file__'))
    conn = sqlite3.connect(os.path.join(dirname,'../../data/',DB+'.db'))

    db_cursor = conn.cursor()
    courses_in_DB = db_cursor.execute('select distinct courseid from thread').fetchall()
    course_match = "".join([c[0] for c in courses_in_DB if c[0] == course])
    
    ### Make sure that course mentioned in arguments is valid and a complete courseID
    if course_match != course:
        parser.error('Incomplete or Invalid Course ID')
    
    ## Do not give --file arg if you want it to run on all batches of a course, set folder in next line

    files = []
    if args.task == 'm' or args.task == 'marking' or args.task == '1.1':
	files = glob.glob('../../../annotated-nus-mooc-corpus/raw/1.1/'+ str(course)+'*.csv')
    elif args.task == 'c' or args.task == 'categorisation' or args.task == '2.1':
	files = glob.glob('../../../annotated-nus-mooc-corpus/raw/2.1/'+ str(course)+'*.csv')

    #print(files)
    if args.file is not None:
        print("Reading from file:"+args.file)
        file = '../../../annotated-nus-mooc-corpus/raw/1.1/'+args.file
        df = pd.read_csv(file)

        if args.task in ("1.1", "marking", "mark", "m"):
            print("Computing kappa for marking task")
            get_kappa_marking(df, db_cursor)
        elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"):
            print("Computing kappa for categorisation task")
            get_kappa_categorization(df, db_cursor)
    else:
        print("Found several files for course: "+course_match)
        for f in files:
            df = pd.read_csv(f)
            if args.task in ("1.1", "marking", "mark", "m"):
                print("Computing kappa for marking task")
                get_kappa_marking(df, db_cursor)
            elif args.task in ("2.1", "2.2", "categorization", "categorisation", "cat", "c"):
                print("Computing kappa for categorisation task")
                get_kappa_categorization(df, db_cursor)

    conn.close()
##Done##
