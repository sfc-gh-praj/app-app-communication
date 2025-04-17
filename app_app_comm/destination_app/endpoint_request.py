from fastapi import FastAPI, HTTPException
import requests
import os
from typing import Dict, Optional

app = FastAPI(title="User Data API", 
              description="API to fetch user data from another APP")

@app.get("/users/{user_id}", response_model=Dict)
async def get_user_data(user_id: str) -> Dict:
    """
    Fetches single user data from endpoint and returns the response
    """
    base_url = os.getenv('SERVICE_URL', 'localhost:8000')
    url = f"http://{base_url}/users/{user_id}"
    
    try:
        # Fetch data for the user
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(status_code=response.status_code, 
                              detail=f"Failed to fetch data for user {user_id}")
            
    except Exception as e:
        raise HTTPException(status_code=500, 
                          detail=f"Error processing user {user_id}: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
