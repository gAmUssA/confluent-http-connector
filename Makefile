# 🌊 Confluent Cloud HTTP Source Connector Automation
# Based on: https://rmoff.net/2025/03/13/creating-an-http-source-connector-on-confluent-cloud-from-the-cli/

# Colors for better readability
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m
BOLD = \033[1m
NC = \033[0m # No Color

# Default values (can be overridden)
ENV_NAME ?= rmoff-demo
CLUSTER_NAME ?= cluster00
CLOUD_PROVIDER ?= aws
REGION ?= us-west-2
CONNECTOR_NAME ?= env-agency--flood-monitoring

.PHONY: help setup login create-env create-cluster create-api-keys setup-vars create-single-connector create-multi-connector status check-data delete-connector clean all

help: ## 📋 Show this help message
	@echo "$(BOLD)$(CYAN)🌊 Confluent Cloud HTTP Source Connector Automation$(NC)"
	@echo "$(YELLOW)Based on: https://rmoff.net/2025/03/13/creating-an-http-source-connector-on-confluent-cloud-from-the-cli/$(NC)"
	@echo ""
	@echo "$(BOLD)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BOLD)Environment Variables:$(NC)"
	@echo "  $(YELLOW)ENV_NAME$(NC)        = $(ENV_NAME)"
	@echo "  $(YELLOW)CLUSTER_NAME$(NC)    = $(CLUSTER_NAME)"
	@echo "  $(YELLOW)CLOUD_PROVIDER$(NC)  = $(CLOUD_PROVIDER)"
	@echo "  $(YELLOW)REGION$(NC)          = $(REGION)"
	@echo "  $(YELLOW)CONNECTOR_NAME$(NC)  = $(CONNECTOR_NAME)"

all: setup create-single-connector status ## 🚀 Run complete setup with single endpoint connector

setup: login create-env create-cluster create-api-keys setup-vars ## ⚙️  Complete initial setup

login: ## 🔐 Login to Confluent Cloud
	@echo "$(BOLD)$(BLUE)🔐 Logging into Confluent Cloud...$(NC)"
	@./scripts/login.sh

create-env: ## 🌍 Create and activate environment
	@echo "$(BOLD)$(GREEN)🌍 Creating environment: $(ENV_NAME)...$(NC)"
	@./scripts/create-environment.sh $(ENV_NAME)

create-cluster: ## ☁️  Create and activate Kafka cluster
	@echo "$(BOLD)$(PURPLE)☁️  Creating Kafka cluster: $(CLUSTER_NAME)...$(NC)"
	@./scripts/create-cluster.sh $(CLUSTER_NAME) $(CLOUD_PROVIDER) $(REGION)

create-api-keys: ## 🔑 Create all required API keys
	@echo "$(BOLD)$(YELLOW)🔑 Creating API keys...$(NC)"
	@./scripts/create-api-keys.sh

setup-vars: ## 📝 Export environment variables
	@echo "$(BOLD)$(CYAN)📝 Setting up environment variables...$(NC)"
	@echo "$(GREEN)✅ Environment variables are set in .env file$(NC)"
	@echo "$(YELLOW)⚠️  Run: source .env$(NC)"

create-single-connector: ## 🔌 Create HTTP Source connector (single endpoint)
	@echo "$(BOLD)$(GREEN)🔌 Creating single endpoint HTTP Source connector...$(NC)"
	@./scripts/create-single-connector.sh $(CONNECTOR_NAME)

create-multi-connector: ## 🔌 Create HTTP Source connector (multiple endpoints)
	@echo "$(BOLD)$(GREEN)🔌 Creating multi-endpoint HTTP Source connector...$(NC)"
	@./scripts/create-multi-connector.sh $(CONNECTOR_NAME)

status: ## 📊 Check connector status
	@echo "$(BOLD)$(BLUE)📊 Checking connector status...$(NC)"
	@./scripts/check-status.sh $(CONNECTOR_NAME)

check-data: ## 📋 Inspect data in Kafka topics
	@echo "$(BOLD)$(CYAN)📋 Checking data in topics...$(NC)"
	@./scripts/check-data.sh

delete-connector: ## 🗑️  Delete the connector
	@echo "$(BOLD)$(RED)🗑️  Deleting connector: $(CONNECTOR_NAME)...$(NC)"
	@./scripts/delete-connector.sh $(CONNECTOR_NAME)

clean: ## 🧹 Clean up all resources
	@echo "$(BOLD)$(RED)🧹 Cleaning up resources...$(NC)"
	@./scripts/cleanup.sh

validate-env: ## ✅ Validate environment setup
	@echo "$(BOLD)$(YELLOW)✅ Validating environment...$(NC)"
	@./scripts/validate-env.sh

list-connectors: ## 📋 List all connectors
	@echo "$(BOLD)$(CYAN)📋 Listing all connectors...$(NC)"
	@./scripts/list-connectors.sh

# Development targets
dev-setup: ## 🛠️  Setup for development (creates scripts directory)
	@mkdir -p scripts
	@chmod +x scripts/*.sh 2>/dev/null || true
	@echo "$(GREEN)✅ Development setup complete$(NC)"
