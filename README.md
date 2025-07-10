# 🌊 Confluent Cloud HTTP Source Connector Automation + Tableflow (feat. Trino)

![Confluent Cloud](https://img.shields.io/badge/Confluent%20Cloud-0066CC?style=for-the-badge&logo=apache-kafka&logoColor=white)
![Apache Kafka](https://img.shields.io/badge/Apache%20Kafka-231F20?style=for-the-badge&logo=apache-kafka&logoColor=white)
![Trino](https://img.shields.io/badge/Trino-DD00A1?style=for-the-badge&logo=trino&logoColor=white)
![Apache Iceberg](https://img.shields.io/badge/Apache%20Iceberg-326CE5?style=for-the-badge&logo=apache&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell%20Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Make](https://img.shields.io/badge/Make-427819?style=for-the-badge&logo=cmake&logoColor=white)
![HTTPie](https://img.shields.io/badge/HTTPie-73DC8C?style=for-the-badge&logo=http&logoColor=white)
![JSON](https://img.shields.io/badge/JSON-000000?style=for-the-badge&logo=json&logoColor=white)

This project automates the complete setup and management of HTTP Source connectors on Confluent Cloud using Makefile and shell scripts. It's based on the excellent guides by [Robin Moffatt](https://rmoff.net/).
[\[1\]](https://rmoff.net/2025/03/13/creating-an-http-source-connector-on-confluent-cloud-from-the-cli/) [\[2\]](https://www.confluent.io/blog/building-streaming-data-pipelines-part-1/)

## 🚀 Features

- **🔐 Complete Authentication Setup**: Automated login and API key management
- **🏗️ Infrastructure Creation**: Environment and Kafka cluster setup
- **🔌 Connector Management**: Create, monitor, and delete HTTP Source connectors
- **📊 Data Inspection**: Check connector status and inspect Kafka topic data
- **🔍 SQL Analytics**: Trino integration with Iceberg catalog for querying streaming data
- **🧹 Resource Cleanup**: Complete teardown of all created resources
- **🎨 User-Friendly Output**: Colorized output with emojis for better readability
- **🛠️ Multiple Tool Support**: Works with HTTPie, cURL, kcat, Confluent CLI, and Docker

## 📋 Prerequisites

### Required Tools
- **Confluent CLI**: [Installation Guide](https://docs.confluent.io/confluent-cli/current/install.html)
- **HTTPie** or **cURL**: For API requests
- **jq**: For JSON parsing (recommended)
- **kcat**: For Kafka topic inspection (recommended)
- **Docker**: For Trino analytics server (optional)

### Installation Commands (macOS)
```bash
# Install Confluent CLI
curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest

# Install optional tools
brew install httpie jq kcat docker
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

## 🔍 Trino Analytics

This project includes Trino integration for SQL-based analytics on your streaming data using Iceberg catalog and Confluent Cloud.

### 🏗️ Setup

1. **Configure Iceberg Catalog**:
   Create `catalog/tableflow.properties` with your Confluent Cloud credentials:
   ```properties
   connector.name=iceberg
   iceberg.catalog.type=rest
   iceberg.rest-catalog.oauth2.credential=YOUR_API_KEY:YOUR_API_SECRET
   iceberg.rest-catalog.security=OAUTH2
   iceberg.rest-catalog.uri=https://tableflow.us-west-2.aws.confluent.cloud/iceberg/catalog/organizations/YOUR_ORG_ID/environments/YOUR_ENV_ID
   iceberg.rest-catalog.vended-credentials-enabled=true
   
   fs.native-s3.enabled=true
   s3.region=us-west-2
   ```

2. **Start Trino Server**:
   ```bash
   make start-trino    # Starts Trino in background
   make trino-logs     # Monitor startup progress
   ```

3. **Access Trino**:
   - **Web UI**: http://localhost:8080
   - **CLI**: `docker exec -it trino trino`
   - **JDBC**: `jdbc:trino://localhost:8080/tableflow`

### 🚀 Usage

#### Start/Stop Trino
```bash
make start-trino    # Start Trino server (non-blocking)
make stop-trino     # Stop Trino server
make trino-logs     # View server logs
```

#### Connect and Query
```bash
# Connect via Docker CLI
docker exec -it trino trino --catalog tableflow

# Or use any SQL client with JDBC:
# jdbc:trino://localhost:8080/tableflow
```

### 📊 SQL Examples

Once your HTTP connectors are running and data is flowing:

#### List Available Schemas
```sql
SHOW SCHEMAS IN tableflow;
```

#### Explore Tables
```sql
-- List tables in your environment (replace lkc-xxxxx with your cluster ID)
SHOW TABLES IN "tableflow"."lkc-xxxxx";

-- Describe table structure
DESCRIBE "tableflow"."lkc-xxxxx"."flood-monitoring-measures";
DESCRIBE "tableflow"."lkc-xxxxx"."flood-monitoring-stations";
DESCRIBE "tableflow"."lkc-xxxxx"."flood-monitoring-readings";
```

#### Query Streaming Data
```sql
-- Query recent flood monitoring readings (unnest the items array)
SELECT 
    u.measure,
    u.value,
    u.dateTime
FROM "tableflow"."lkc-xxxxx"."flood-monitoring-readings" t
CROSS JOIN UNNEST(t.items) AS u
WHERE u.dateTime >= current_timestamp - INTERVAL '1' HOUR
ORDER BY u.dateTime DESC
LIMIT 100;
```

#### Analytical Queries
```sql
-- Denormalized view with readings, measures, and stations
WITH readings AS (
    SELECT u.*
    FROM "tableflow"."lkc-xxxxx"."flood-monitoring-readings" t
    CROSS JOIN UNNEST(t.items) AS u
),
measures AS (
    SELECT DISTINCT u._40id, u.label, u.parameterName, u.unitName, u.station
    FROM "tableflow"."lkc-xxxxx"."flood-monitoring-measures" t
    CROSS JOIN UNNEST(t.items) AS u
),
stations AS (
    SELECT DISTINCT u._40id, u.catchmentName, u.label as station_label, u.riverName
    FROM "tableflow"."lkc-xxxxx"."flood-monitoring-stations" t
    CROSS JOIN UNNEST(t.items) AS u
)
SELECT 
    s.station_label,
    s.riverName,
    m.label as measure_label,
    m.parameterName,
    AVG(CAST(r.value AS DOUBLE)) as avg_value,
    COUNT(*) as reading_count
FROM readings r
LEFT JOIN measures m ON r.measure = m._40id
LEFT JOIN stations s ON m.station = s._40id
WHERE r.dateTime >= current_date - INTERVAL '7' DAY
GROUP BY s.station_label, s.riverName, m.label, m.parameterName
ORDER BY avg_value DESC
LIMIT 20;

-- Time series analysis for a specific measure
WITH readings AS (
    SELECT u.*
    FROM "tableflow"."lkc-xxxxx"."flood-monitoring-readings" t
    CROSS JOIN UNNEST(t.items) AS u
)
SELECT 
    date_trunc('hour', r.dateTime) as hour,
    AVG(CAST(r.value AS DOUBLE)) as avg_value,
    MIN(CAST(r.value AS DOUBLE)) as min_value,
    MAX(CAST(r.value AS DOUBLE)) as max_value,
    COUNT(*) as reading_count
FROM readings r
WHERE r.measure = 'http://environment.data.gov.uk/flood-monitoring/id/measures/YOUR-MEASURE-ID'
    AND r.dateTime >= current_date - INTERVAL '1' DAY
GROUP BY date_trunc('hour', r.dateTime)
ORDER BY hour;
```

### 🔧 Configuration

#### Custom Catalog Properties
Modify `catalog/tableflow.properties` to:
- Change regions or cloud providers
- Add authentication credentials
- Configure S3 settings
- Enable additional features

#### Docker Configuration
The Trino container:
- **Port**: 8080 (configurable in Makefile)
- **Catalog Mount**: `./catalog:/etc/trino/catalog`
- **Image**: `trinodb/trino:latest`
- **Mode**: Detached with background readiness check

### 🎯 Integration Benefits

- **Real-time Analytics**: Query streaming data as it arrives
- **SQL Interface**: Use familiar SQL syntax on streaming data
- **Scalable**: Trino handles large datasets efficiently
- **Iceberg Format**: ACID transactions and schema evolution
- **Cloud Native**: Integrates seamlessly with Confluent Cloud

### 💡 Tips

1. **Monitor Data Flow**: Use `make check-data` to verify data is flowing before querying
2. **Check Connector Status**: Use `make status` to ensure connectors are healthy
3. **Schema Discovery**: Tables appear automatically as connectors create topics
4. **Performance**: Use appropriate WHERE clauses for time-based filtering
5. **Debugging**: Use `make trino-logs` to troubleshoot connection issues

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
