#!/bin/bash

# 🌍 Create and activate Confluent Cloud environment
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ENV_NAME=${1:-"rmoff-demo"}

echo -e "${BLUE}🌍 Creating environment: ${ENV_NAME}...${NC}"

# Create environment
echo -e "${YELLOW}📝 Creating environment...${NC}"
ENV_OUTPUT=$(confluent environment create "$ENV_NAME" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create environment${NC}"
    echo "$ENV_OUTPUT"
    exit 1
fi

# Extract environment ID from output
ENV_ID=$(echo "$ENV_OUTPUT" | grep -E "^\| ID" | awk '{print $4}')

if [ -z "$ENV_ID" ]; then
    echo -e "${RED}❌ Could not extract environment ID${NC}"
    echo "$ENV_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✅ Environment created with ID: ${ENV_ID}${NC}"

# Set as active environment
echo -e "${YELLOW}🎯 Setting as active environment...${NC}"
confluent environment use "$ENV_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Environment ${ENV_NAME} (${ENV_ID}) is now active${NC}"
else
    echo -e "${RED}❌ Failed to set environment as active${NC}"
    exit 1
fi

# Save environment variables
echo "export CNFL_ENV=$ENV_ID" >> .env
echo -e "${GREEN}💾 Environment ID saved to .env file${NC}"

echo -e "${GREEN}🎉 Environment setup complete!${NC}"
