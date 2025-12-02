#!/bin/bash

# Step 1: Add REST API
echo "Adding REST API..."
amplify add api

# Step 2: Push to deploy
echo "Deploying to AWS..."
amplify push

# Step 3: Show status
echo "Showing project status..."
amplify status