import os
import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db, User, Location, Position
from app.schemas import UserSignup, UserLogin, UserResponse, LocationCreate, PositionCreate
from app.firebase import auth as firebase_auth
from typing import Optional
from datetime import date

auth_router = APIRouter()

BASE_DIR = "firebase_service_account"
file_path = BASE_DIR + os.sep + "firebase_api_key.txt"

# Read the API key from the file
with open(file_path, 'r') as file:
    FIREBASE_API_KEY = file.read().strip()


@auth_router.post("/signup", response_model=UserResponse)
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
        return UserResponse(
            uid=new_user.uid,
            email=new_user.email,
            role=new_user.role,
            username=None,
            display_name=None,
            phone_number=None,
            dob=None,
            position=None,
            location=None,
        )

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

@auth_router.post("/users/set-username", response_model=UserResponse)
def set_username(uid: str, display_name: str, username: str, db: Session = Depends(get_db)):
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

    return UserResponse(
        uid=user.uid,
        email=user.email,
        role=user.role,
        username=user.username,
        phone_number=user.phone_number,
        dob=user.dob,
        position=None,  # Optional, will be populated later
        location=None,  # Optional, will be populated later
    )


@auth_router.post("/users/set-location", response_model=UserResponse)
def set_location(uid: str, location: LocationCreate, db: Session = Depends(get_db)):
    # Fetch the user
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if location exists
    existing_location = db.query(Location).filter(
        Location.country == location.country,
        Location.state == location.state,
        Location.city == location.city,
        Location.area == location.area,
    ).first()

    if existing_location:
        # Use existing location for the user
        user.location_id = existing_location.id
    else:
        # Create a new location
        new_location = Location(
            country=location.country,
            state=location.state,
            city=location.city,
            area=location.area,
        )
        db.add(new_location)
        db.commit()
        db.refresh(new_location)
        user.location_id = new_location.id

    # Update the user's location_id
    db.commit()
    db.refresh(user)

    # Construct location string for the response
    user_location = db.query(Location).filter(Location.id == user.location_id).first()
    if user_location.area:
        location_str = f"{user_location.area}, {user_location.city}, {user_location.state}, {user_location.country}"
    else:
        location_str = f"{user_location.city}, {user_location.state}, {user_location.country}"

    # Return UserResponse
    return UserResponse(
        uid=user.uid,
        email=user.email,
        role=user.role,
        phone_number=user.phone_number,
        dob=user.dob,
        position=None,  # Optional, will be populated later
        location=location_str,  # Concatenated location string
    )


# Endpoint to set position
@auth_router.post("/users/set-position", response_model=UserResponse)
def set_position(uid: str, position: PositionCreate, db: Session = Depends(get_db)):
    # Fetch the user
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if position exists
    existing_position = db.query(Position).filter(Position.name == position.name).first()

    if not existing_position:
        # Create a new position
        new_position = Position(name=position.name)
        db.add(new_position)
        db.commit()
        db.refresh(new_position)
        user.position_id = new_position.id
    else:
        user.position_id = existing_position.id

    # Update user's position
    db.commit()
    db.refresh(user)

    # Format the location string
    user_location = None
    if user.location_id:
        location = db.query(Location).filter(Location.id == user.location_id).first()
        if location:
            if location.area:
                user_location = f"{location.area}, {location.city}, {location.state}, {location.country}"
            else:
                user_location = f"{location.city}, {location.state}, {location.country}"

    # Return UserResponse
    return UserResponse(
        uid=user.uid,
        email=user.email,
        role=user.role,
        phone_number=user.phone_number,
        dob=user.dob,
        position=position.name,
        location=user_location,
    )


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
