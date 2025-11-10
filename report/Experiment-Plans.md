# Scalability Experiments Plan

## Overview

This document outlines the planned scalability experiments for the XML-to-JSON converter service. These experiments aim to validate the system's performance, scalability, and fault tolerance under various conditions.

---

## Experiment 1: Horizontal Scaling Performance

### Objective
Measure how throughput and latency scale with increasing number of pod replicas.

### Hypothesis
Throughput will increase near-linearly with replica count until we hit I/O or network saturation.

### Methodology

#### Setup
- **Fixed Dataset**: 10,000 XML log files (varying sizes: 1KB, 10KB, 100KB)
- **Replica Configurations**: 1, 2, 4, 8 pods
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Load Generator**: Apache Bench (ab) or custom Go client

#### Test Steps
1. Deploy system with N replicas
2. Pre-load SQS queue with 10,000 conversion jobs
3. Start all workers simultaneously
4. Measure time to process all jobs
5. Collect metrics from Prometheus
6. Repeat 3 times for each configuration
7. Calculate average and standard deviation

#### Metrics to Collect
- **Throughput**: Records processed per second
- **Latency**: 
  - p50 (median)
  - p95 (95th percentile)
  - p99 (99th percentile)
  - Max
- **Resource Utilization**:
  - CPU usage per pod
  - Memory usage per pod
  - Network I/O
- **System Metrics**:
  - Queue lag (time from enqueue to process)
  - S3 upload rate

### Expected Results

| Replicas | Expected Throughput | Expected p95 Latency |
|----------|---------------------|----------------------|
| 1        | 100 records/sec     | 100ms                |
| 2        | 180 records/sec     | 110ms                |
| 4        | 340 records/sec     | 120ms                |
| 8        | 600 records/sec     | 150ms                |

**Note**: Numbers are estimates. Actual results may vary.

### Analysis Points
- Scalability efficiency = (Throughput at N pods) / (N × Throughput at 1 pod)
- Identify bottlenecks (CPU, network, S3, SQS)
- Determine optimal replica count for cost/performance

### Visualization
- Line chart: Throughput vs Replica Count
- Line chart: Latency (p50, p95, p99) vs Replica Count
- Bar chart: CPU/Memory utilization by replica count
- Scatter plot: Request duration over time

---

## Experiment 2: Elasticity Under Burst Load

### Objective
Validate that Horizontal Pod Autoscaler (HPA) effectively handles traffic spikes and keeps queue lag bounded.

### Hypothesis
HPA will scale up pods within 30-60 seconds of burst, and queue lag will stay under 5 minutes.

### Methodology

#### Setup
- **Initial State**: 2 replicas
- **HPA Configuration**: 
  - Min: 2 pods
  - Max: 10 pods
  - Target CPU: 70%
  - Scale-up delay: immediate
  - Scale-down delay: 5 minutes
- **Burst Profile**: 
  - Baseline: 50 requests/sec for 5 minutes
  - Burst: 500 requests/sec for 5 minutes
  - Return to baseline: 50 requests/sec for 10 minutes

#### Test Steps
1. Start with baseline load (50 req/sec)
2. Observe steady-state (should be 2 pods)
3. Trigger burst load (500 req/sec)
4. Monitor HPA reaction:
   - Time to first scale-up
   - Number of pods added
   - Time to reach stable state
5. Return to baseline
6. Monitor scale-down:
   - Time to start scale-down
   - Time to return to min replicas
7. Record all metrics throughout

#### Metrics to Collect
- **HPA Metrics**:
  - Pod count over time
  - Time to first scale-up event
  - Time to reach target CPU utilization
  - Time to scale down
- **Queue Metrics**:
  - Queue depth over time
  - Queue lag (age of oldest message)
  - Max queue lag during burst
- **Performance Metrics**:
  - Throughput over time
  - Latency percentiles during burst
  - Error rate during scaling events

### Success Criteria
- ✅ Queue lag stays < 5 minutes during burst
- ✅ No failed requests during scale-up
- ✅ CPU utilization stabilizes at ~70% target
- ✅ Scale-up completes within 2 minutes of burst start
- ✅ Scale-down starts after 5-minute cooldown

### Visualization
- Time-series graph: Pod count, Queue depth, CPU utilization
- Line chart: Latency percentiles during burst
- Heatmap: Request completion time vs time of day

---

## Experiment 3: Fault Tolerance and Error Handling

### Objective
Verify system stability and throughput when processing malformed XML logs.

### Hypothesis
System will maintain >95% success rate for valid logs and route malformed logs to DLQ without affecting overall stability.

### Methodology

#### Setup
- **Dataset**: 1,000 XML files
  - 90% valid XML logs (900 files)
  - 5% malformed XML (50 files): syntax errors, missing tags
  - 5% corrupted files (50 files): invalid UTF-8, truncated
- **Configuration**: 4 replicas
- **Retry Policy**: 3 attempts before DLQ

#### Test Steps
1. Shuffle dataset randomly
2. Submit all files to SQS queue
3. Process with workers
4. Monitor error handling:
   - Parse errors caught and logged
   - Failed messages sent to DLQ
   - Valid messages processed successfully
5. Verify DLQ contents
6. Attempt to replay DLQ after fixes (manual intervention)

#### Metrics to Collect
- **Success Metrics**:
  - Total processed: 1,000
  - Successfully converted: ~950
  - Failed (to DLQ): ~50
  - System stability (no crashes)
- **Performance Impact**:
  - Throughput degradation vs. clean dataset
  - Latency increase due to retries
  - CPU/Memory impact during error handling
- **Error Distribution**:
  - Parse errors by type
  - Number of retry attempts per failed message
- **Recovery Metrics**:
  - Time to process all valid logs
  - DLQ processing time after fixes

### Success Criteria
- ✅ System processes >95% of valid logs successfully
- ✅ No pod crashes or restarts
- ✅ All malformed logs end up in DLQ
- ✅ Error logs contain actionable information
- ✅ Throughput of valid logs > 90% of clean dataset baseline
- ✅ DLQ messages can be replayed after fixes

### Visualization
- Pie chart: Success vs. Failed vs. DLQ
- Bar chart: Error types distribution
- Line chart: Success rate over time
- Box plot: Processing time (valid vs. invalid logs)

---

## Experiment 4: Load Sustainability Test

### Objective
Determine maximum sustained throughput without resource exhaustion.

### Methodology

#### Setup
- **Duration**: 30 minutes continuous load
- **Replica Count**: 4 pods
- **Load Pattern**: Gradually increase from 100 to 1000 req/sec

#### Test Steps
1. Start at 100 req/sec
2. Increase by 100 req/sec every 5 minutes
3. Monitor resource utilization, latency, error rate
4. Continue until:
   - Error rate > 1%, OR
   - p95 latency > 1 second, OR
   - CPU > 90%, OR
   - Memory > 90%
5. Identify breaking point

#### Metrics
- Maximum sustained throughput
- Resource utilization at max load
- Latency degradation curve
- Error rate threshold

---

## Experiment 5: Cost-Performance Analysis

### Objective
Determine optimal instance type and replica count for cost efficiency.

### Methodology

#### Configurations to Test
| Instance Type | vCPU | Memory | Replicas | Hourly Cost |
|---------------|------|--------|----------|-------------|
| t3.small      | 2    | 2 GB   | 8        | ~$0.17      |
| t3.medium     | 2    | 4 GB   | 4        | ~$0.17      |
| t3.large      | 2    | 8 GB   | 2        | ~$0.17      |
| c5.large      | 2    | 4 GB   | 4        | ~$0.34      |

#### Metrics
- Throughput per dollar
- Latency per configuration
- Time to process 10,000 files
- Total cost per 1M conversions

---

## Testing Tools

### Load Generation
```bash
# Apache Bench
ab -n 10000 -c 100 -p request.json \
   -T application/json \
   http://load-balancer-url/convert

# Custom Go Load Generator
go run load_test.go \
  --requests 10000 \
  --concurrency 100 \
  --ramp-up 30s \
  --duration 5m
```

### Monitoring
```bash
# Watch pod metrics
kubectl top pods -n default --watch

# Prometheus queries
rate(conversion_requests_total[5m])
histogram_quantile(0.95, conversion_duration_seconds)

# SQS metrics
aws sqs get-queue-attributes \
  --queue-url <url> \
  --attribute-names ApproximateNumberOfMessages
```

### Data Generation
```bash
# Generate test XML files
go run sample/genxml.go \
  --count 10000 \
  --sizes 1KB,10KB,100KB \
  --malformed-rate 0.05
```

---

## Results Documentation Template

### For Each Experiment

```markdown
## Experiment N: [Name]

### Date & Time
- Date: YYYY-MM-DD
- Duration: X hours
- Operator: [Name]

### Environment
- Cluster: [name]
- Region: [aws-region]
- Kubernetes Version: [version]
- Node Type: [instance-type]
- Replicas: [count]

### Configuration
- [Key config parameters]

### Raw Data
- Prometheus Metrics: [S3 link]
- Application Logs: [S3 link]
- Raw Results: [CSV/JSON file]

### Results Summary

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| ...    | ...   | ...    | ✅/❌   |

### Observations
- [Key findings]

### Issues Encountered
- [Problems and resolutions]

### Graphs
![Throughput Chart](./results/exp1-throughput.png)
![Latency Chart](./results/exp1-latency.png)

### Conclusion
- [Summary of results vs hypothesis]
```

---

## Timeline

| Week | Tasks |
|------|-------|
| 1    | Complete SQS integration, HPA configuration |
| 2    | Implement Prometheus metrics, create Grafana dashboards |
| 2    | Run Experiment 1: Horizontal Scaling |
| 3    | Run Experiment 2: Burst Load |
| 3    | Run Experiment 3: Fault Tolerance |
| 4    | Run Experiment 4 & 5: Sustainability & Cost Analysis |
| 4    | Analyze results, write final report |

---

## Safety & Cleanup

### Cost Controls
- Set AWS budgets and alerts
- Use Terraform `destroy` to tear down after experiments
- Verify all resources deleted: `aws resourcegroupstaggingapi get-resources`

### Monitoring Alerts
- Slack/Email notifications for:
  - Pod OOMKilled
  - Error rate > 5%
  - Cost > $50/day

### Experiment Checklist
- [ ] Terraform plan reviewed
- [ ] AWS budget alert configured
- [ ] Load test script validated
- [ ] Prometheus/Grafana dashboards ready
- [ ] Baseline metrics collected
- [ ] Rollback plan documented
- [ ] Post-experiment cleanup script ready

---

This experiment plan provides a comprehensive framework for validating the scalability, performance, and fault tolerance of the XML-to-JSON converter service.

