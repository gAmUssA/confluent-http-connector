#!/bin/bash

# 🗑️ Delete the connector
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONNECTOR_NAME=${1:-"env-agency--flood-monitoring"}

echo -e "${BLUE}🗑️  Deleting connector: ${CONNECTOR_NAME}...${NC}"

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found. Please run setup first.${NC}"
    exit 1
fi

# Check required environment variables
required_vars=("CNFL_ENV" "CNFL_KAFKA_CLUSTER" "CNFL_CLOUD_API_KEY" "CNFL_CLOUD_API_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var not set${NC}"
        exit 1
    fi
done

# Check if httpie is installed, fallback to curl
if command -v http &> /dev/null; then
    HTTP_CLIENT="http"
else
    HTTP_CLIENT="curl"
fi

# Confirm deletion
echo -e "${YELLOW}⚠️  Are you sure you want to delete connector '${CONNECTOR_NAME}'? (y/N)${NC}"
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🚫 Deletion cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}🔍 Checking if connector exists...${NC}"

# Check if connector exists first
if [ "$HTTP_CLIENT" = "http" ]; then
    STATUS_RESPONSE=$(http GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        --print=b 2>/dev/null)
else
    STATUS_RESPONSE=$(curl -s -X GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" 2>/dev/null)
fi

if [ -z "$STATUS_RESPONSE" ] || echo "$STATUS_RESPONSE" | grep -q "does not exist"; then
    echo -e "${YELLOW}⚠️  Connector '${CONNECTOR_NAME}' does not exist${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Connector found, proceeding with deletion...${NC}"

# Delete the connector
echo -e "${YELLOW}🗑️  Deleting connector...${NC}"

if [ "$HTTP_CLIENT" = "http" ]; then
    RESPONSE=$(http DELETE \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        --print=HhBb 2>&1)
else
    RESPONSE=$(curl -s -X DELETE \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        -w "HTTP_STATUS:%{http_code}" 2>&1)
fi

# Check if the deletion was successful
if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK" || echo "$RESPONSE" | grep -q "HTTP_STATUS:200"; then
    echo -e "${GREEN}✅ Connector deleted successfully!${NC}"
    echo -e "${YELLOW}📝 Connector '${CONNECTOR_NAME}' has been removed${NC}"
    
    # Verify deletion
    echo -e "${YELLOW}🔍 Verifying deletion...${NC}"
    sleep 2
    
    if [ "$HTTP_CLIENT" = "http" ]; then
        VERIFY_RESPONSE=$(http GET \
            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
            --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
            --print=b 2>/dev/null)
    else
        VERIFY_RESPONSE=$(curl -s -X GET \
            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
            --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" 2>/dev/null)
    fi
    
    if echo "$VERIFY_RESPONSE" | grep -q "does not exist"; then
        echo -e "${GREEN}✅ Deletion verified - connector no longer exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Connector may still exist (deletion in progress)${NC}"
    fi
    
else
    echo -e "${RED}❌ Failed to delete connector${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE"
    exit 1
fi

echo -e "${GREEN}🎉 Connector deletion complete!${NC}"
echo -e "${YELLOW}💡 Note: Topics created by the connector will remain unless manually deleted${NC}"
