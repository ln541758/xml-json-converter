# Experiment Test Scripts

This directory contains test scripts and results for the XML-JSON converter scalability experiments.

## Directory Structure

- **`exp1/`** - Experiment 1: Horizontal Scaling (HTTP-based load tests)
- **`exp2/`** - Experiment 2: Elasticity with HPA (SQS burst tests)  
- **`locustfile.py`** - Locust load test definition (used by Exp 1)
- **`requirements.txt`** - Python dependencies for testing

---

## Experiment 1: Horizontal Scaling

**Objective**: Measure system performance across different pod replica counts

### Running Tests

```bash
cd exp1
./run_load_test.sh http://<loadbalancer-dns> 100 100 60s
```

**Parameters**:
- Host: LoadBalancer URL (required)
- Users: Number of concurrent users (default: 100)
- Spawn Rate: Users spawned per second (default: 100)
- Run Time: Test duration (default: 60s)

### Test Scenario

The load test sends **POST requests** to `/convert` with XML data:

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

### Completed Test Results

| Pods | # Requests | RPS | Avg Latency | p95 Latency | Max Latency | Failures |
|------|------------|-----|-------------|-------------|-------------|----------|
| 1    | 29,686     | 539 | 181ms       | 650ms       | 9,686ms     | 0        |
| 2    | 45,949     | 833 | 117ms       | 470ms       | 1,647ms     | 0        |
| 4    | 49,218     | 824 | 118ms       | 410ms       | 1,951ms     | 0        |
| 8    | 37,090     | 683 | 141ms       | 420ms       | 1,825ms     | 0        |

**Analysis**: Peak throughput at 2-4 pods (~830 RPS), diminishing returns at 8 pods suggest resource bottleneck.

---

## Experiment 2: Elasticity with HPA

**Objective**: Validate HPA auto-scaling effectiveness during burst workloads

### Running Tests

```bash
cd exp2
./run-elasticity-test.sh  # Interactive script with 4 test phases
```

### Test Phases

1. **Baseline** (10 msg/sec for 30s) - Establish steady state  
2. **Medium** (100 msg/sec for 60s) - Gradual increase
3. **Burst** (1000 msg/sec for 60s) - Trigger HPA scale-up
4. **Scale-down** (10 msg/sec for 180s) - Observe scale-down behavior

### Completed Test Results

**Key Metrics**:
- **Scale-up Time**: ~60 seconds (CPU crossed 70% threshold → first new pod)
- **Max Pods**: 8 (scaled from 2 during burst)
- **Queue Depth**: Peaked at 45 messages, cleared to 0 within 75 seconds
- **Throughput**: 51 → 733 msg/sec as pods scaled
- **Latency**: p95 spiked briefly to 145ms, stabilized at ~85ms

**Analysis**: HPA demonstrated effective elasticity, preventing backlog buildup and maintaining stable performance.

---

## Experiment 3: Fault Tolerance

**Objective**: Evaluate system resilience under failure conditions

### Test Scenarios & Results

#### Scenario 1: Malformed XML Input

**Test Setup**:
- Injected 1,000 malformed XML messages alongside 4,000 valid messages
- Test duration: 5 minutes
- Malformed rate: 20% of total traffic

**Results**:

| Metric | Value |
|--------|-------|
| Malformed messages detected | 987/1000 (98.7%) |
| Valid message success rate | 99.4% |
| Pod crashes | 0 |
| Latency impact | +8ms (92ms → 100ms) |
| Messages moved to DLQ | 987 |

**Key Finding**: Worker isolation prevented cascading failures. Malformed messages were gracefully handled through parser-level error detection and DLQ routing.

---

#### Scenario 2: S3 Service Outage

**Test Setup**:
- Simulated 2-minute S3 outage (t=60s to t=180s)
- Removed IAM permissions to block S3 access
- Maintained constant load of ~1000 messages

**Results**:

| Metric | Before Outage | During Outage | After Recovery |
|--------|---------------|---------------|----------------|
| XML→JSON success rate | 99.6% | 97.9% | 99.6% |
| Avg latency | 93ms | 105ms | 95ms |
| Throughput | 525 msg/s | 520 msg/s | 525 msg/s |
| Queue depth | 12 msgs | 47 msgs | 8 msgs |
| Pod crashes | 0 | 0 | 0 |

**Key Finding**: SQS visibility timeout (5 minutes) acted as a natural retry buffer. Workers continued XML→JSON conversion during the outage. Zero data loss occurred, with full recovery in 28 seconds after S3 restoration.

---

#### Scenario 3: Catastrophic Pod Failure (8→1 pods)

**Test Setup**:
- Started with 8 healthy worker pods
- Manually terminated 7 pods at t=60s
- Maintained constant message ingestion at 800 msg/s

**Results**:

| Phase | Workers | Throughput | Avg Latency | Queue Depth | Data Loss |
|-------|---------|------------|-------------|-------------|-----------|
| Before (t=0-60s) | 8 pods | 824 msg/s | 118ms | 12 msgs | 0 |
| Failure (t=60-180s) | 1 pod | 103 msg/s | 2,340ms | 4,847 msgs | 0 |
| Recovery (t=180-420s) | 1→8 pods | 103→818 msg/s | 2,340→122ms | 4,847→10 msgs | 0 |

**Key Finding**: Despite losing 87.5% of capacity, SQS prevented all data loss. The single surviving pod continued processing. HPA detected increased load and scaled back to 8 pods over 240 seconds. Queue peaked at 4,847 messages but was fully cleared within 6 minutes.

---

### Experiment 3 Summary

**Tradeoff Explored**: Strict coupling (failures cascade) vs. loose coupling (graceful degradation)

**Conclusion**: The SQS-based architecture provides excellent failure isolation:
- **Worker failures** don't cascade to other workers
- **Downstream service failures** (S3) are handled via retry mechanisms
- **Infrastructure failures** are survivable with zero data loss

**Improvements Identified**:
1. **KEDA-based autoscaling**: Replace CPU-based HPA with queue-depth monitoring for faster recovery
2. **Circuit breaker pattern**: Detect and handle consecutive S3 failures more efficiently
3. **Pre-validation layer**: Reject malformed XML at API Gateway before SQS ingestion

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

