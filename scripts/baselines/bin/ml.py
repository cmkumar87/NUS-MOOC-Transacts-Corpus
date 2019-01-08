# coding: utf-8
#!conda upgrade -c conda-forge tensorflow

import numpy as np
import os
import nltk
import re
import pandas as pd
import operator
from io import StringIO
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer, TfidfTransformer
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.svm import SVC
from sklearn.model_selection import train_test_split
from sklearn import metrics
from sklearn.model_selection import cross_val_score
from sklearn.utils import shuffle
from sklearn import preprocessing

from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.utils import to_categorical


df = pd.read_csv('../data/21total_preprocessed.csv')

del df['Task2.1']
print(df.head())
df2 = pd.read_csv('../data/nustotal_preprocessed.csv')
df = df.append(df2)

df['Categories'] = df['Categories'].factorize()[0]
print(df['Categories'].value_counts())

#Removing Names
def extract_entities(text):
    for sent in nltk.sent_tokenize(text):
        for chunk in nltk.ne_chunk(nltk.pos_tag(nltk.word_tokenize(sent))):
            if hasattr(chunk, 'node'):
                print(chunk.node, ' '.join(c[0] for c in chunk.leaves()))

categories = ['resolves','elaborates','social','requests']
courses = df['Course'].unique()

for course in courses:
    course_data = df.loc[df['Course']==course].dropna()
    post_text = course_data['Post_text'].tolist()
    course_train, course_val, course_test = np.split(course_data.sample(frac=1), [int(.6*len(course_data)), int(.8*len(course_data))])    
df = df.dropna()
df_train, df_val, y_train, y_val = train_test_split(df.loc[:,'Post_text':'Comment_count'],df['Categories'],test_size=0.40,stratify=df['Categories']) 

count_vect = CountVectorizer()
df_train_counts = count_vect.fit_transform(df_train['Post_text'])

tfidf_vectorizer = TfidfVectorizer(stop_words='english')
df_train_tfidf = tfidf_vectorizer.fit(df_train['Post_text'])
text=df_train['Post_text'].tolist()

X = df_train_tfidf.transform([text[0]])

new_dict={}
for vocab, idf_score in zip((list(tfidf_vectorizer.vocabulary_.keys())),(tfidf_vectorizer.idf_)):
    if len(vocab)>3:
        new_dict[vocab] = idf_score
#print(sorted(new_dict.items(),key=operator.itemgetter(1),reverse=True)[:30])

#print((X.toarray()))

class_weights = {
    0: 1.,
    1: 1.,
    2: 5.,
    3: 5.
}

# Linear SVM or SGDCLassifier with Hinge Loss
from sklearn.pipeline import Pipeline
from sklearn.linear_model import SGDClassifier
text_clf = Pipeline([
                     ('tfidf', TfidfVectorizer(stop_words='english',ngram_range=(1,2))),
                     ('clf',  SGDClassifier(loss='hinge', penalty='l2',
                                           alpha=1e-3, random_state=42 #class_weight=class_weights,
                                            )),
])
text_clf.fit(df_train['Post_text'], y_train)  

predicted = text_clf.predict(df_val['Post_text'])

print('----------Linear SVM or SGDCLassifier with Hinge Loss------------\n\n')
print("Predicted: "+ str(predicted.tolist()))
print("Actual: " + str(y_val.tolist()))
print("Accuracy: "+ str(np.mean(predicted == y_val))+ "\n")
indices = (np.argsort(text_clf.named_steps['clf'].coef_,axis=1))
#print(indices)
#features = (text_clf.named_steps['tfidf'].get_feature_names())
#for i in indices:
#    print("---"+ str(categories[np.where(np.all(indices==i,axis=1))[0][0]]) + "---")
#    for j in i[-15:]:
#        print(features[j])

print(metrics.confusion_matrix(y_val, predicted))
print(metrics.classification_report(y_val, predicted))

# Gradient Boosted Trees

class TextStats(BaseEstimator, TransformerMixin):
    """Extract features from each document """

    def fit(self, x, y=None):
        return self

    def transform(self, posts):
        return [{'length': len(text)
                }
                for text in posts]

class DenseTransformer(TransformerMixin):

    def transform(self, X, y=None, **fit_params):
        return X.todense()

    def fit_transform(self, X, y=None, **fit_params):
        self.fit(X, y, **fit_params)
        return self.transform(X)

    def fit(self, X, y=None, **fit_params):
        return self

text_clf = Pipeline([
                     ('tfidf', TfidfVectorizer(stop_words='english', ngram_range=(1,2))),
                     
                     ('to_dense', DenseTransformer()),
                     
                     ('clf', GradientBoostingClassifier(random_state=42)),
])


text_clf.fit(df_train['Post_text'], y_train,)  
predicted = text_clf.predict(df_val['Post_text'])
pred_proba = text_clf.predict_proba(df_val['Post_text'])

print('----------Gradient Boosted Trees------------\n\n')
print("Predicted: "+ str(predicted.tolist()))
print("Actual: " + str(y_val.tolist()))
print("Accuracy: "+ str(np.mean(predicted == y_val))+ "\n")
print("Predict Probabilties: ")
for idx, item in enumerate(pred_proba.tolist()):
    item = list(np.around(np.array(item),2))
    print(idx, str(item) +"\t"+ str((predicted.tolist())[idx])+"\t"+str((y_val.tolist())[idx]))

#print(np.sort(text_clf.named_steps['clf'].feature_importances_))
indices = np.argsort(text_clf.named_steps['clf'].feature_importances_)[-15:]

features = (text_clf.named_steps['tfidf'].get_feature_names())
#print("\nMost important features: \n")
#for i in indices:
#    print(features[i])

print(metrics.confusion_matrix(y_val, predicted))
print(metrics.classification_report(y_val, predicted))

# Random Forest Pipeline

text_clf = Pipeline([
                     ('tfidf', TfidfVectorizer(stop_words='english', ngram_range=(1,2))),
                     
                     ('to_dense', DenseTransformer()),
                     
                     ('clf', RandomForestClassifier(class_weight=class_weights,random_state=42
                                            )),
])

text_clf.fit(df_train['Post_text'], y_train)  
predicted = text_clf.predict(df_val['Post_text'])
pred_proba = text_clf.predict_proba(df_val['Post_text'])

#print(df_val['Post_text'],y_val)
print('----------Random Forest------------\n\n')
print("Predicted: "+ str(predicted.tolist()))
print("Actual: " + str(y_val.tolist()))
print("Accuracy: "+ str(np.mean(predicted == y_val))+ "\n")

print("Predict Probabilties: ")
for idx, item in enumerate(pred_proba.tolist()):
    item = list(np.around(np.array(item),2))
    print(idx, str(item) +"\t"+ str((predicted.tolist())[idx])+"\t"+str((y_val.tolist())[idx]))

indices = np.argsort(text_clf.named_steps['clf'].feature_importances_)[-15:]

features = (text_clf.named_steps['tfidf'].get_feature_names())
#print("\nMost important features: \n")
#for i in indices:
#    print(features[i])

print(metrics.confusion_matrix(y_val, predicted))
print(metrics.classification_report(y_val, predicted))

BASE_DIR = ''
GLOVE_DIR = os.path.join(BASE_DIR, 'glove.6B')
embeddings_index = {}
with open(os.path.join(GLOVE_DIR, 'glove.6B.300d.txt')) as f:
    for line in f:
        values = line.split()
        word = values[0]
        coefs = np.asarray(values[1:], dtype='float32')
        embeddings_index[word] = coefs
print('Found %s word vectors.' % len(embeddings_index))
MAX_SEQUENCE_LENGTH = 1000
MAX_NUM_WORDS = 20000
EMBEDDING_DIM = 300
VALIDATION_SPLIT = 0.2

df = pd.read_csv('../data/21total_preprocessed.csv').dropna(subset=['Post_text'])
del df['Task2.1']
df['Categories'] = df['Categories'].factorize()[0]
texts = df['Post_text']
print((texts[0][0]))
labels = df['Categories']
tokenizer = Tokenizer(num_words=MAX_NUM_WORDS)
tokenizer.fit_on_texts(texts)
sequences = tokenizer.texts_to_sequences(texts)
word_index = tokenizer.word_index

print(len(texts))
data = pad_sequences(sequences, maxlen=MAX_SEQUENCE_LENGTH)

labels = to_categorical(np.asarray(labels))
print('Shape of data tensor:', data.shape)
print('Shape of label tensor:', labels.shape)

indices = np.arange(data.shape[0])
np.random.shuffle(indices)
data = data[indices]
labels = labels[indices]
print(labels)
num_validation_samples = int(VALIDATION_SPLIT * data.shape[0])

label1 = []
for entry in labels:
    label1.append(np.argmax(entry))
print(np.array(label1).shape)
label1 =np.array(label1)
x_train = data[:-num_validation_samples]
y_train = labels[:-num_validation_samples]
x_val = data[-num_validation_samples:]
y_val = labels[-num_validation_samples:]

print('Preparing embedding matrix.')
print(y_train.shape)

# prepare embedding matrix
num_words = min(MAX_NUM_WORDS, len(word_index) + 1)
embedding_matrix = np.zeros((num_words, EMBEDDING_DIM))
for word, i in word_index.items():
    if i >= MAX_NUM_WORDS:
        continue
    embedding_vector = embeddings_index.get(word)
    if embedding_vector is not None:
        # words not found in embedding index will be all-zeros.
        embedding_matrix[i] = embedding_vector

class_weights = {
    0: 1.,
    1: 1.,
    2: 5.,
    3: 5.
}

label1 = []
for entry in labels:
    label1.append(np.argmax(entry))
#print(np.array(label1).shape)
label1 = np.array(label1)
x_train = data[:-num_validation_samples]
y_train = label1[:-num_validation_samples]
x_val = data[-num_validation_samples:]
y_val = label1[-num_validation_samples:]

#Linear SVM with Glove 
print('-----------Linear SVM with GloVe----------------')
print(embedding_matrix.shape)
from sklearn import linear_model
clf = linear_model.SGDClassifier(class_weight=class_weights)
clf.fit(x_train,y_train)

predicted = clf.predict(x_val)

#prob esitmates are not available for hinge loss
#todo https://github.com/scikit-learn/scikit-learn/issues/7278
#http://scikit-learn.org/stable/modules/calibration.html
#pred_proba = clf.predict_proba(df_val['Post_text'])

print("Predicted: "+ str(predicted.tolist()))
print("Actual: " + str(y_val.tolist()))
print(len(y_val.tolist()))

print("Accuracy: "+ str(np.mean(predicted == y_val))+ "\n")
#print("Predict Probabilties: ")
#for idx, item in enumerate(pred_proba.tolist()):
#    item = list(np.around(np.array(item),2))
#    print(idx, str(item) +"\t"+ str((predicted.tolist())[idx])+"\t"+str((y_val.tolist())[idx]))

print(metrics.confusion_matrix(y_val, predicted))
print(metrics.classification_report(y_val, predicted))

