#!/bin/bash

# 📋 List all connectors
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Listing all connectors...${NC}"

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

echo -e "${YELLOW}🔍 Fetching connectors via REST API...${NC}"

# Get list of connectors
if [ "$HTTP_CLIENT" = "http" ]; then
    RESPONSE=$(http GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        --print=b 2>/dev/null)
else
    RESPONSE=$(curl -s -X GET \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET")
fi

# Check if the request was successful
if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ Failed to get connector list${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE"
    exit 1
fi

# Parse and display connectors
if [ "$HAS_JQ" = true ]; then
    CONNECTOR_COUNT=$(echo "$RESPONSE" | jq '. | length')
    
    if [ "$CONNECTOR_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}📭 No connectors found${NC}"
    else
        echo -e "${GREEN}✅ Found $CONNECTOR_COUNT connector(s):${NC}"
        echo -e "${PURPLE}═══════════════════════════════════════${NC}"
        
        # List each connector
        echo "$RESPONSE" | jq -r '.[]' | while read -r connector_name; do
            echo -e "${BLUE}🔌 $connector_name${NC}"
            
            # Get status for each connector
            if [ "$HTTP_CLIENT" = "http" ]; then
                STATUS_RESPONSE=$(http GET \
                    "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$connector_name/status" \
                    --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
                    --print=b 2>/dev/null)
            else
                STATUS_RESPONSE=$(curl -s -X GET \
                    "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$connector_name/status" \
                    --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET")
            fi
            
            # Check for actual HTTP errors, not just JSON field names containing 'error'
            if [ -n "$STATUS_RESPONSE" ] && ! echo "$STATUS_RESPONSE" | grep -q '"error_code"\|"message".*"error"\|HTTP.*[45][0-9][0-9]'; then
                STATE=$(echo "$STATUS_RESPONSE" | jq -r '.connector.state // "UNKNOWN"')
                TYPE=$(echo "$STATUS_RESPONSE" | jq -r '.type // "UNKNOWN"')
                TASK_COUNT=$(echo "$STATUS_RESPONSE" | jq '.tasks | length')
                
                # Color-code the state
                if [ "$STATE" = "RUNNING" ]; then
                    STATE_COLOR="${GREEN}$STATE${NC}"
                elif [ "$STATE" = "FAILED" ]; then
                    STATE_COLOR="${RED}$STATE${NC}"
                else
                    STATE_COLOR="${YELLOW}$STATE${NC}"
                fi
                
                echo -e "  ${YELLOW}Type:${NC} $TYPE"
                echo -e "  ${YELLOW}State:${NC} $STATE_COLOR"
                echo -e "  ${YELLOW}Tasks:${NC} $TASK_COUNT"
            else
                echo -e "  ${RED}Status: Could not retrieve${NC}"
            fi
            
            echo -e "${PURPLE}───────────────────────────────────────${NC}"
        done
    fi
else
    # Display raw JSON if jq is not available
    echo -e "${GREEN}✅ Connector List (Raw JSON):${NC}"
    echo "$RESPONSE"
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"

# Also try using Confluent CLI if available
if command -v confluent &> /dev/null; then
    echo -e "${YELLOW}🔧 Alternative: Using Confluent CLI...${NC}"
    
    CLI_OUTPUT=$(confluent connect cluster list 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$CLI_OUTPUT" ]; then
        echo -e "${GREEN}✅ Confluent CLI Output:${NC}"
        echo "$CLI_OUTPUT"
    else
        echo -e "${YELLOW}⚠️  Could not list connectors via CLI${NC}"
    fi
fi

echo -e "${GREEN}🎉 Connector listing complete!${NC}"
