# XML-to-JSON Converter Service

A scalable, cloud-native Go-based service for converting DevOps XML logs to JSON format. Built for CS6650 Building Scalable Distributed Systems.

**GitHub Repository:** https://github.com/ln541758/xml-json-converter

This project implements a cloud-native XML-to-JSON conversion service designed to handle large-scale workloads reliably and efficiently.
The system follows an asynchronous, distributed architecture using AWS EKS, SQS, and S3, ensuring high scalability, resilience to failures, and smooth handling of bursty traffic.

The service receives XML conversion jobs, processes them in worker pods running on Kubernetes, and stores the resulting JSON files in Amazon S3. Metrics are monitored through Prometheus and visualized in Grafana, enabling detailed scalability and fault-tolerance analysis.

## 🏗️ Architecture

- **Language**: Go 1.25
- **Container Orchestration**: Kubernetes (AWS EKS)
- **Cloud Services**: AWS (S3, ECR, SQS planned)
- **Infrastructure as Code**: Terraform
- **Monitoring**: Prometheus + Grafana



## 📁 Development Motivation

Modern distributed systems must support high throughput, dynamic scaling, and graceful failure handling.
The motivation behind this project is to explore these real-world challenges by building a system that:

Scales horizontally under increasing load

Recovers gracefully from downstream failures (e.g., S3 outages)

Ensures message durability using SQS

Provides observability for debugging and performance tuning

Implements autoscaling strategies (CPU-based HPA and potential queue-based autoscaling)

This project allowed us to apply key concepts learned in CS6650—such as asynchronous messaging, autoscaling, load shedding, distributed fault tolerance, and infrastructure-as-code—and test them in an end-to-end real cloud environment.

## 📄 Documentation

**Complete project report and documentation available in the [`report/`](./report/) folder:**

1. **[Final Project Report](./report/report.md)** - Main report
   - Project overview and motivation
   - System architecture
   - Implementation details
   - Current progress and future work

2. **[Architecture Diagrams](./report/graph/architecture.png)** - Visual system design
   - Current architecture
   - Planned architecture with SQS
   - [Data flow diagrams](./report/graph/Data-flow.png)
   - Monitoring architecture

3. **[Experiment Report](./report/Experiment report.pdf)** - Scalability testing methodology
   - Horizontal scaling experiments
   - Burst load testing
   - Fault tolerance validation
   - Cost-performance analysis



## 🚀 Quick Start

### Prerequisites
- Go 1.25+
- Docker
- Terraform >= 1.3.0
- AWS Account with appropriate permissions
- kubectl configured for EKS

### Local Development

```bash
# Clone repository
git clone <repo-url>
cd xml-json-converter

# Install dependencies
go mod download

# Run locally
go run main.go

# Test endpoint
curl http://localhost:8080/convert
```

### Deploy to AWS EKS

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply

# Get LoadBalancer URL
terraform output load_balancer_url

# Test deployed service
curl http://<load-balancer-url>/convert
```

## 🔍 Monitoring

```bash
# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Open http://localhost:9090

# View pod status
kubectl get pods -l app=parser

# View logs
kubectl logs -f deployment/xml-json-parser

# Check resource usage
kubectl top pods
```

## 🧪 Testing

```bash
# Unit tests (to be implemented)
go test ./...

# Load testing
ab -n 1000 -c 10 http://localhost:8080/convert
```

## 🎯 Key Learning Outcomes

This project demonstrates practical application of CS6650 concepts:

See [Experiment Plans](./report/Experiment report.mpdf) for detailed methodology.

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Language | Go 1.25 | High-performance, concurrent processing |
| Web Framework | Go `net/http` | Lightweight HTTP server |
| XML Parser | `clbanning/mxj` | Efficient XML-to-JSON conversion |
| Cloud Provider | AWS | Infrastructure hosting |
| Container Registry | AWS ECR | Docker image storage |
| Object Storage | AWS S3 | Result persistence |
| Message Queue | AWS SQS (planned) | Job distribution |
| Orchestration | Kubernetes (EKS) | Container management |
| IaC | Terraform | Infrastructure automation |
| Monitoring | Prometheus | Metrics collection |
| Visualization | Grafana (planned) | Dashboards and alerts |

## 🎯 Key Design Decisions

1. **Go Language**: Lightweight concurrency, fast I/O, native Prometheus integration
2. **Kubernetes**: Industry-standard orchestration, built-in scaling, self-healing
3. **Terraform**: Infrastructure as Code for reproducibility and version control
4. **Multi-stage Docker**: Minimal image size (~20MB) for fast deployment
5. **Asynchronous S3 Upload**: Non-blocking response to clients


**For detailed technical documentation, please see the [report folder](./report/).**
