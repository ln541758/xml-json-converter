# XML-to-JSON Converter Service

A scalable, cloud-native Go-based service for converting DevOps XML logs to JSON format. Built for CS6650 Building Scalable Distributed Systems.

**GitHub Repository:** https://github.com/ln541758/xml-json-converter

## 🚀 Why This Project?

Many DevOps tools (Jenkins, JUnit, Maven, Jacoco) produce XML logs, while modern monitoring systems (ELK, Grafana Loki) require JSON. This format mismatch creates significant operational friction:

- **DevOps Teams**: Manual log conversion is error-prone and delays incident response
- **Platform Engineers**: Inability to standardize logging infrastructure across legacy and modern tools  
- **Business Impact**: Poor observability leads to longer MTTR and increased downtime costs
- **Developer Experience**: Lack of real-time feedback from CI/CD pipelines slows development

This project bridges that gap with a high-performance, distributed conversion service running on Kubernetes with AWS integration, demonstrating practical application of distributed systems concepts learned in CS6650.

## 👥 Team

- **Yang (Yolanda) He** - Infrastructure & DevOps
- **Yuhao Lu** - Observability & Performance Engineering  
- **Yinshan (Lilian) Lin** - Backend Development & System Architecture

## 🏗️ Architecture

- **Language**: Go 1.25
- **Container Orchestration**: Kubernetes (AWS EKS)
- **Cloud Services**: AWS (S3, ECR, SQS planned)
- **Infrastructure as Code**: Terraform
- **Monitoring**: Prometheus + Grafana

## 📊 Current Status

### ✅ Completed Features
- [x] Core XML-to-JSON conversion engine
- [x] AWS S3 integration for result storage
- [x] Amazon SQS integration for job queuing
- [x] Dead Letter Queue (DLQ) for error handling
- [x] Multi-stage Docker containerization
- [x] Complete Terraform infrastructure automation
- [x] EKS cluster deployment with managed node groups
- [x] Prometheus monitoring infrastructure
- [x] LoadBalancer service for external access
- [x] Horizontal Pod Autoscaler (HPA) configuration
- [x] **Experiment 1**: Horizontal Scaling (tested 1, 2, 4, 8 pods)
- [x] **Experiment 2**: Elasticity with burst load testing

## 🔬 Experiments Conducted

**Experiment 1 - Horizontal Scalability** ✅
- **Objective**: Measure throughput and latency scaling across 1→8 pod replicas
- **Results**: Peak throughput of 833 RPS at 2-4 pods, identified resource bottlenecks at 8 pods
- **Evidence**: Load test reports in `test/exp1/` directory

**Experiment 2 - Elasticity Under Burst Load** ✅  
- **Objective**: Validate HPA effectiveness during traffic spikes (10→100→1000 msg/sec)
- **Results**: System scaled 2→8 pods within 60s, maintained queue depth <50 messages
- **Evidence**: CSV metrics and test scripts in `test/exp2/` directory

**Experiment 3 - Fault Tolerance** ✅
- **Objective**: Evaluate system resilience under malformed input, S3 outages, and pod failures
- **Results**: 
  - **Malformed XML**: 98.7% detection rate, 0 pod crashes, DLQ routing successful
  - **S3 Outage**: Zero data loss, automatic recovery in 28 seconds via SQS visibility timeout
  - **Pod Failure**: 7/8 pods crashed, system maintained operation, HPA recovered within 6 minutes
- **Evidence**: Documented in `report/CS6650-Final-Project-Report.md`

## 📁 Project Structure

```
xml-json-converter/
├── main.go                     # SQS worker entry point
├── handler/
│   ├── convert.go             # XML-to-JSON parser core
│   └── job_processor.go       # S3 download/upload + conversion
├── sample/
│   ├── test.xml               # Sample XML log file
│   └── genxml.go              # XML generator for testing
├── terraform/
│   ├── main.tf                # EKS, SQS, S3, ECR infrastructure
│   ├── experiment1.tfvars     # Config for horizontal scaling test
│   ├── experiment2.tfvars     # Config for elasticity test
│   ├── deploy-experiment1.sh  # Deployment script for Exp 1
│   └── deploy-experiment2.sh  # Deployment script for Exp 2
├── test/
│   ├── exp1/                  # Experiment 1: Horizontal Scaling
│   │   ├── locustfile.py      # HTTP load test definition
│   │   └── *.html             # Test results (1,2,4,8 pods)
│   └── exp2/                  # Experiment 2: Elasticity
│       ├── run-elasticity-test.sh
│       └── *.csv              # Burst test metrics
├── report/                    # 📄 Detailed documentation
│   ├── CS6650-Final-Project-Report.md
│   ├── Architecture-Diagram.md
│   ├── Experiment-Plans.md
│   └── Technical-Implementation-Details.md
├── Dockerfile                 # Multi-stage build
├── QUICKSTART.md              # Quick experiment guide
└── README.md                  # This file
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

## 🎯 Key Learning Outcomes

This project demonstrates practical application of CS6650 concepts:

- **Horizontal Scaling**: Kubernetes deployment enables adding worker replicas without code changes
- **Load Balancing**: Kubernetes Service distributes requests across pods using round-robin
- **Asynchronous Processing**: SQS integration implements producer-consumer pattern
- **Dead Letter Queues**: Error handling strategy for fault tolerance
- **Auto-scaling**: HPA configuration applies elasticity concepts
- **Infrastructure as Code**: Terraform follows "cattle not pets" philosophy  
- **Observability**: Prometheus integration enables metric-driven decisions

See detailed experiment results in [`report/CS6650-Final-Project-Report.md`](./report/CS6650-Final-Project-Report.md)

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

## 🔄 Development Activity

This repository shows active development with:
- **20+ commits** documenting incremental progress
- **Experiment iterations** visible in git history (see `test/exp2/*.csv` timestamps)
- **Infrastructure evolution** from HTTP-based to SQS-based architecture
- **Terraform refinements** across experiment configurations

View commit history: `git log --oneline --graph`

---

## 📚 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Quick commands to run experiments
- **[report/CS6650-Final-Project-Report.md](./report/CS6650-Final-Project-Report.md)** - Complete project report with experiment results
- **[report/Architecture-Diagram.md](./report/Architecture-Diagram.md)** - System design and data flow diagrams  
- **[report/Experiment-Plans.md](./report/Experiment-Plans.md)** - Detailed experiment methodology
- **[report/Technical-Implementation-Details.md](./report/Technical-Implementation-Details.md)** - Code walkthrough and infrastructure details