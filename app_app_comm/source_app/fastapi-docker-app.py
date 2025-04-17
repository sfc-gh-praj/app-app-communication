from fastapi import FastAPI, HTTPException
from typing import Dict, List
import random
import uvicorn
from users import users 

app = FastAPI(title="Simple FastAPI Demo", 
              description="A simple FastAPI application with three routes returning different output types")


@app.get("/", tags=["Root"])
async def root() -> Dict[str, str]:
    """
    Root endpoint that returns a simple welcome message.
    
    Returns:
        Dict: A dictionary with a welcome message
    """
    return {"message": "Welcome to the Simple FastAPI Demo"}

@app.get("/users", tags=["Users"])
async def get_users() -> List[Dict[str, str]]:
    """
    Returns a list of all users.
    
    Returns:
        List[Dict]: A list of user dictionaries with id, name, and email
    """

    return users

@app.get("/users/{userid}", tags=["User"])
async def get_random_user(userid: str) -> Dict[str,str]:
    """
    Retrieves a user by their ID.
    
    Parameters:
        userid (str): The ID of the user to retrieve
        
    Returns:
        Dict[str, str]: Dictionary containing user information
        
    Raises:
        HTTPException: If the user ID is not found    """
    user = next((user for user in users if user["id"] == userid), None)
    if not user:
        raise HTTPException(status_code=404, detail=f"User with ID {userid} not found")
    return user


if __name__ == "__main__":
    uvicorn.run("fastapi-docker-app:app", host="0.0.0.0", port=8000, reload=True)
