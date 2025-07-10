#!/bin/bash

# 🔌 Create HTTP Source connector (multiple endpoints)
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONNECTOR_NAME=${1:-"env-agency--flood-monitoring"}

echo -e "${BLUE}🔌 Creating multi-endpoint HTTP Source connector: ${CONNECTOR_NAME}...${NC}"

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

echo -e "${YELLOW}🌐 Base URL: https://environment.data.gov.uk/flood-monitoring${NC}"
echo -e "${YELLOW}📍 Endpoints:${NC}"
echo -e "  ${BLUE}1.${NC} /id/stations → flood-monitoring-stations (1 hour interval)"
echo -e "  ${BLUE}2.${NC} /id/measures → flood-monitoring-measures (1 hour interval)"
echo -e "  ${BLUE}3.${NC} /data/readings?latest → flood-monitoring-readings (15 min interval)"

# Create connector configuration
if [ "$HTTP_CLIENT" = "http" ]; then
    echo -e "${YELLOW}🔧 Creating multi-endpoint connector with httpie...${NC}"
    
    RESPONSE=$(http PUT \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/config" \
        --auth "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        content-type:application/json \
        connector.class="HttpSourceV2" \
        name="" \
        http.api.base.url="https://environment.data.gov.uk/flood-monitoring" \
        apis.num="3" \
        api1.http.api.path="/id/stations" \
        api1.http.offset.mode="SIMPLE_INCREMENTING" \
        api1.http.initial.offset="0" \
        api1.request.interval.ms="3600000" \
        api1.topics="flood-monitoring-stations" \
        api2.http.api.path="/id/measures" \
        api2.http.offset.mode="SIMPLE_INCREMENTING" \
        api2.http.initial.offset="0" \
        api2.request.interval.ms="3600000" \
        api2.topics="flood-monitoring-measures" \
        api3.http.api.path="/data/readings?latest" \
        api3.http.offset.mode="SIMPLE_INCREMENTING" \
        api3.http.initial.offset="0" \
        api3.request.interval.ms="900000" \
        api3.topics="flood-monitoring-readings" \
        kafka.api.key="$CNFL_KC_API_KEY" \
        kafka.api.secret="$CNFL_KC_API_SECRET" \
        output.data.format="AVRO" \
        tasks.max="3" 2>&1)
else
    echo -e "${YELLOW}🔧 Creating multi-endpoint connector with curl...${NC}"
    
    RESPONSE=$(curl -s -X PUT \
        "https://api.confluent.cloud/connect/v1/environments/$CNFL_ENV/clusters/$CNFL_KAFKA_CLUSTER/connectors/$CONNECTOR_NAME/config" \
        --user "$CNFL_CLOUD_API_KEY:$CNFL_CLOUD_API_SECRET" \
        -H "Content-Type: application/json" \
        -d '{
            "connector.class": "HttpSourceV2",
            "name": "",
            "http.api.base.url": "https://environment.data.gov.uk/flood-monitoring",
            "apis.num": "3",
            "api1.http.api.path": "/id/stations",
            "api1.http.offset.mode": "SIMPLE_INCREMENTING",
            "api1.http.initial.offset": "0",
            "api1.request.interval.ms": "3600000",
            "api1.topics": "flood-monitoring-stations",
            "api2.http.api.path": "/id/measures",
            "api2.http.offset.mode": "SIMPLE_INCREMENTING",
            "api2.http.initial.offset": "0",
            "api2.request.interval.ms": "3600000",
            "api2.topics": "flood-monitoring-measures",
            "api3.http.api.path": "/data/readings?latest",
            "api3.http.offset.mode": "SIMPLE_INCREMENTING",
            "api3.http.initial.offset": "0",
            "api3.request.interval.ms": "900000",
            "api3.topics": "flood-monitoring-readings",
            "kafka.api.key": "'$CNFL_KC_API_KEY'",
            "kafka.api.secret": "'$CNFL_KC_API_SECRET'",
            "output.data.format": "AVRO",
            "tasks.max": "3"
        }' 2>&1)
fi

# Check if the request was successful
if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK" || echo "$RESPONSE" | grep -q '"name"'; then
    echo -e "${GREEN}✅ Multi-endpoint connector created successfully!${NC}"
    echo -e "${YELLOW}📝 Connector details:${NC}"
    echo -e "  ${BLUE}Name:${NC} $CONNECTOR_NAME"
    echo -e "  ${BLUE}Type:${NC} HttpSourceV2"
    echo -e "  ${BLUE}Base URL:${NC} https://environment.data.gov.uk/flood-monitoring"
    echo -e "  ${BLUE}APIs:${NC} 3 endpoints"
    echo -e "  ${BLUE}Topics:${NC} flood-monitoring-stations, flood-monitoring-measures, flood-monitoring-readings"
    echo -e "  ${BLUE}Tasks:${NC} 3 (one per endpoint)"
    echo -e "  ${BLUE}Format:${NC} AVRO"
    
    echo -e "${YELLOW}⚠️  Note: If using a basic cluster, you may need to upgrade to standard for multiple tasks${NC}"
else
    echo -e "${RED}❌ Failed to create connector${NC}"
    echo -e "${RED}Response:${NC} $RESPONSE"
    exit 1
fi

echo -e "${GREEN}🎉 Multi-endpoint connector setup complete!${NC}"
echo -e "${YELLOW}💡 Use 'make status' to check connector status${NC}"
