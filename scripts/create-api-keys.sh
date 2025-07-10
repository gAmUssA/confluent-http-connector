#!/bin/bash

# 🔑 Create all required API keys
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 Creating API keys...${NC}"

# Source environment variables if .env exists
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found. Please run cluster creation first.${NC}"
    exit 1
fi

# Check required environment variables
if [ -z "$CNFL_KAFKA_CLUSTER" ] || [ -z "$CNFL_SR_ID" ]; then
    echo -e "${RED}❌ Required environment variables not set. Please run cluster creation first.${NC}"
    exit 1
fi

# Function to create API key and extract credentials
create_api_key() {
    local resource=$1
    local description=$2
    local result_var=$3
    
    echo -e "${YELLOW}🔐 Creating API key for ${description}...${NC}" >&2
    
    # Use JSON output for reliable parsing
    local output=$(confluent api-key create --resource "$resource" --output json 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}❌ Failed to create API key for ${description}${NC}" >&2
        echo "$output" >&2
        return 1
    fi
    
    # Check if jq is available for JSON parsing
    if command -v jq &> /dev/null; then
        # Extract API key and secret using jq
        local api_key=$(echo "$output" | jq -r '.api_key // empty')
        local api_secret=$(echo "$output" | jq -r '.api_secret // empty')
    else
        # Fallback: try to extract from JSON manually
        local api_key=$(echo "$output" | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4)
        local api_secret=$(echo "$output" | grep -o '"api_secret":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$api_key" ] || [ -z "$api_secret" ]; then
        echo -e "${RED}❌ Could not extract API credentials for ${description}${NC}" >&2
        echo -e "${RED}Raw output:${NC}" >&2
        echo "$output" >&2
        return 1
    fi
    
    echo -e "${GREEN}✅ API key created for ${description}${NC}" >&2
    echo -e "  ${YELLOW}Key:${NC} $api_key" >&2
    echo -e "  ${YELLOW}Secret:${NC} ${api_secret:0:8}...${NC}" >&2
    
    # Set the result variable
    eval "$result_var='$api_key:$api_secret'"
}

# Create API key for Kafka cluster
echo -e "${BLUE}📊 Creating Kafka cluster API key...${NC}"
create_api_key "$CNFL_KAFKA_CLUSTER" "Kafka cluster" KAFKA_CREDS
if [ $? -ne 0 ]; then
    exit 1
fi
KAFKA_API_KEY=$(echo "$KAFKA_CREDS" | cut -d: -f1)
KAFKA_API_SECRET=$(echo "$KAFKA_CREDS" | cut -d: -f2)

# Create API key for cloud resources
echo -e "${BLUE}☁️ Creating cloud resources API key...${NC}"
create_api_key "cloud" "cloud resources" CLOUD_CREDS
if [ $? -ne 0 ]; then
    exit 1
fi
CLOUD_API_KEY=$(echo "$CLOUD_CREDS" | cut -d: -f1)
CLOUD_API_SECRET=$(echo "$CLOUD_CREDS" | cut -d: -f2)

# Create API key for Schema Registry
echo -e "${BLUE}📋 Creating Schema Registry API key...${NC}"
create_api_key "$CNFL_SR_ID" "Schema Registry" SR_CREDS
if [ $? -ne 0 ]; then
    exit 1
fi
SR_API_KEY=$(echo "$SR_CREDS" | cut -d: -f1)
SR_API_SECRET=$(echo "$SR_CREDS" | cut -d: -f2)

# Save API keys to .env file
echo -e "${YELLOW}💾 Saving API keys to .env file...${NC}"
{
    echo "export CNFL_KC_API_KEY=$KAFKA_API_KEY"
    echo "export CNFL_KC_API_SECRET=$KAFKA_API_SECRET"
    echo "export CNFL_CLOUD_API_KEY=$CLOUD_API_KEY"
    echo "export CNFL_CLOUD_API_SECRET=$CLOUD_API_SECRET"
    echo "export CNFL_SR_API_KEY=$SR_API_KEY"
    echo "export CNFL_SR_API_SECRET=$SR_API_SECRET"
} >> .env

echo -e "${GREEN}✅ All API keys created and saved!${NC}"
echo -e "${YELLOW}⚠️  Important: API secrets cannot be retrieved later. Keep the .env file secure!${NC}"
echo -e "${GREEN}🎉 API keys setup complete!${NC}"
