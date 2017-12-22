import pandas as pd 
import os.path
import numpy as np
import csv
from sklearn.metrics import confusion_matrix
import io,glob


data=pd.DataFrame()
data = pd.read_csv('reason2_auto.csv')
data2 = pd.read_csv('reason_auto.csv')
lab = ['paraphrase','feedbackreq','clarification','refinement','juxtaposition',
'justify','critique','summary','extension','completion','appreciation','answer',
'agreement','disagreement','other','none']
f = confusion_matrix((data['groundtruth'].tolist() + data2['groundtruth'].tolist()), 
	(data['answer'].tolist()+ data2['answer '].tolist()), labels = lab)

confmat = pd.DataFrame(f, index = lab, columns=lab)
confmat.to_csv('cm.csv')
print(confmat)
print(f.sum())