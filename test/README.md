# Load Testing with Locust

This directory contains load testing scripts for the XML-JSON converter service.

## API Endpoint

The converter accepts **POST requests** with XML data in the request body:

```bash
POST /convert
Content-Type: application/xml

<logs>
  <log><id>1</id><level>INFO</level><msg>Test</msg></log>
</logs>
```

Response: JSON data (also saved to S3)

## Prerequisites

Install Python dependencies:

```bash
pip install -r requirements.txt
```

## Quick Test (Single Request)

Before running load tests, verify the endpoint works:

```bash
# Test with sample XML file
./test_single_request.sh http://YOUR-LOADBALANCER-URL.elb.amazonaws.com

# Test with custom XML (20 log entries)
./test_with_custom_xml.sh http://YOUR-LOADBALANCER-URL.elb.amazonaws.com 20
```

## Load Testing

### Option 1: Using the provided script (recommended)

```bash
# Make the script executable
chmod +x run_load_test.sh

# Run with default settings (100 users, 60 seconds)
./run_load_test.sh

# Run against a remote server
./run_load_test.sh http://your-loadbalancer-url.com

# Customize users, spawn rate, and duration
./run_load_test.sh http://localhost:8080 200 50 120s
```

Parameters:
- Host: Server URL (default: http://localhost:8080)
- Users: Number of concurrent users (default: 100)
- Spawn Rate: Users spawned per second (default: 100)
- Run Time: Test duration (default: 60s)

### Option 2: Direct Locust commands

**Send 100 requests simultaneously (headless mode):**

```bash
locust -f locustfile.py \
    --host=http://localhost:8080 \
    --users=100 \
    --spawn-rate=100 \
    --run-time=60s \
    --headless
```

**Launch with Web UI:**

```bash
locust -f locustfile.py --host=http://localhost:8080
```

Then open http://localhost:8089 in your browser to control the test.

## Test Scenarios

### XMLConverterUser (Default)
- Tests POST `/convert` endpoint with XML data in request body
- Sends 100 concurrent requests with XML payloads
- No wait time between requests for maximum load
- Validates JSON response

### XMLConverterUserWithGET (For Local Testing)
- Tests GET `/convert` endpoint (backwards compatibility)
- Uses local test.xml file on the server
- For local development only (won't work on EKS)

## Output

After running the test, you'll get:
- **load_test_report.html**: Detailed HTML report with graphs and statistics
- **load_test_results_stats.csv**: Request statistics
- **load_test_results_failures.csv**: Failed requests (if any)
- **load_test_results_stats_history.csv**: Stats over time

## Key Metrics to Watch

- **Total Requests**: Number of requests completed
- **Failures**: Number of failed requests
- **Average Response Time**: Mean response time in ms
- **RPS (Requests Per Second)**: Throughput
- **P50, P95, P99**: Response time percentiles

## Testing Different Configurations

```bash
# Test with 1 pod
./run_load_test.sh http://your-server 100 100 60s

# Test with 2 pods
# (scale deployment first: kubectl scale deployment xml-json-parser --replicas=2)
./run_load_test.sh http://your-server 100 100 60s

# Test with 4 pods
# (scale deployment first: kubectl scale deployment xml-json-parser --replicas=4)
./run_load_test.sh http://your-server 100 100 60s
```

## Examples

**Quick burst test (100 concurrent users for 30 seconds):**
```bash
./run_load_test.sh http://localhost:8080 100 100 30s
```

**Sustained load test (50 users gradually spawned over 10 seconds, run for 5 minutes):**
```bash
./run_load_test.sh http://localhost:8080 50 5 5m
```

**Stress test (500 users):**
```bash
./run_load_test.sh http://localhost:8080 500 50 120s
```

