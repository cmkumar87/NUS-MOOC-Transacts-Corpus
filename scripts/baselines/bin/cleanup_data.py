import sqlite3
import pandas as pd
import re

'''
This script cleans the text in the annotated corpus. It substitutes equations, time and links with #MATH, #URLREF and #TIMEREF

'''


courses_df = pd.read_csv('../data/nustotal.csv', encoding = "latin1")
thread_titles = courses_df['Title']
courses = courses_df['Course']
del courses_df['post']
del courses_df['inst_post']
#conn = sqlite3.connect('../../../nus-part-two/Annotation files/annot-site/project/data/nusdata.db')
conn = sqlite3.connect('/diskA/muthu/nus-mooc-corpus/data/cs6207.db')
conn.text_factory = lambda x: str(x, 'latin1')
c = conn.cursor()

for thread_title in thread_titles:
    thread_text = ''
    thread_comment_text = ''
    post_count=0
    comment_count =0
    for row in c.execute('select thread.id, post2.id, post2.post_text from post2 inner join thread on \
        post2.thread_id=thread.id where thread.title=? and post2.courseid=?  order by post2.post_order ASC',
        (thread_title,courses_df.loc[courses_df['Title']==thread_title,'Course'].iloc[0])):
        post_count+=1
        thread_id,post_id,post_text = row

        post_text = re.sub(r'(https?://)?(www\.)?([a-zA-Z0-9_%]*)\b\.[a-z]{2,4}(\.[a-z]{2})?((/[a-zA-Z0-9_%]*)+)?(\.[a-z]*)?','#URLREF',post_text)
        post_text = re.sub(r'([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?','#TIMEREF',post_text)
        post_text = re.sub(r'(\()+.*[+*/-]+.*(\))+','#MATH',post_text)
        thread_text+=post_text+ '\n'
        c2 = conn.cursor()
        comment_text = [r for r in  c2.execute('select comment2.id, comment2.comment_text from comment2 inner \
            join post2 on comment2.post_id=post2.id where post2.id=?  and comment2.thread_id=? order by comment2.id ASC',
            (post_id,thread_id)) if len(r)!=0]

        try:
            comment_text = re.sub(r'(https?://)?(www\.)?([a-zA-Z0-9_%]*)\b\.[a-z]{2,4}(\.[a-z]{2})?((/[a-zA-Z0-9_%]*)+)?(\.[a-z]*)?','#URLREF',set(comment_text).pop()[1])
            comment_text = re.sub(r'([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?','#TIMEREF',comment_text)
            comment_text = re.sub(r'(\()+.*[+*/-]+.*(\))+','#MATH',comment_text)
            thread_text+= comment_text+'\n'
            thread_comment_text+= comment_text+'\n'
            comment_count+=1
        except:
            pass

    inst_text = ''
  
    '''

    courses_df.loc[courses_df['Title']==thread_title,'Post_text'] = thread_text
    courses_df.loc[courses_df['Title']==thread_title,'Comment_text'] = thread_comment_text
    courses_df.loc[courses_df['Title']==thread_title,'Post_count'] = post_count
    courses_df.loc[courses_df['Title']==thread_title,'Comment_count'] = comment_count

#    courses_df.loc[courses_df['Title']==thread_title,'Instr_text'] = inst_text

# REGEX
'''

courses_df.to_csv('../data/nustotal_preprocessed.csv')

