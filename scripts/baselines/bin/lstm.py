# coding: utf-8
#!conda upgrade -c conda-forge tensorflow

import numpy as np
import os
import nltk
import pandas as pd
import re
from io import StringIO
import operator
import tensorflow
from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from keras.utils import to_categorical
from keras.layers import Dense, Input, Dropout
from keras.layers import LSTM, Embedding, Flatten
from keras.models import Model
import keras.backend as K
from keras.callbacks import Callback
from sklearn.metrics import confusion_matrix, f1_score, precision_score, recall_score

#set random seed
from numpy.random import seed
seed(42)
from tensorflow import set_random_seed
set_random_seed(42)

print(tensorflow.VERSION)
categories = ['resolves','elaborates','social','requests']

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
print('Found %s unique tokens.' % len(word_index))

data = pad_sequences(sequences, maxlen=MAX_SEQUENCE_LENGTH)
labels = to_categorical(np.asarray(labels))
print('Shape of data tensor:', data.shape)
print('Shape of label tensor:', labels.shape)

indices = np.arange(data.shape[0])
np.random.shuffle(indices)
data = data[indices]
labels = labels[indices]
num_validation_samples = int(VALIDATION_SPLIT * data.shape[0])

label1 = []
for entry in labels:
    label1.append(np.argmax(entry))
print(np.array(label1).shape)
label1 = np.array(label1)
x_train = data[:-num_validation_samples]
y_train = labels[:-num_validation_samples]
x_val = data[-num_validation_samples:]
y_val = labels[-num_validation_samples:]

print('Preparing embedding matrix.')
print(y_train.shape)

class Metrics(Callback):
    
    def on_train_begin(self, logs={}):
        self.val_f1s = []
        self.val_recalls = []
        self.val_precisions = []
        self.val_predproba = []
 
    def on_epoch_end(self, epoch, logs={}):
        val_predict = (np.asarray(self.model.predict(self.validation_data[0]))).round()
        val_targ = self.validation_data[1]
        _val_f1 = f1_score(val_targ, val_predict,average=None)
        _val_recall = recall_score(val_targ, val_predict,average=None)
        _val_precision = precision_score(val_targ, val_predict,average=None)
        self.val_f1s.append(_val_f1)
        self.val_recalls.append(_val_recall)
        self.val_precisions.append(_val_precision)
        self.val_predproba.append(val_predict)
        return 

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
    else:
        embedding_matrix[i] = np.random.rand(1, EMBEDDING_DIM)

embedding_layer = Embedding(num_words,
                            EMBEDDING_DIM,
                            weights=[embedding_matrix],
                            input_length=MAX_SEQUENCE_LENGTH,
                            trainable=False)

# train a 1D convnet with global maxpooling
sequence_input = Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='int32')
embedded_sequences = embedding_layer(sequence_input)

x = LSTM(64, dropout_W=0.2, dropout_U=0.2)(embedded_sequences)
x = Dropout(0.4)(Dense(64, activation='relu')(x))
preds = Dense(len(categories), activation='softmax')(x)

model = Model(sequence_input, preds)
print(model.summary())
        
metrics = Metrics()
model.compile(loss='categorical_crossentropy',
              optimizer='rmsprop',
              metrics=['acc'])

print('Training model...')
model.fit(x_train, y_train,
          batch_size=16,
          epochs=10,
          validation_data=(x_val, y_val),callbacks=[metrics])

print((metrics.val_f1s[-1], metrics.val_precisions[-1], metrics.val_recalls[-1]))
#print(metrics.val_predproba[-1])

