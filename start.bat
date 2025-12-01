@echo off
REM Emergency Alert System Startup Script for Windows

echo === Emergency Alert System - Flask Application ===
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist ".env" (
    echo Warning: .env file not found. Please create it with your Supabase credentials.
    echo Example .env content:
    echo SUPABASE_URL=your_supabase_url
    echo SUPABASE_KEY=your_supabase_anon_key
    echo SECRET_KEY=your_secret_key
    echo.
)

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

if errorlevel 1 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Dependencies installed successfully!
echo.

REM Start the application
echo Starting Emergency Alert System...
echo Application will be available at: http://localhost:5000
echo Press Ctrl+C to stop the server
echo.

REM Run the Flask application
python app.py

pause
