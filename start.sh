#!/bin/bash
# Startup script for Railway
# Initializes database then starts the API

echo "🚀 Starting OCRimageflow..."

# Initialize database
echo "📦 Initializing database..."
python init_db.py

# Check if init was successful
if [ $? -eq 0 ]; then
    echo "✅ Database ready!"
    echo "🌐 Starting API server..."
    uvicorn main:app --host 0.0.0.0 --port $PORT
else
    echo "❌ Database initialization failed. Exiting."
    exit 1
fi
