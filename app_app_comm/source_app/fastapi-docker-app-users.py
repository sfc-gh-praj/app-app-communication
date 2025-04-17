from fastapi import FastAPI, HTTPException,Request
from typing import Dict, List
import random
import uvicorn
from users import users 
import logging
import sys


#This is the source application that will be used for accessing the endpoints using service functions

app = FastAPI(title="Simple FastAPI Demo", 
              description="A simple FastAPI application with 2 routes returning different output types and to be used for inter-application communication using service functions")

def get_logger(logger_name):
   logger = logging.getLogger(logger_name)
   logger.setLevel(logging.DEBUG)
   handler = logging.StreamHandler(sys.stdout)
   handler.setLevel(logging.DEBUG)
   handler.setFormatter(
      logging.Formatter(
      '%(name)s [%(asctime)s] [%(levelname)s] %(message)s'))
   logger.addHandler(handler)
   return logger

logger = get_logger('Get users')


@app.get("/", tags=["Root"])
async def root() -> Dict[str, str]:
    """
    Root endpoint that returns a simple welcome message.
    
    Returns:
        Dict: A dictionary with a welcome message
    """
    return {"message": "Welcome to the Simple FastAPI Demo"}

@app.post("/users", tags=["Endpoints"])
async def get_users(request: Request):
    """
    Returns a list of sample users formatted according to Snowflake remote service data format.
    Each user is represented as a list with row number and user data.
    
    Returns:
        Dict: A dictionary with 'data' key containing list of lists with user data
    """
    request_body = await request.json()
    request_body = request_body['data']
    # Check if the request is for "All" users

    # Format response according to Snowflake remote service format
    # which expects {"data": [[row_num, field1, field2, ...]]}
    data = []
    for idx, user in enumerate(users):
        user_data = {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "role": user["role"],
            "department": user["department"],
            "location": user["location"]
        }
        data.append([idx, user_data])
    print(data)
    return {"data": data}


@app.post("/specific_user", tags=["Endpoints1"])
async def get_random_user(request: Request):
    """
    Retrieves a user by their ID.
    """
    request_body = await request.json()
    request_body = request_body['data']
    data = []
    
    # Fix: request_body is a list with [index, user_data]
     # Unpack the list
    
    for index, user_id in request_body:
        local_user_id = user_id
        print(f"local_user_id => {local_user_id}")
        logger.info(f"local_user_id => {local_user_id}")
        user = next((user for user in users if user["id"] == local_user_id), None)
        logger.info(f"user => {user}")
        if not user:
            raise HTTPException(status_code=404, detail=f"User with ID {local_user_id} not found")
        
        user_data = {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "role": user["role"],
            "department": user["department"],
            "location": user["location"]
        }
        data.append([index, user_data])

    return {"data": data}


if __name__ == "__main__":
    uvicorn.run("fastapi-docker-app-users:app", host="0.0.0.0", port=8000, reload=True)
