# Use Python 3.11 to avoid 3.13 build issues
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy the rest of the app
COPY . .

# Expose port (Render uses 10000 by default for web services)
EXPOSE 10000

# Start the app using gunicorn with gevent
CMD ["gunicorn", "-k", "gevent", "app:app", "-b", "0.0.0.0:10000"]
