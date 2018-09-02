#!/usr/anaconda3/bin/python

import glob,base64
import hashlib
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

""" Decrypts encrypted annotation files with input key"""

# Encryption password was set to WING group password, ask for key

salt = os.urandom(16)
kdf = PBKDF2HMAC(
    algorithm=hashes.SHA256(),
    length=32,
    salt=salt,
    iterations=100000,
    backend=default_backend()
)

key= '' #Input key here

f = Fernet(key)
os.chdir(r'/Users/radhikanikam/Desktop/Encrypted/')
files = glob.glob("Raw_files_courses_copy/*/*.csv") # Get raw files and save them to folder "/Encrypted/"
os.chdir(r'/Users/radhikanikam/Desktop/')

""" This is the directory tree in "Encrypted" 
  Encrypted
    .
    └── Raw_files_courses_copy
        ├── 1.1
        ├── 2.1
        ├── 2.2

  Decrypted will follow similar structure, make the above blank directories first      
"""

for fle in files:
    os.chdir(r'/Users/radhikanikam/Desktop/')
    filename = os.path.basename('Encrypted/'+fle)
    print(filename)
    with open('Encrypted/'+fle) as fi:
       text = fi.read()
    os.chdir(r'/Users/radhikanikam/Desktop/Decrypted/')
    new = (os.getcwd())
    with open(os.path.join(new,fle),'wb+') as fe:
       fe.write(f.decrypt(bytes(text, encoding='utf-8'))) # To decode the files

      

