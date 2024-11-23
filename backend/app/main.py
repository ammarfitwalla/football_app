from fastapi import FastAPI
from app.auth_routes import auth_router

app = FastAPI()

# Include authentication routes
app.include_router(auth_router)

@app.get("/")
def read_root():
    return {"message": "Welcome to the Football App"}
