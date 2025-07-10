# 🌊 Confluent Cloud HTTP Source Connector Automation

This project automates the complete setup and management of HTTP Source connectors on Confluent Cloud using Makefile and shell scripts. It's based on the excellent guide by [Robin Moffatt](https://rmoff.net/2025/03/13/creating-an-http-source-connector-on-confluent-cloud-from-the-cli/).

## 🚀 Features

- **🔐 Complete Authentication Setup**: Automated login and API key management
- **🏗️ Infrastructure Creation**: Environment and Kafka cluster setup
- **🔌 Connector Management**: Create, monitor, and delete HTTP Source connectors
- **📊 Data Inspection**: Check connector status and inspect Kafka topic data
- **🧹 Resource Cleanup**: Complete teardown of all created resources
- **🎨 User-Friendly Output**: Colorized output with emojis for better readability
- **🛠️ Multiple Tool Support**: Works with HTTPie, cURL, kcat, and Confluent CLI

## 📋 Prerequisites

### Required Tools
- **Confluent CLI**: [Installation Guide](https://docs.confluent.io/confluent-cli/current/install.html)
- **HTTPie** or **cURL**: For API requests
- **jq**: For JSON parsing (recommended)
- **kcat**: For Kafka topic inspection (recommended)

### Installation Commands (macOS)
```bash
# Install Confluent CLI
curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest

# Install optional tools
brew install httpie jq kcat
```

## 🏁 Quick Start

1. **Clone and Setup**:
   ```bash
   git clone <your-repo>
   cd confluent-http-connector
   ```

2. **Run Complete Setup**:
   ```bash
   make all
   ```

3. **Or Step-by-Step**:
   ```bash
   make setup           # Login + create environment + cluster + API keys
   make create-single   # Create single-endpoint connector
   make status          # Check connector status
   make check-data      # Inspect topic data
   ```

## 🎯 Makefile Targets

### 🔧 Setup Commands
| Target | Description |
|--------|-------------|
| `make all` | Complete setup: login → environment → cluster → API keys → connector |
| `make setup` | Setup infrastructure: login → environment → cluster → API keys |
| `make login` | Login to Confluent Cloud |
| `make create-env` | Create and activate environment |
| `make create-cluster` | Create Kafka cluster and Schema Registry |
| `make create-api-keys` | Generate all required API keys |

### 🔌 Connector Commands
| Target | Description |
|--------|-------------|
| `make create-single` | Create HTTP connector for single endpoint |
| `make create-multi` | Create HTTP connector for multiple endpoints |
| `make status` | Check connector status |
| `make list-connectors` | List all connectors |
| `make delete-connector` | Delete a connector |

### 📊 Data Commands
| Target | Description |
|--------|-------------|
| `make check-data` | Inspect Kafka topic data |
| `make validate-env` | Validate environment setup |

### 🧹 Cleanup Commands
| Target | Description |
|--------|-------------|
| `make clean` | Complete cleanup of all resources |

## 📁 Project Structure

```
confluent-http-connector/
├── Makefile                           # Main orchestration
├── README.md                          # This file
├── .env                              # Environment variables (auto-generated)
└── scripts/
    ├── login.sh                      # Confluent Cloud login
    ├── create-environment.sh         # Environment creation
    ├── create-cluster.sh             # Kafka cluster setup
    ├── create-api-keys.sh            # API key generation
    ├── create-single-connector.sh    # Single endpoint connector
    ├── create-multi-connector.sh     # Multi-endpoint connector
    ├── check-status.sh               # Connector status checking
    ├── check-data.sh                 # Topic data inspection
    ├── delete-connector.sh           # Connector deletion
    ├── list-connectors.sh            # List all connectors
    ├── validate-env.sh               # Environment validation
    └── cleanup.sh                    # Resource cleanup
```

## 🔐 Environment Variables

The automation creates a `.env` file with the following variables:

```bash
# Confluent Cloud Resources
CNFL_ENV=env-xxxxx                    # Environment ID
CNFL_KAFKA_CLUSTER=lkc-xxxxx          # Kafka cluster ID
CNFL_KAFKA_BROKER=pkc-xxxxx.region.provider.confluent.cloud:9092
CNFL_SR_ID=lsrc-xxxxx                 # Schema Registry ID
CNFL_SR_HOST=psrc-xxxxx.region.provider.confluent.cloud

# API Keys
CNFL_KC_API_KEY=xxxxx                 # Kafka cluster API key
CNFL_KC_API_SECRET=xxxxx              # Kafka cluster API secret
CNFL_CLOUD_API_KEY=xxxxx              # Cloud resource API key
CNFL_CLOUD_API_SECRET=xxxxx           # Cloud resource API secret
CNFL_SR_API_KEY=xxxxx                 # Schema Registry API key
CNFL_SR_API_SECRET=xxxxx              # Schema Registry API secret

# Connector Configuration
CONNECTOR_NAME=env-agency--flood-monitoring
```

## 🌊 Example: UK Flood Monitoring

The default configuration creates a connector that monitors UK flood data:

### Single Endpoint Connector
- **Endpoint**: `https://environment.data.gov.uk/flood-monitoring/id/stations`
- **Topic**: `flood-monitoring-stations`
- **Polling**: Every 60 seconds

### Multi-Endpoint Connector
- **Stations**: `flood-monitoring-stations`
- **Measures**: `flood-monitoring-measures`  
- **Readings**: `flood-monitoring-readings`

## 🔍 Monitoring and Troubleshooting

### Check Connector Status
```bash
make status
# or
./scripts/check-status.sh [connector-name]
```

### Inspect Topic Data
```bash
make check-data
# Uses kcat to inspect messages in flood monitoring topics
```

### Validate Environment
```bash
make validate-env
# Checks all tools, credentials, and connectivity
```

### List All Connectors
```bash
make list-connectors
# Shows all connectors with their status
```

## 🛠️ Customization

### Custom API Endpoints
Edit the connector creation scripts to use different endpoints:

```bash
# In create-single-connector.sh or create-multi-connector.sh
# Modify the JSON configuration:
"http.url": "https://your-api-endpoint.com/data"
```

### Custom Polling Intervals
```bash
# Change polling frequency (in milliseconds)
"http.request.interval.ms": "30000"  # 30 seconds
```

### Custom Topic Names
```bash
# Modify topic prefix
"kafka.topic": "your-custom-topic-name"
```

## 🧹 Cleanup

⚠️ **Warning**: Cleanup will delete ALL resources created by this automation.

```bash
make clean
# This will delete:
# - All connectors
# - API keys
# - Kafka cluster
# - Environment
# - Local .env file
```

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Failed**
   ```bash
   make validate-env  # Check credentials
   make login         # Re-authenticate
   ```

2. **Connector Creation Failed**
   ```bash
   make status        # Check connector status
   make list-connectors  # List existing connectors
   ```

3. **No Data in Topics**
   ```bash
   make check-data    # Inspect topics
   make status        # Check if connector is running
   ```

4. **Missing Tools**
   ```bash
   brew install httpie jq kcat  # Install optional tools
   ```

### Debug Mode
Add `set -x` to any script for verbose debugging:
```bash
# Edit any script and add at the top:
set -x  # Enable debug mode
```

## 📚 References

- [Original Guide by Robin Moffatt](https://rmoff.net/2025/03/13/creating-an-http-source-connector-on-confluent-cloud-from-the-cli/)
- [Confluent Cloud Documentation](https://docs.confluent.io/cloud/current/overview.html)
- [HTTP Source Connector Documentation](https://docs.confluent.io/kafka-connectors/http/current/overview.html)
- [UK Environment Agency API](https://environment.data.gov.uk/flood-monitoring/doc/reference)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Streaming! 🌊**
