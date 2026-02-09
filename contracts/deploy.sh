#!/bin/bash

# Ensure we are in the contracts directory
cd "$(dirname "$0")"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "Error: .env file not found in $(pwd). Please create one with PRIVATE_KEY."
    exit 1
fi

# Run deployment (explicitly broadcast)
leo deploy --broadcast --private-key "$PRIVATE_KEY" --network "$NETWORK" --endpoint "$ENDPOINT"
