from pydantic import BaseModel


# For signup and login requests
class UserSignup(BaseModel):
    email: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


# For returning user data
class UserResponse(BaseModel):
    uid: str
    email: str
    role: str
