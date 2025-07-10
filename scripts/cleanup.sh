#!/bin/bash

# 🧹 Cleanup resources
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up Confluent Cloud resources...${NC}"

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found. Cannot proceed with cleanup.${NC}"
    exit 1
fi

# Check required environment variables
required_vars=("CNFL_ENV" "CNFL_KAFKA_CLUSTER")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var not set${NC}"
        exit 1
    fi
done

# Warning message
echo -e "${YELLOW}⚠️  WARNING: This will delete the following resources:${NC}"
echo -e "${RED}  • All connectors in the cluster${NC}"
echo -e "${RED}  • API keys created for this project${NC}"
echo -e "${RED}  • The Kafka cluster${NC}"
echo -e "${RED}  • The Confluent environment${NC}"
echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}"
echo ""
echo -e "${YELLOW}Are you sure you want to proceed? Type 'DELETE' to confirm:${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo -e "${YELLOW}🚫 Cleanup cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}🔍 Starting cleanup process...${NC}"

# Step 1: Delete all connectors
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🗑️  Step 1: Deleting connectors...${NC}"

if [ -n "$CNFL_CLOUD_API_KEY" ] && [ -n "$CNFL_CLOUD_API_SECRET" ]; then
    # Check if httpie is installed, fallback to curl
    if command -v http &> /dev/null; then
        HTTP_CLIENT="http"
    else
        HTTP_CLIENT="curl"
    fi
    
    # Get list of connectors
    if [ "$HTTP_CLIENT" = "http" ]; then
        CONNECTORS=$(http GET \
            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors" \
            --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
            --print=b 2>/dev/null)
    else
        CONNECTORS=$(curl -s -X GET \
            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors" \
            --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET")
    fi
    
    if [ -n "$CONNECTORS" ] && ! echo "$CONNECTORS" | grep -q "error"; then
        if command -v jq &> /dev/null; then
            CONNECTOR_COUNT=$(echo "$CONNECTORS" | jq '. | length')
            if [ "$CONNECTOR_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}Found $CONNECTOR_COUNT connector(s) to delete...${NC}"
                echo "$CONNECTORS" | jq -r '.[]' | while read -r connector_name; do
                    echo -e "${YELLOW}Deleting connector: $connector_name${NC}"
                    if [ "$HTTP_CLIENT" = "http" ]; then
                        http DELETE \
                            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$connector_name" \
                            --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
                            --print=h >/dev/null 2>&1
                    else
                        curl -s -X DELETE \
                            "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$connector_name" \
                            --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" >/dev/null 2>&1
                    fi
                    echo -e "${GREEN}✅ Deleted: $connector_name${NC}"
                done
            else
                echo -e "${YELLOW}No connectors found${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  jq not available, skipping connector deletion${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not retrieve connectors or none exist${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cloud API keys not available, skipping connector deletion${NC}"
fi

# Step 2: Delete API keys
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🔑 Step 2: Deleting API keys...${NC}"

if command -v confluent &> /dev/null; then
    # Delete Kafka cluster API key
    if [ -n "$CNFL_KC_API_KEY" ]; then
        echo -e "${YELLOW}Deleting Kafka cluster API key: $CNFL_KC_API_KEY${NC}"
        confluent api-key delete "$CNFL_KC_API_KEY" --force 2>/dev/null || echo -e "${YELLOW}⚠️  Could not delete Kafka API key${NC}"
    fi
    
    # Delete Cloud API key
    if [ -n "$CNFL_CLOUD_API_KEY" ]; then
        echo -e "${YELLOW}Deleting Cloud API key: $CNFL_CLOUD_API_KEY${NC}"
        confluent api-key delete "$CNFL_CLOUD_API_KEY" --force 2>/dev/null || echo -e "${YELLOW}⚠️  Could not delete Cloud API key${NC}"
    fi
    
    # Delete Schema Registry API key
    if [ -n "$CNFL_SR_API_KEY" ]; then
        echo -e "${YELLOW}Deleting Schema Registry API key: $CNFL_SR_API_KEY${NC}"
        confluent api-key delete "$CNFL_SR_API_KEY" --force 2>/dev/null || echo -e "${YELLOW}⚠️  Could not delete SR API key${NC}"
    fi
    
    echo -e "${GREEN}✅ API key deletion completed${NC}"
else
    echo -e "${YELLOW}⚠️  Confluent CLI not available, skipping API key deletion${NC}"
fi

# Step 3: Delete Kafka cluster
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🗄️  Step 3: Deleting Kafka cluster...${NC}"

if command -v confluent &> /dev/null && [ -n "$CNFL_KAFKA_CLUSTER" ]; then
    echo -e "${YELLOW}Deleting Kafka cluster: $CNFL_KAFKA_CLUSTER${NC}"
    confluent kafka cluster delete "$CNFL_KAFKA_CLUSTER" --force 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Kafka cluster deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not delete Kafka cluster (may require manual deletion)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot delete Kafka cluster${NC}"
fi

# Step 4: Delete environment
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🌍 Step 4: Deleting environment...${NC}"

if command -v confluent &> /dev/null && [ -n "$CNFL_ENV" ]; then
    echo -e "${YELLOW}Deleting environment: $CNFL_ENV${NC}"
    confluent environment delete "$CNFL_ENV" --force 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Environment deleted${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not delete environment (may require manual deletion)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cannot delete environment${NC}"
fi

# Step 5: Clean up local files
echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📁 Step 5: Cleaning up local files...${NC}"

if [ -f .env ]; then
    echo -e "${YELLOW}Removing .env file...${NC}"
    rm .env
    echo -e "${GREEN}✅ .env file removed${NC}"
fi

# Optional: Remove any temporary files
if [ -d temp ]; then
    echo -e "${YELLOW}Removing temp directory...${NC}"
    rm -rf temp
    echo -e "${GREEN}✅ Temp directory removed${NC}"
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Cleanup completed!${NC}"
echo -e "${YELLOW}💡 Note: Some resources may take a few minutes to be fully deleted${NC}"
echo -e "${YELLOW}💡 Check the Confluent Cloud console to verify all resources are removed${NC}"
