#!/usr/anaconda3/bin/python

import glob,base64
import hashlib
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

""" Encrypts raw annotation files with input password"""

password = "" # set encryption password to WING group password

salt = os.urandom(16)
kdf = PBKDF2HMAC(
    algorithm=hashes.SHA256(),
    length=32,
    salt=salt,
    iterations=100000,
    backend=default_backend()
)
key = base64.urlsafe_b64encode(kdf.derive(password)) # Get key from password
print(key)
f = Fernet(key)
files = glob.glob("Raw_files_courses_copy/*/*.csv") # Get raw files and save them to folder "/Encrypted/"
""" Make these folders in "Encrypted" first
  Encrypted
    .
    └── Raw_files_courses_copy
        ├── 1.1
        ├── 2.1
        ├── 2.2
"""

for fle in files:
    os.chdir(r'/Users/radhikanikam/Desktop/')
    filename = os.path.basename(fle)
    save_to = '/Encrypted/'
    #print(os.getcwd())
    with open(fle) as fi:
       text = fi.read()
       token = f.encrypt(bytes(text, encoding='utf-8'))
    os.chdir(r'/Users/radhikanikam/Desktop/Encrypted/')
    new = (os.getcwd())
    with open(os.path.join(new,fle),'wb+') as fe:
        fe.write(token)
       #print(token)
       #print(f.decrypt(token)) # To decode the files

