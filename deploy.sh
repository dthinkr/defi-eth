#!/bin/bash

set -e
set -x

REPO_URL="https://github.com/dthinkr/defi-eth.git"
BRANCH="deploy"
REPO_DIR="defi-eth"

echo "Starting deployment script"

read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN
export NGROK_AUTH_TOKEN

echo "Current directory: $(pwd)"
echo "Checking for repository directory: $REPO_DIR"

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository"
    git clone -b $BRANCH $REPO_URL $REPO_DIR
else
    echo "Repository directory already exists"
fi

echo "Changing to repository directory"
cd $REPO_DIR
echo "Current directory after cd: $(pwd)"

update_from_remote() {
    echo "Updating from remote"
    git fetch origin $BRANCH
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH)
    
    if [ $LOCAL != $REMOTE ]; then
        echo "Changes detected, pulling updates"
        git pull origin $BRANCH
        echo "Running docker compose"
        NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN docker compose up -d --build
    else
        echo "No changes detected"
    fi
}

start_services() {
    echo "Starting services"
    NGROK_AUTH_TOKEN=$NGROK_AUTH_TOKEN docker compose up -d --build
    docker compose logs -f $(docker compose config --services | grep -v app)
}

update_from_remote
start_services

echo "Entering update loop"
while true; do
    sleep 300
    update_from_remote
done