#!/bin/bash

set -e

# Configuration
REPO_URL="https://github.com/dthinkr/defi-eth.git"
REPO_NAME="defi-eth"
BRANCH="main"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in git docker docker-compose; do
    if ! command_exists $cmd; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# Clone or pull the repository
if [ ! -d "$REPO_NAME" ]; then
    git clone -b $BRANCH $REPO_URL
    cd $REPO_NAME
else
    cd $REPO_NAME
    git pull origin $BRANCH
fi

# Check for NGROK_AUTH_TOKEN in environment
if [ -z "$NGROK_AUTH_TOKEN" ]; then
    read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN
    export NGROK_AUTH_TOKEN
fi

# Remove ngrok.yml if it exists (we'll use environment variable instead)
if [ -f "ngrok.yml" ]; then
    rm ngrok.yml
fi

# Update docker-compose.yml to use the correct domain (if needed)
if grep -q "dthinkr.ngrok.app" docker-compose.yml; then
    echo "docker-compose.yml already contains the correct domain."
else
    echo "Updating docker-compose.yml with the correct domain..."
    sed -i.bak 's/--domain=[^ ]*/--domain=dthinkr.ngrok.app/' docker-compose.yml
    rm docker-compose.yml.bak
fi

# Build and start the containers
docker-compose up -d --build

# Wait for ngrok to start
sleep 5

# Get and display the public URL
NGROK_URL=$(docker-compose exec -T ngrok ngrok api tunnels list | grep -o 'public_url":"[^"]*' | cut -d'"' -f3)
echo "Your app is publicly available at: ${NGROK_URL}/defi-eth/"

# Follow logs of all services except 'app'
docker-compose logs -f $(docker-compose config --services | grep -v app)