# Project Report

This folder contains the CS6650 Final Project Report for the XML-to-JSON Converter Service.

## Contents

- **CS6650-Final-Project-Report.md**: Main project report (Markdown format)
  - Project overview and motivation
  - System architecture
  - Implementation details
  - Current progress
  - Future work and planned experiments

## Report Summary

This report documents the development of a scalable, cloud-native XML-to-JSON conversion service built with:

- **Language**: Go
- **Infrastructure**: AWS (EKS, S3, SQS, ECR)
- **Orchestration**: Kubernetes
- **IaC**: Terraform
- **Monitoring**: Prometheus

### Key Achievements

1. ✅ SQS-based asynchronous job processing
2. ✅ Complete Terraform infrastructure automation  
3. ✅ Kubernetes deployment on AWS EKS with HPA
4. ✅ S3 integration for input/output storage
5. ✅ Dead Letter Queue (DLQ) for fault tolerance
6. ✅ **Two comprehensive scalability experiments completed**

### Completed Experiments

**Experiment 1 - Horizontal Scalability**
- Tested system performance across 1, 2, 4, 8 pod replicas
- Measured throughput (RPS), latency (p95), and CPU utilization
- Identified optimal scaling point and resource bottlenecks
- Evidence: HTML reports in `test/exp1/` directory

**Experiment 2 - Elasticity Under Burst Load**
- Validated HPA auto-scaling with burst workloads (10→1000 msg/sec)
- System scaled 2→8 pods within 60 seconds
- Maintained queue depth <50 messages during peak load
- Evidence: CSV metrics in `test/exp2/` directory

**Experiment 3 - Fault Tolerance**
- Tested system resilience under three failure scenarios
- **Malformed XML**: 98.7% detection, DLQ routing, no cascading failures
- **S3 Outage**: Zero data loss, 28-second recovery via SQS visibility timeout
- **Pod Failure**: Survived 7/8 pod loss, HPA recovery in 240 seconds
- Evidence: Detailed analysis in CS6650-Final-Project-Report.md

## Report Structure

1. **Introduction** - Project overview, motivation, and tech stack
2. **System Architecture** - High-level design and component details
3. **Implementation Details** - Code walkthrough and infrastructure
4. **Current Progress** - Completed features and achievements
5. **Future Work** - Remaining tasks and planned experiments
6. **Conclusion** - Summary and next steps

---

**Date**: November 9, 2025  
**Course**: CS6650 Building Scalable Distributed Systems

