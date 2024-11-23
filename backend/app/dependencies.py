from fastapi import Depends, HTTPException
from firebase_admin import auth as firebase_auth

# Role-based access dependency
def require_role(required_role: str):
    def role_checker(token: str = Depends(firebase_auth.verify_id_token)):
        user_role = token.get('role', 'player')
        if user_role != required_role:
            raise HTTPException(status_code=403, detail=f"Access requires {required_role} role")
        return token
    return role_checker
