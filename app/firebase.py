import os
import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase Admin SDK
BASE_DIR = "firebase_service_account"
path = BASE_DIR + os.sep + "footballappid-firebase-adminsdk.json"
cred = credentials.Certificate(path)
firebase_admin.initialize_app(cred)
