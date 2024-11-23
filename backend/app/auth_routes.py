import os
import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db, User
from app.schemas import UserSignup, UserLogin, UserResponse
from app.firebase import auth as firebase_auth

auth_router = APIRouter()

BASE_DIR = "firebase_service_account"
file_path = BASE_DIR + os.sep + "firebase_api_key.txt"

# Read the API key from the file
with open(file_path, 'r') as file:
    FIREBASE_API_KEY = file.read().strip()


# Signup Route
@auth_router.post("/signup", response_model=UserResponse)
def signup(user: UserSignup, db: Session = Depends(get_db)):
    try:
        print("email=", user.email, 'password=', user.password)
        # Create user in Firebase
        firebase_user = firebase_auth.create_user(
            email=user.email, password=user.password
        )

        # Store user in local database
        try:
            new_user = User(uid=firebase_user.uid, email=user.email, role="player")
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            print("new user created")
        except Exception as err:
            print("error creating new user", str(err))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error during signup: {str(e)}")


@auth_router.post("/login", response_model=UserResponse)
def login(user: UserLogin, db: Session = Depends(get_db)):
    try:
        # Use Firebase REST API for email/password authentication
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
        payload = {
            "email": user.email,
            "password": user.password,
            "returnSecureToken": True
        }
        response = requests.post(url, json=payload)
        if response.status_code != 200:
            raise HTTPException(status_code=401, detail="Invalid email or password")

        data = response.json()
        id_token = data["idToken"]

        # Verify the ID token using Firebase Admin SDK
        decoded_token = firebase_auth.verify_id_token(id_token)
        uid = decoded_token["uid"]

        # Check if the user exists in the local database
        db_user = db.query(User).filter(User.uid == uid).first()
        if not db_user:
            raise HTTPException(status_code=404, detail="User not found")

        return db_user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")
