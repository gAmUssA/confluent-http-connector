#!/bin/bash

# ✅ Validate environment setup
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}✅ Validating environment setup...${NC}"

VALIDATION_PASSED=true

# Function to check if a command exists
check_command() {
    local cmd=$1
    local description=$2
    local required=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✅ $description: Found${NC}"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $description: Not found (REQUIRED)${NC}"
            VALIDATION_PASSED=false
        else
            echo -e "${YELLOW}⚠️  $description: Not found (optional)${NC}"
        fi
        return 1
    fi
}

# Function to check environment variable
check_env_var() {
    local var_name=$1
    local description=$2
    local required=$3
    
    if [ -n "${!var_name}" ]; then
        echo -e "${GREEN}✅ $description: Set${NC}"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $description: Not set (REQUIRED)${NC}"
            VALIDATION_PASSED=false
        else
            echo -e "${YELLOW}⚠️  $description: Not set (optional)${NC}"
        fi
        return 1
    fi
}

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🔧 Checking required tools...${NC}"

# Check required tools
check_command "confluent" "Confluent CLI" "true"

# Check optional tools
check_command "http" "HTTPie" "false"
check_command "curl" "cURL" "false"
check_command "jq" "jq (JSON processor)" "false"
check_command "kcat" "kcat (Kafka CLI)" "false"
check_command "kafkacat" "kafkacat (legacy)" "false"

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📁 Checking configuration files...${NC}"

# Check if .env file exists
if [ -f .env ]; then
    echo -e "${GREEN}✅ .env file: Found${NC}"
    
    # Source the .env file
    source .env
    
    echo -e "${YELLOW}🔍 Checking environment variables...${NC}"
    
    # Check required environment variables
    check_env_var "CNFL_ENV" "Confluent Environment ID" "true"
    check_env_var "CNFL_KAFKA_CLUSTER" "Kafka Cluster ID" "true"
    check_env_var "CNFL_KAFKA_BROKER" "Kafka Broker" "true"
    check_env_var "CNFL_SR_ID" "Schema Registry ID" "true"
    check_env_var "CNFL_SR_HOST" "Schema Registry Host" "true"
    check_env_var "CNFL_KC_API_KEY" "Kafka API Key" "true"
    check_env_var "CNFL_KC_API_SECRET" "Kafka API Secret" "true"
    check_env_var "CNFL_CLOUD_API_KEY" "Cloud API Key" "true"
    check_env_var "CNFL_CLOUD_API_SECRET" "Cloud API Secret" "true"
    check_env_var "CNFL_SR_API_KEY" "Schema Registry API Key" "true"
    check_env_var "CNFL_SR_API_SECRET" "Schema Registry API Secret" "true"
    
else
    echo -e "${RED}❌ .env file: Not found (REQUIRED)${NC}"
    VALIDATION_PASSED=false
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🔐 Testing Confluent Cloud connectivity...${NC}"

if [ "$VALIDATION_PASSED" = true ] && command -v confluent &> /dev/null; then
    # Test Confluent CLI connectivity
    echo -e "${YELLOW}🔍 Testing Confluent CLI authentication...${NC}"
    
    AUTH_TEST=$(confluent environment list 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Confluent CLI: Authenticated${NC}"
        
        # Check if current environment is set
        CURRENT_ENV=$(confluent environment list | grep "*" | awk '{print $2}')
        if [ -n "$CURRENT_ENV" ]; then
            echo -e "${GREEN}✅ Active environment: $CURRENT_ENV${NC}"
            
            if [ "$CURRENT_ENV" = "$CNFL_ENV" ]; then
                echo -e "${GREEN}✅ Environment matches .env file${NC}"
            else
                echo -e "${YELLOW}⚠️  Active environment differs from .env file${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No active environment set${NC}"
        fi
        
        # Check if current cluster is set
        CURRENT_CLUSTER=$(confluent kafka cluster list 2>/dev/null | grep "*" | awk '{print $2}')
        if [ -n "$CURRENT_CLUSTER" ]; then
            echo -e "${GREEN}✅ Active cluster: $CURRENT_CLUSTER${NC}"
            
            if [ "$CURRENT_CLUSTER" = "$CNFL_KAFKA_CLUSTER" ]; then
                echo -e "${GREEN}✅ Cluster matches .env file${NC}"
            else
                echo -e "${YELLOW}⚠️  Active cluster differs from .env file${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No active cluster set${NC}"
        fi
        
    else
        echo -e "${RED}❌ Confluent CLI: Authentication failed${NC}"
        echo -e "${YELLOW}Error: $AUTH_TEST${NC}"
        VALIDATION_PASSED=false
    fi
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Validation Summary${NC}"

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}🎉 Environment validation PASSED!${NC}"
    echo -e "${GREEN}✅ All required components are properly configured${NC}"
    echo -e "${YELLOW}💡 You can now run: make all${NC}"
else
    echo -e "${RED}❌ Environment validation FAILED!${NC}"
    echo -e "${RED}⚠️  Please fix the issues above before proceeding${NC}"
    echo -e "${YELLOW}💡 Run: make setup (to complete initial setup)${NC}"
fi

echo -e "${PURPLE}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}🛠️  Recommended tools to install:${NC}"
echo -e "${BLUE}• HTTPie:${NC} brew install httpie"
echo -e "${BLUE}• jq:${NC} brew install jq"
echo -e "${BLUE}• kcat:${NC} brew install kcat"

exit $([ "$VALIDATION_PASSED" = true ] && echo 0 || echo 1)
