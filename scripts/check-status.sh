#!/bin/bash

# 📊 Check connector status
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

CONNECTOR_NAME=${1:-"env-agency--flood-monitoring"}

echo -e "${BLUE}📊 Checking connector status: ${CONNECTOR_NAME}...${NC}"

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

# Check if jq is installed for JSON parsing
if command -v jq &> /dev/null; then
    HAS_JQ=true
else
    HAS_JQ=false
    echo -e "${YELLOW}⚠️  jq not found, output will be raw JSON${NC}"
fi

echo -e "${YELLOW}🔍 Fetching connector status...${NC}"

# Get connector status
if [ "$HTTP_CLIENT" = "http" ]; then
    RESPONSE=$(http GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        --print=b 2>/dev/null)
else
    RESPONSE=$(curl -s -X GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/status" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET")
fi

# Check if the request was successful
if [ -z "$RESPONSE" ]; then
    echo -e "${RED}❌ Failed to get connector status - empty response${NC}"
    exit 1
fi

# Check for HTTP error responses (like 404, 401, etc.)
if echo "$RESPONSE" | grep -q '"error_code"\|"message".*"error"\|HTTP.*[45][0-9][0-9]'; then
    echo -e "${RED}❌ Failed to get connector status${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE"
    exit 1
fi

# Parse and display status
if [ "$HAS_JQ" = true ]; then
    # Extract key information using jq
    CONNECTOR_STATE=$(echo "$RESPONSE" | jq -r '.connector.state // "UNKNOWN"')
    CONNECTOR_TYPE=$(echo "$RESPONSE" | jq -r '.type // "UNKNOWN"')
    TASK_COUNT=$(echo "$RESPONSE" | jq '.tasks | length')
    
    echo -e "${GREEN}✅ Connector Status Retrieved${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}📋 Connector Details:${NC}"
    echo -e "  ${BLUE}Name:${NC} $CONNECTOR_NAME"
    echo -e "  ${BLUE}Type:${NC} $CONNECTOR_TYPE"
    
    # Color-code the state
    if [ "$CONNECTOR_STATE" = "RUNNING" ]; then
        echo -e "  ${BLUE}State:${NC} ${GREEN}$CONNECTOR_STATE${NC}"
    elif [ "$CONNECTOR_STATE" = "FAILED" ]; then
        echo -e "  ${BLUE}State:${NC} ${RED}$CONNECTOR_STATE${NC}"
    else
        echo -e "  ${BLUE}State:${NC} ${YELLOW}$CONNECTOR_STATE${NC}"
    fi
    
    echo -e "  ${BLUE}Tasks:${NC} $TASK_COUNT"
    
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}🔧 Task Details:${NC}"
    
    # Display task information
    echo "$RESPONSE" | jq -r '.tasks[] | "  Task \(.id): \(.state) (Worker: \(.worker_id))"' | while read -r line; do
        if echo "$line" | grep -q "RUNNING"; then
            echo -e "${GREEN}$line${NC}"
        elif echo "$line" | grep -q "FAILED"; then
            echo -e "${RED}$line${NC}"
        else
            echo -e "${YELLOW}$line${NC}"
        fi
    done
    
    # Check for errors
    ERROR_COUNT=$(echo "$RESPONSE" | jq '.errors_from_trace | length')
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${PURPLE}═══════════════════════════════════════${NC}"
        echo -e "${RED}⚠️  Errors Found:${NC}"
        echo "$RESPONSE" | jq -r '.errors_from_trace[]'
    fi
    
else
    # Display raw JSON if jq is not available
    echo -e "${GREEN}✅ Connector Status (Raw JSON):${NC}"
    echo "$RESPONSE"
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"

# Also try using Confluent CLI if available
if command -v confluent &> /dev/null; then
    echo -e "${YELLOW}🔧 Alternative: Using Confluent CLI...${NC}"
    
    # List connectors to get the connector ID
    CONNECTOR_LIST=$(confluent connect cluster list 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$CONNECTOR_LIST" ]; then
        echo -e "${BLUE}📋 Available Connectors:${NC}"
        echo "$CONNECTOR_LIST"
        
        # Try to get connector ID for detailed info
        CONNECTOR_ID=$(echo "$CONNECTOR_LIST" | grep "$CONNECTOR_NAME" | awk '{print $1}' | head -1)
        
        if [ -n "$CONNECTOR_ID" ]; then
            echo -e "${YELLOW}🔍 Detailed info for connector ID: $CONNECTOR_ID${NC}"
            confluent connect cluster describe "$CONNECTOR_ID" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not get detailed info${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not list connectors via CLI${NC}"
    fi
fi

echo -e "${GREEN}🎉 Status check complete!${NC}"
