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

# Check for ngrok.yml and create if it doesn't exist
if [ ! -f "ngrok.yml" ]; then
    if [ -z "$NGROK_AUTH_TOKEN" ]; then
        read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN
    fi
    cat > ngrok.yml << EOL
version: "2"
authtoken: $NGROK_AUTH_TOKEN
tunnels:
  defi-eth:
    addr: nginx:80
    proto: http
EOL
fi

# Update docker-compose.yml to use the correct domain
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's/--domain=.*ngrok.app/--domain=dthinkr.ngrok.app/' docker-compose.yml
else
    # Linux and others
    sed -i 's/--domain=.*ngrok.app/--domain=dthinkr.ngrok.app/' docker-compose.yml
fi

# Print the updated ngrok command from docker-compose.yml
echo "Updated ngrok command in docker-compose.yml:"
grep -A 3 "ngrok:" docker-compose.yml

# Build and start the containers
docker-compose up -d --build

# Wait for ngrok to start
sleep 5

# Get and display the public URL
NGROK_URL=$(docker-compose exec -T ngrok ngrok api tunnels list | grep -o 'public_url":"[^"]*' | cut -d'"' -f3)
echo "Your app is publicly available at: ${NGROK_URL}/defi-eth/"

# Follow logs of all services except 'app'
docker-compose logs -f $(docker-compose config --services | grep -v app)