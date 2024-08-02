#!/bin/bash

REPO_URL="https://github.com/dthinkr/defi-eth.git"
BRANCH="deploy"

read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN
export NGROK_AUTH_TOKEN

update_from_remote() {
    git fetch origin $BRANCH
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH)
    
    if [ $LOCAL != $REMOTE ]; then
        echo "Updating from remote..."
        git pull origin $BRANCH
        NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN docker-compose up -d --build
    fi
}

start_services() {
    NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN docker-compose up -d --build
    docker-compose logs -f $(docker-compose config --services | grep -v app)
}

update_from_remote
start_services

while true; do
    sleep 300
    update_from_remote
done