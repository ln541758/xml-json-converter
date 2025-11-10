# XML-to-JSON Converter Service

A scalable, cloud-native Go-based service for converting DevOps XML logs to JSON format. Built for CS6650 Building Scalable Distributed Systems.

## 🚀 Project Overview

Many DevOps tools (Jenkins, JUnit, Maven, Jacoco) produce XML logs, while modern monitoring systems (ELK, Grafana Loki) require JSON. This project bridges that gap with a high-performance, distributed conversion service running on Kubernetes with AWS integration.

## 🏗️ Architecture

- **Language**: Go 1.25
- **Container Orchestration**: Kubernetes (AWS EKS)
- **Cloud Services**: AWS (S3, ECR, SQS planned)
- **Infrastructure as Code**: Terraform
- **Monitoring**: Prometheus + Grafana

## 📊 Current Status

### ✅ Completed Features
- [x] Core XML-to-JSON conversion engine
- [x] HTTP REST API (`/convert` endpoint)
- [x] AWS S3 integration for result storage
- [x] Multi-stage Docker containerization
- [x] Complete Terraform infrastructure automation
- [x] EKS cluster deployment
- [x] Prometheus monitoring setup
- [x] LoadBalancer service for external access

### 🔲 In Progress / Planned
- [ ] Amazon SQS integration for job queuing
- [ ] Dead Letter Queue (DLQ) for error handling
- [ ] Horizontal Pod Autoscaler (HPA)
- [ ] Prometheus metrics instrumentation
- [ ] Grafana dashboards
- [ ] Comprehensive scalability experiments

## 📁 Project Structure

```
xml-json-converter/
├── main.go                 # HTTP server entry point
├── handler/
│   ├── convert.go         # Conversion handler + S3 upload
│   └── parser.go          # XML-to-JSON parser
├── sample/
│   ├── test.xml           # Sample XML log file
│   ├── genxml.go          # XML generator for testing
│   └── result-*.json      # Conversion outputs
├── terraform/
│   ├── main.tf            # EKS, ECR, S3, Prometheus
│   ├── variables.tf       # Configurable parameters
│   └── outputs.tf         # Terraform outputs
├── Dockerfile             # Multi-stage build
├── Report/                # 📄 PROJECT REPORT
│   ├── CS6650-Final-Project-Report.md
│   ├── Architecture-Diagram.md
│   ├── Experiment-Plans.md
│   └── Technical-Implementation-Details.md
└── README.md              # This file
```

## 📄 Documentation

**Complete project report and documentation available in the [`Report/`](./Report/) folder:**

1. **[Final Project Report](./Report/CS6650-Final-Project-Report.md)** - Main report (< 5 pages)
   - Project overview and motivation
   - System architecture
   - Implementation details
   - Current progress and future work

2. **[Architecture Diagrams](./Report/Architecture-Diagram.md)** - Visual system design
   - Current architecture
   - Planned architecture with SQS
   - Data flow diagrams
   - Monitoring architecture

3. **[Experiment Plans](./Report/Experiment-Plans.md)** - Scalability testing methodology
   - Horizontal scaling experiments
   - Burst load testing
   - Fault tolerance validation
   - Cost-performance analysis

4. **[Technical Implementation](./Report/Technical-Implementation-Details.md)** - Deep dive
   - Code walkthrough
   - Infrastructure configuration
   - Deployment procedures
   - Known issues and limitations

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

## 📈 Planned Scalability Experiments

1. **Horizontal Scaling**: Measure throughput with 1→2→4→8 replicas
2. **Burst Load**: Validate HPA effectiveness during traffic spikes
3. **Fault Tolerance**: Test system with 5-10% malformed XML logs
4. **Cost-Performance**: Optimize instance types and replica counts

See [Experiment Plans](./Report/Experiment-Plans.md) for detailed methodology.

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

## 📝 Future Enhancements

### Phase 2 (Next Sprint)
- SQS integration for distributed job processing
- Dead Letter Queue for failed conversions
- Prometheus metrics instrumentation
- HPA configuration

### Phase 3 (Future)
- Grafana dashboards
- Distributed tracing (Jaeger)
- Multi-region deployment
- Streaming parser for large files
- Batch processing support

## 🤝 Contributing

This is a CS6650 final project. For questions or suggestions, please open an issue.

## 📜 License

Academic project for CS6650 - Building Scalable Distributed Systems

## 🙏 Acknowledgments

- CS6650 course staff
- AWS for cloud infrastructure
- Open-source Go community

---

**For detailed technical documentation, please see the [Report folder](./Report/).**