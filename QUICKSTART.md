# Quick Start Guide

This guide shows how to reproduce the experiments from our CS6650 final project.

## Prerequisites

- AWS Account with EKS/S3/SQS permissions
- `terraform`, `kubectl`, `aws-cli` installed
- Python 3.x with `locust` for load testing

---

## Experiment 1: Horizontal Scaling ✅ COMPLETED

**Objective**: Measure throughput and latency scaling across different replica counts

**What This Tests**: How the system performs as we add more worker pods (1 → 2 → 4 → 8)

```bash
# Deploy with specific replica count
cd terraform
./deploy-experiment1.sh 4        # Example: 4 replicas

# Get LoadBalancer DNS
terraform output -raw load_balancer_dns

# Run load test (from test directory)
cd ../test/exp1
./run_load_test.sh http://<loadbalancer-dns> 100 100 60s
```

**Results Location**: `test/exp1/load_test{1,2,4,8}_report.html`

**Key Findings**: Peak throughput ~833 RPS at 2-4 pods, diminishing returns at 8 pods

---

## Experiment 2: Elasticity (HPA Auto-Scaling) ✅ COMPLETED

**Objective**: Validate HPA effectiveness during burst workloads

**What This Tests**: System's ability to auto-scale under increasing load (10 → 100 → 1000 msg/sec)

```bash
# Deploy with HPA enabled
cd terraform
./deploy-experiment2.sh

# Run burst load test
cd ../test/exp2
./run-elasticity-test.sh          # Interactive script with 4 phases
```

**Monitor in Separate Terminals** (optional):
```bash
watch -n 5 kubectl get hpa         # HPA status
watch -n 5 kubectl get pods        # Pod count
watch -n 5 kubectl top pods        # CPU usage
```

**Results Location**: `test/exp2/elasticity-test-*.csv`

**Key Findings**: System scaled 2→8 pods in 60s, queue depth peaked at 45 messages

---

## Experiment 3: Fault Tolerance ✅ COMPLETED

**Objective**: Evaluate system resilience under various failure conditions

**What This Tests**: How the system handles malformed input, downstream service failures, and infrastructure catastrophes

### Test Scenarios

**Scenario 1: Malformed XML Input**
- Injected 1,000 malformed XML messages (20% of total traffic)
- **Results**: 98.7% detection rate, 0 pod crashes, all malformed messages routed to DLQ
- **Key Finding**: Worker isolation prevents cascading failures

**Scenario 2: S3 Service Outage**
- Simulated 2-minute S3 outage by removing IAM permissions
- **Results**: Zero data loss, 97.9% success rate during outage, 28-second recovery
- **Key Finding**: SQS visibility timeout acts as natural retry buffer

**Scenario 3: Catastrophic Pod Failure (8→1 pods)**
- Manually terminated 7/8 worker pods during active load
- **Results**: Single pod maintained 103 msg/s, HPA recovered to 8 pods in 240s, zero data loss
- **Key Finding**: SQS prevents data loss even during infrastructure failures

### Running Tests

**Note**: These are destructive tests. Documentation available in:
- `report/CS6650-Final-Project-Report.md` (Experiment 3 section)
- Test methodology in `report/Experiment-Plans.md`

**To simulate** (not recommended for production):
```bash
# Scenario 1: Inject malformed XML
# (Custom script required - see report for methodology)

# Scenario 2: Simulate S3 outage
# Remove S3 permissions temporarily via AWS IAM console

# Scenario 3: Pod failure
kubectl delete pods -l app=xml-json-parser --force
watch kubectl get pods  # Observe HPA recovery
```

---

## Cleanup

**IMPORTANT**: Destroy infrastructure to avoid AWS charges

```bash
cd terraform
./cleanup.sh
# OR manually:
terraform destroy -auto-approve
```

---

## Viewing Results

**Experiment 1 (HTTP Load Tests)**:
- Open `test/exp1/load_test{1,2,4,8}_report.html` in browser
- Compare throughput (RPS) and latency (p95) across pod counts

**Experiment 2 (Elasticity)**:
- View CSV files in `test/exp2/elasticity-test-*.csv`
- Key columns: Timestamp, Phase, QueueDepth, PodCount, AvgCPU

---

## Troubleshooting

**Issue**: `terraform apply` fails
- **Solution**: Check AWS credentials: `aws sts get-caller-identity`

**Issue**: LoadBalancer DNS not resolving
- **Solution**: Wait 2-3 minutes for AWS provisioning: `kubectl get svc -w`

**Issue**: Locust not installed
- **Solution**: `pip install -r test/requirements.txt`
