#!/bin/bash

if [ -z "$NGROK_AUTH_TOKEN" ]; then
    read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN
    export NGROK_AUTH_TOKEN
fi

# Start all services
docker-compose up -d --build

# Follow logs of all services except 'app'
docker-compose logs -f $(docker-compose config --services | grep -v app)