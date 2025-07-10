#!/bin/bash

# 📋 Inspect data in Kafka topics
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Checking data in Kafka topics...${NC}"

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ .env file not found. Please run setup first.${NC}"
    exit 1
fi

# Check required environment variables
required_vars=("CNFL_KAFKA_BROKER" "CNFL_KC_API_KEY" "CNFL_KC_API_SECRET" "CNFL_SR_HOST" "CNFL_SR_API_KEY" "CNFL_SR_API_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var not set${NC}"
        exit 1
    fi
done

# Check available tools
HAS_KCAT=false
HAS_JQ=false

if command -v kcat &> /dev/null; then
    HAS_KCAT=true
    echo -e "${GREEN}✅ kcat found${NC}"
elif command -v kafkacat &> /dev/null; then
    HAS_KCAT=true
    KCAT_CMD="kafkacat"
    echo -e "${GREEN}✅ kafkacat found${NC}"
else
    echo -e "${YELLOW}⚠️  kcat/kafkacat not found, will use Confluent CLI only${NC}"
fi

if command -v jq &> /dev/null; then
    HAS_JQ=true
    echo -e "${GREEN}✅ jq found${NC}"
else
    echo -e "${YELLOW}⚠️  jq not found, JSON output will be raw${NC}"
fi

# Set kcat command
KCAT_CMD=${KCAT_CMD:-"kcat"}

# List topics using Confluent CLI
echo -e "${YELLOW}📋 Listing topics...${NC}"
if command -v confluent &> /dev/null; then
    TOPIC_LIST=$(confluent kafka topic list 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Available topics:${NC}"
        echo "$TOPIC_LIST"
        echo -e "${PURPLE}═══════════════════════════════════════${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not list topics via CLI${NC}"
    fi
fi

# Define topics to check
TOPICS=("flood-monitoring-stations" "flood-monitoring-measures" "flood-monitoring-readings")

# Function to check topic data with kcat
check_topic_with_kcat() {
    local topic=$1
    local description=$2
    
    echo -e "${BLUE}🔍 Checking topic: ${topic}${NC}"
    echo -e "${YELLOW}📝 Description: ${description}${NC}"
    
    # Check if topic exists and has data
    echo -e "${YELLOW}📊 Getting message count...${NC}"
    
    if [ "$HAS_KCAT" = true ]; then
        # Get one message to check if topic has data
        MESSAGE=$($KCAT_CMD -b "$CNFL_KAFKA_BROKER" \
            -X security.protocol=sasl_ssl -X sasl.mechanisms=PLAIN \
            -X sasl.username="$CNFL_KC_API_KEY" -X sasl.password="$CNFL_KC_API_SECRET" \
            -s avro -r "https://$CNFL_SR_API_KEY:$CNFL_SR_API_SECRET@$CNFL_SR_HOST" \
            -C -t "$topic" -c1 -q 2>/dev/null)
        
        if [ -n "$MESSAGE" ]; then
            echo -e "${GREEN}✅ Topic has data${NC}"
            
            # Get message size
            MESSAGE_SIZE=$(echo "$MESSAGE" | wc -c)
            echo -e "${YELLOW}📏 Sample message size: ${MESSAGE_SIZE} bytes${NC}"
            
            # Try to parse JSON structure if jq is available
            if [ "$HAS_JQ" = true ]; then
                echo -e "${YELLOW}🔧 Sample message structure:${NC}"
                KEYS=$(echo "$MESSAGE" | jq -r 'keys[]' 2>/dev/null | head -5)
                if [ -n "$KEYS" ]; then
                    echo "$KEYS" | while read -r key; do
                        echo -e "  ${BLUE}•${NC} $key"
                    done
                    
                    # Show a sample item if it's an array
                    if echo "$MESSAGE" | jq -e '.items[0]' >/dev/null 2>&1; then
                        echo -e "${YELLOW}📋 Sample item keys:${NC}"
                        ITEM_KEYS=$(echo "$MESSAGE" | jq -r '.items[0] | keys[]' 2>/dev/null | head -5)
                        if [ -n "$ITEM_KEYS" ]; then
                            echo "$ITEM_KEYS" | while read -r key; do
                                echo -e "    ${PURPLE}•${NC} $key"
                            done
                        fi
                    fi
                else
                    echo -e "${YELLOW}⚠️  Could not parse JSON structure${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  No data found in topic (may be empty or connector not running)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  kcat not available, cannot check topic data${NC}"
    fi
    
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
}

# Check each topic
echo -e "${YELLOW}🔍 Checking flood monitoring topics...${NC}"

check_topic_with_kcat "flood-monitoring-stations" "UK flood monitoring stations data"
check_topic_with_kcat "flood-monitoring-measures" "UK flood monitoring measures data"
check_topic_with_kcat "flood-monitoring-readings" "UK flood monitoring readings data (latest)"

# Alternative: List topics with kcat if available
if [ "$HAS_KCAT" = true ]; then
    echo -e "${YELLOW}🔧 Alternative: Listing topics with kcat...${NC}"
    KCAT_TOPICS=$($KCAT_CMD -b "$CNFL_KAFKA_BROKER" \
        -X security.protocol=sasl_ssl -X sasl.mechanisms=PLAIN \
        -X sasl.username="$CNFL_KC_API_KEY" -X sasl.password="$CNFL_KC_API_SECRET" \
        -L 2>/dev/null | grep "topic " | awk '{print $2}' | grep -E "flood-monitoring|error")
    
    if [ -n "$KCAT_TOPICS" ]; then
        echo -e "${GREEN}✅ Topics found via kcat:${NC}"
        echo "$KCAT_TOPICS" | while read -r topic; do
            if echo "$topic" | grep -q "error"; then
                echo -e "  ${RED}• $topic${NC}"
            else
                echo -e "  ${GREEN}• $topic${NC}"
            fi
        done
    fi
fi

echo -e "${GREEN}🎉 Data check complete!${NC}"
echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "  ${BLUE}•${NC} Use 'make status' to check connector health"
echo -e "  ${BLUE}•${NC} Install kcat for better topic inspection: brew install kcat"
echo -e "  ${BLUE}•${NC} Install jq for JSON parsing: brew install jq"
