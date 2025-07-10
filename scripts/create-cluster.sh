#!/bin/bash

# ☁️ Create and activate Kafka cluster
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME=${1:-"cluster00"}
CLOUD_PROVIDER=${2:-"aws"}
REGION=${3:-"us-west-2"}

echo -e "${BLUE}☁️ Creating Kafka cluster: ${CLUSTER_NAME}...${NC}"
echo -e "${YELLOW}📍 Provider: ${CLOUD_PROVIDER}, Region: ${REGION}${NC}"

# Create Kafka cluster
echo -e "${YELLOW}🔨 Creating cluster (this may take a few minutes)...${NC}"
CLUSTER_OUTPUT=$(confluent kafka cluster create "$CLUSTER_NAME" --cloud "$CLOUD_PROVIDER" --region "$REGION" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create cluster${NC}"
    echo "$CLUSTER_OUTPUT"
    exit 1
fi

# Extract cluster ID and endpoint from output
CLUSTER_ID=$(echo "$CLUSTER_OUTPUT" | grep -E "^\| ID" | awk '{print $4}')
CLUSTER_ENDPOINT=$(echo "$CLUSTER_OUTPUT" | grep -E "^\| Endpoint" | awk '{print $4}')

if [ -z "$CLUSTER_ID" ] || [ -z "$CLUSTER_ENDPOINT" ]; then
    echo -e "${RED}❌ Could not extract cluster details${NC}"
    echo "$CLUSTER_OUTPUT"
    exit 1
fi

# Extract broker hostname from endpoint (remove SASL_SSL:// prefix and :9092 suffix)
KAFKA_BROKER=$(echo "$CLUSTER_ENDPOINT" | sed 's|SASL_SSL://||' | sed 's|:9092||')

echo -e "${GREEN}✅ Cluster created:${NC}"
echo -e "  ${YELLOW}ID:${NC} $CLUSTER_ID"
echo -e "  ${YELLOW}Endpoint:${NC} $CLUSTER_ENDPOINT"
echo -e "  ${YELLOW}Broker:${NC} $KAFKA_BROKER"

# Set as active cluster
echo -e "${YELLOW}🎯 Setting as active cluster...${NC}"
confluent kafka cluster use "$CLUSTER_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cluster ${CLUSTER_NAME} (${CLUSTER_ID}) is now active${NC}"
else
    echo -e "${RED}❌ Failed to set cluster as active${NC}"
    exit 1
fi

# Get Schema Registry details
echo -e "${YELLOW}📋 Getting Schema Registry details...${NC}"
SR_OUTPUT=$(confluent schema-registry cluster describe 2>&1)

if [ $? -eq 0 ]; then
    SR_ID=$(echo "$SR_OUTPUT" | grep -E "^\| Cluster" | awk '{print $4}')
    SR_ENDPOINT=$(echo "$SR_OUTPUT" | grep -E "^\| Endpoint URL" | awk '{print $5}')
    SR_HOST=$(echo "$SR_ENDPOINT" | sed 's|https://||')
    
    echo -e "${GREEN}✅ Schema Registry found:${NC}"
    echo -e "  ${YELLOW}ID:${NC} $SR_ID"
    echo -e "  ${YELLOW}Host:${NC} $SR_HOST"
else
    echo -e "${RED}❌ Failed to get Schema Registry details${NC}"
    echo "$SR_OUTPUT"
    exit 1
fi

# Save environment variables
{
    echo "export CNFL_KAFKA_CLUSTER=$CLUSTER_ID"
    echo "export CNFL_KAFKA_BROKER=$KAFKA_BROKER"
    echo "export CNFL_SR_ID=$SR_ID"
    echo "export CNFL_SR_HOST=$SR_HOST"
} >> .env

echo -e "${GREEN}💾 Cluster details saved to .env file${NC}"
echo -e "${GREEN}🎉 Cluster setup complete!${NC}"
