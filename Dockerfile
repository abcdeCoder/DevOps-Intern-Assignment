# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Pull and install MongoDB
RUN apt-get update && apt-get install -y gnupg wget && apt-get clean
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
RUN apt-get update && apt-get install -y mongodb-org && apt-get clean

# Copy the .env file into the container (if available)
COPY .env .env

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=development


# Expose port 5000 for the Flask app and port 27017 for MongoDB
EXPOSE 5000
EXPOSE 27017

# Define environment variable for MongoDB URI
ENV MONGODB_URI=mongodb://localhost:27017/

# Export environment variables from the .env file
RUN export $(cat .env | xargs)

# Start MongoDB and then run the Flask application
CMD mongod --fork --logpath /var/log/mongodb.log && flask run --host=0.0.0.0
