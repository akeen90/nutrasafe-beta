# NutraSafe Background Removal Service
# Uses Python 3.11 slim image for smaller size

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies required by rembg/onnxruntime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download rembg models during build (faster cold starts)
# isnet-general-use is better for product photos
RUN python -c "from rembg import new_session; new_session('isnet-general-use')"

# Copy application code
COPY main.py .

# Set environment variables
ENV PORT=8080
ENV PYTHONUNBUFFERED=1

# Run with gunicorn for production
CMD exec gunicorn --bind :$PORT --workers 1 --threads 4 --timeout 120 main:app
