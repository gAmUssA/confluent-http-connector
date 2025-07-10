#!/bin/bash

# 🔐 Login to Confluent Cloud
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Logging into Confluent Cloud...${NC}"

# Check if confluent CLI is installed
if ! command -v confluent &> /dev/null; then
    echo -e "${RED}❌ Confluent CLI is not installed. Please install it first.${NC}"
    echo -e "${YELLOW}💡 Install with: curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest${NC}"
    exit 1
fi

# Login to Confluent Cloud
echo -e "${YELLOW}🔑 Please complete the login process in your browser...${NC}"
confluent login --save

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully logged into Confluent Cloud${NC}"
else
    echo -e "${RED}❌ Failed to login to Confluent Cloud${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Login complete!${NC}"
