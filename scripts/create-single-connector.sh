#!/bin/bash

# 🔌 Create HTTP Source connector (single endpoint)
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONNECTOR_NAME=${1:-"env-agency--flood-monitoring-stations"}

echo -e "${BLUE}🔌 Creating single endpoint HTTP Source connector: ${CONNECTOR_NAME}...${NC}"

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found. Please run setup first.${NC}"
    exit 1
fi

# Check required environment variables
required_vars=("CNFL_ENV" "CNFL_KAFKA_CLUSTER" "CNFL_CLOUD_API_KEY" "CNFL_CLOUD_API_SECRET" "CNFL_KC_API_KEY" "CNFL_KC_API_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var not set${NC}"
        exit 1
    fi
done

# Check if httpie is installed, fallback to curl
if command -v http &> /dev/null; then
    HTTP_CLIENT="http"
    echo -e "${GREEN}✅ Using httpie for HTTP requests${NC}"
else
    HTTP_CLIENT="curl"
    echo -e "${YELLOW}⚠️  httpie not found, using curl${NC}"
fi

echo -e "${YELLOW}🌐 API Endpoint: https://environment.data.gov.uk/flood-monitoring${NC}"
echo -e "${YELLOW}📍 Path: /id/stations${NC}"
echo -e "${YELLOW}📊 Topic: flood-monitoring-stations${NC}"

# Create connector configuration
if [ "$HTTP_CLIENT" = "http" ]; then
    echo -e "${YELLOW}🔧 Creating connector with httpie...${NC}"
    
    RESPONSE=$(http PUT \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/config" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        content-type:application/json \
        connector.class="HttpSourceV2" \
        name="" \
        http.api.base.url="https://environment.data.gov.uk/flood-monitoring" \
        api1.http.api.path="/id/stations" \
        api1.http.offset.mode="SIMPLE_INCREMENTING" \
        api1.http.initial.offset="0" \
        api1.request.interval.ms="3600000" \
        api1.topics="flood-monitoring-stations" \
        kafka.api.key="$CNFL_KC_API_KEY" \
        kafka.api.secret="$CNFL_KC_API_SECRET" \
        output.data.format="AVRO" \
        tasks.max="1" 2>&1)
else
    echo -e "${YELLOW}🔧 Creating connector with curl...${NC}"
    
    RESPONSE=$(curl -s -X PUT \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/config" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        -H "Content-Type: application/json" \
        -d '{
            "connector.class": "HttpSourceV2",
            "name": "",
            "http.api.base.url": "https://environment.data.gov.uk/flood-monitoring",
            "api1.http.api.path": "/id/stations",
            "api1.http.offset.mode": "SIMPLE_INCREMENTING",
            "api1.http.initial.offset": "0",
            "api1.request.interval.ms": "3600000",
            "api1.topics": "flood-monitoring-stations",
            "kafka.api.key": "'$CNFL_KC_API_KEY'",
            "kafka.api.secret": "'$CNFL_KC_API_SECRET'",
            "output.data.format": "AVRO",
            "tasks.max": "1"
        }' 2>&1)
fi

# Check if the request was successful
if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK" || echo "$RESPONSE" | grep -q '"name"'; then
    echo -e "${GREEN}✅ Connector created successfully!${NC}"
    echo -e "${YELLOW}📝 Connector details:${NC}"
    echo -e "  ${BLUE}Name:${NC} $CONNECTOR_NAME"
    echo -e "  ${BLUE}Type:${NC} HttpSourceV2"
    echo -e "  ${BLUE}Endpoint:${NC} https://environment.data.gov.uk/flood-monitoring/id/stations"
    echo -e "  ${BLUE}Topic:${NC} flood-monitoring-stations"
    echo -e "  ${BLUE}Interval:${NC} 1 hour (3600000 ms)"
    echo -e "  ${BLUE}Format:${NC} AVRO"
else
    echo -e "${RED}❌ Failed to create connector${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE"
    exit 1
fi

echo -e "${GREEN}🎉 Single endpoint connector setup complete!${NC}"
echo -e "${YELLOW}💡 Use 'make status' to check connector status${NC}"
