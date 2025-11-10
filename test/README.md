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

Before running load tests, verify the endpoint works with a simple curl:

```bash
curl -X POST \
  -H "Content-Type: application/xml" \
  -d '<logs><log><id>1</id><level>INFO</level><msg>Test</msg></log></logs>' \
  http://YOUR-LOADBALANCER-URL.elb.amazonaws.com/convert
```

Expected response: `{"logs":{"log":{"id":"1","level":"INFO","msg":"Test"}}}`

## Running Load Tests

```bash
# Make the script executable (first time only)
chmod +x run_load_test.sh

# Run with default settings (100 users, 60 seconds)
./run_load_test.sh http://YOUR-LOADBALANCER-URL

# Customize users, spawn rate, and duration
./run_load_test.sh http://YOUR-LOADBALANCER-URL 200 50 120s
```

**Parameters:**
- **Host**: Server URL (required)
- **Users**: Number of concurrent users (default: 100)
- **Spawn Rate**: Users spawned per second (default: 100)
- **Run Time**: Test duration (default: 60s)

## Test Scenario

The load test sends POST requests to `/convert` with XML data:
- Concurrent requests with XML payloads
- No wait time between requests for maximum load
- Validates JSON response
- Configurable number of users and spawn rate

## Output

After running the test, you'll get:
- **load_test_report.html**: Detailed HTML report with graphs and statistics
- Console output showing real-time progress and final summary

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

## Example Test Scenarios

**Quick burst test (100 concurrent users for 30 seconds):**
```bash
./run_load_test.sh http://YOUR-LOADBALANCER-URL 100 100 30s
```

**Sustained load test (50 users gradually spawned, run for 5 minutes):**
```bash
./run_load_test.sh http://YOUR-LOADBALANCER-URL 50 10 5m
```

**Stress test (500 users):**
```bash
./run_load_test.sh http://YOUR-LOADBALANCER-URL 500 50 120s
```

## Getting LoadBalancer URL

From your terraform directory:

```bash
cd ../terraform
terraform output load_balancer_dns
```

Or using kubectl:

```bash
kubectl get svc xml-json-parser-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

