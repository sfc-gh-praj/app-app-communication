import streamlit as st
import requests
import os
import pandas as pd
from typing import Union, List, Dict

def fetch_all_users() -> List[Dict]:
    """
    Fetch all users from the API
    """
    base_url = os.getenv('SERVICE_URL', 'localhost:8000')
    url = f"http://{base_url}/users"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Failed to fetch users. Status code: {response.status_code}")
            return []
    except Exception as e:
        st.error(f"Error fetching users: {str(e)}")
        return []

def fetch_single_user(user_id: str) -> Union[Dict, None]:
    """
    Fetch a single user by ID
    """
    base_url = os.getenv('SERVICE_URL', 'localhost:8000')
    url = f"http://{base_url}/users/{user_id}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()
        else:
            st.error(f"Failed to fetch user {user_id}. Status code: {response.status_code}")
            return None
    except Exception as e:
        st.error(f"Error fetching user {user_id}: {str(e)}")
        return None

def main():
    st.title("User Management Report")
    st.markdown("""
    This report allows you to:
    - View all users in the system
    - Search for specific users by ID
    """)
    
    # Create a radio button for selecting the view mode
    view_mode = st.radio(
        "Select View Mode",
        ["View All Users", "View Specific User"]
    )
    
    if view_mode == "View All Users":
        st.subheader("All Users")
        if st.button("Fetch All Users"):
            users_data = fetch_all_users()
            if users_data:
                df = pd.DataFrame(users_data)
                st.dataframe(df)
    
    else:  # View Specific User
        st.subheader("View Specific User")
        user_id = st.text_input("Enter User ID")
        if user_id and st.button("Fetch User"):
            user_data = fetch_single_user(user_id)
            if user_data:
                # Convert single dictionary to DataFrame
                df = pd.DataFrame([user_data])
                st.dataframe(df)

if __name__ == "__main__":
    main()