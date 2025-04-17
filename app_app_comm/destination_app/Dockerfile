# Use Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY streamlit_ui.py .

ENV SERVICE_URL=localhost:8000

# Expose port
EXPOSE 8001

# Run the application
CMD ["streamlit", "run", "streamlit_ui.py", "--server.port", "8001", "--server.address", "0.0.0.0"]

# CMD ["uvicorn", "endpoint_request:app", "--host", "0.0.0.0", "--port", "8001"] 