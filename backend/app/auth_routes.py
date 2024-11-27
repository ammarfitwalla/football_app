import os
import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db, User, Location, Position
from app.schemas import (UserSignup, UserLogin, UserResponse,
SetUsernameRequest, SetLocationRequest, SetPositionRequest, LoginResponse)
from app.firebase import auth as firebase_auth
from typing import Optional, List
from datetime import date

auth_router = APIRouter()

BASE_DIR = "firebase_service_account"
file_path = BASE_DIR + os.sep + "firebase_api_key.txt"

# Read the API key from the file
with open(file_path, 'r') as file:
    FIREBASE_API_KEY = file.read().strip()


@auth_router.post("/signup", response_model=dict)
def signup(user: UserSignup, db: Session = Depends(get_db)):
    try:
        print("email=", user.email, 'password=', user.password)
        
        # Create user in Firebase
        firebase_user = firebase_auth.create_user(
            email=user.email, password=user.password
        )
        print(firebase_user.uid, user.email)
        
        # Store user in the local database with a null username
        new_user = User(
            uid=firebase_user.uid,
            email=user.email,
            role="player",
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        print("new user created")
        
        # Return a UserResponse object with optional fields as None
        return {'uid': firebase_user.uid}

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error during signup: {str(e)}")



@auth_router.post("/login", response_model=LoginResponse)
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
        
        return {'uid':uid}
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication failed: {str(e)}")

@auth_router.post("/users/set-username", response_model=dict)
def set_username(payload: SetUsernameRequest, db: Session = Depends(get_db)):
    # Extract data from request payload
    uid = payload.uid
    display_name = payload.display_name
    username = payload.username

    # Fetch the user by UID
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if the username is already taken
    existing_user = db.query(User).filter(User.username == username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")

    # Update the user's username
    user.username = username
    user.display_name = display_name
    db.commit()
    db.refresh(user)

    return {"message": "Username set successfully"}


@auth_router.post("/users/set-location", response_model=dict)
def set_location(payload: SetLocationRequest, db: Session = Depends(get_db)):
    # Extract data from request body
    uid = payload.uid
    country = payload.country
    state = payload.state
    city = payload.city
    area = payload.area

    existing_location = db.query(Location).filter(
        Location.country == country,
        Location.state == state,
        Location.city == city,
        Location.area == area,
    ).first()

    # Fetch the user by UID
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.location_id = existing_location.id

    # Update the user's location_id
    db.commit()
    db.refresh(user)

    # Return UserResponse
    return {
        "message": "Location set successfully",
    }


# Endpoint to set position
@auth_router.post("/users/set-position", response_model=dict)
def set_position(payload: SetPositionRequest, db: Session = Depends(get_db)):    # Fetch the user
    uid = payload.uid
    position = payload.position

    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if position exists
    existing_position = db.query(Position).filter(
        Position.name == position
        ).first()
    user.position_id = existing_position.id

    # Update user's position
    db.commit()
    db.refresh(user)

    return {'message': 'Position set successfully'}

# Endpoint to set phone number and DOB
@auth_router.post("/users/set-details", response_model=UserResponse)
def set_details(uid: str, phone_number: Optional[str] = None, dob: Optional[date] = None, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.phone_number = phone_number if phone_number else user.phone_number
    user.dob = dob if dob else user.dob
    db.commit()
    db.refresh(user)
    return user

@auth_router.get("/users/check-details")
def check_details(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    missing_details = []
    if not user.username:
        missing_details.append("username")
    if not user.location_id:
        missing_details.append("location")
    if not user.position_id:
        missing_details.append("position")

    return {"missing_details": missing_details}

@auth_router.get("/locations/countries", response_model=List[str])
def get_countries(db: Session = Depends(get_db)):
    countries = db.query(Location.country).distinct().all()
    return [country[0] for country in countries]

@auth_router.get("/locations/states", response_model=List[str])
def get_states(country: str, db: Session = Depends(get_db)):
    states = db.query(Location.state).filter(Location.country == country).distinct().all()
    return [state[0] for state in states]

@auth_router.get("/locations/cities", response_model=List[str])
def get_cities(country: str, state: str, db: Session = Depends(get_db)):
    cities = db.query(Location.city).filter(Location.country == country, Location.state == state).distinct().all()
    return [city[0] for city in cities]

@auth_router.get("/locations/areas", response_model=List[str])
def get_areas(country: str, state: str, city: str, db: Session = Depends(get_db)):
    areas = db.query(Location.area).filter(Location.country == country, Location.state == state, Location.city == city).distinct().all()
    return [area[0] for area in areas if area[0]]

@auth_router.get("/positions/get-positions", response_model=List[str])
def get_positions(db: Session = Depends(get_db)):
    positions = db.query(Position.name).distinct().all()
    return [position[0] for position in positions]
