# Updated version of the schemas.py file with necessary changes.

from pydantic import BaseModel, Field
from typing import Optional, List


# User-related schemas
class UserSignup(BaseModel):
    email: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    uid: str


class UserResponse(BaseModel):
    uid: str
    email: str
    role: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    phone_number: Optional[str] = None
    dob: Optional[str] = None
    position: Optional[str] = None  # Name of the position
    location: Optional[str] = None  # Concatenated location string (e.g., "City, State, Country")

    class Config:
        orm_mode = True


# Position-related schemas
class PositionCreate(BaseModel):
    name: str


class PositionResponse(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True


# Location-related schemas
class LocationCreate(BaseModel):
    country: str
    state: str
    city: str
    area: Optional[str] = None


class SetLocationRequest(BaseModel):
    uid: str
    country: str
    state: str
    city: str
    area: Optional[str] = None

    class Config:
        orm_mode = True

class SetPositionRequest(BaseModel):
    uid: str
    position: str

    class Config:
        orm_mode = True

class SetUsernameRequest(BaseModel):
    uid: str
    display_name: str
    username: str


class SearchQuery(BaseModel):
    query: Optional[str] = None  # Search text input
    country: str  # Required: Filter by country
    state: str  # Required: Filter by state
    city: str  # Required: Filter by city
    role: str  # Required: Only search for users with a specific role (e.g., "player")
    age_filter: Optional[List[int]] = None  # Optional: [start_age, end_age]
    position_filter: Optional[List[str]] = None  # Optional: Filter by positions
