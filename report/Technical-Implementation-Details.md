# Technical Implementation Details

## Current System Status: Phase 1 Complete

This document provides detailed technical information about the implemented components of the XML-to-JSON converter service.

---

## 1. Application Code

### 1.1 Main Server (`main.go`)

**Purpose**: HTTP server entry point

**Key Features**:
- Uses Go's standard `net/http` library for maximum efficiency
- Single endpoint: `/convert`
- Runs on port 8080
- Lightweight and fast startup time

**Code Structure**:
```go
package main

import (
    "log"
    "net/http"
    "xml-json-converter/handler"
)

func main() {
    http.HandleFunc("/convert", handler.ConvertHandler)
    log.Println("Server running at :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

**Rationale**: 
- Standard library is sufficient for current needs
- Easy to extend with middleware (logging, metrics, auth)
- No external framework overhead

---

### 1.2 Conversion Handler (`handler/convert.go`)

**Purpose**: Orchestrates the XML-to-JSON conversion workflow

**Dependencies**:
- `github.com/aws/aws-sdk-go-v2/service/s3`: S3 upload functionality
- `github.com/aws/aws-sdk-go-v2/config`: AWS configuration

**Workflow**:
1. Read XML data from input (currently local file)
2. Call parser to convert XML → JSON
3. Return JSON to client (synchronous)
4. Upload result to S3 (asynchronous via goroutine)
5. Save to local file for debugging

**Key Functions**:

#### `ConvertHandler(w http.ResponseWriter, r *http.Request)`
- HTTP request handler
- Reads `sample/test.xml` (placeholder for future SQS message body)
- Converts XML to JSON
- Returns JSON response immediately
- Triggers background S3 upload

**Error Handling**:
- File read errors → HTTP 500 with error message
- Parse errors → HTTP 500 with detailed error
- S3 upload errors → logged but don't block response

#### `uploadToS3(data []byte) error`
- Asynchronous S3 upload function
- Uses AWS SDK v2 with default credential chain
- Creates timestamped filenames: `result-{unix-timestamp}.json`
- Target bucket: `xml-json-output-bucket`

**Current Limitations**:
- No authentication/authorization
- Fixed input file path (not production-ready)
- S3 errors not reported to client
- No retry logic for S3 uploads
- No request validation

**Future Enhancements**:
- Read from SQS message instead of local file
- Add retry logic with exponential backoff
- Implement circuit breaker for S3
- Add request ID for tracing
- Metrics instrumentation

---

### 1.3 XML Parser (`handler/parser.go`)

**Purpose**: Core XML-to-JSON conversion logic

**Library**: `github.com/clbanning/mxj/v2`
- Popular Go library for XML manipulation
- Efficient XML parsing
- Direct JSON conversion
- Handles nested structures

**Function**: `XMLToJSON(data []byte) ([]byte, error)`

**Implementation**:
```go
func XMLToJSON(data []byte) ([]byte, error) {
    // Parse XML to map[string]interface{}
    mv, err := mxj.NewMapXml(data)
    if err != nil {
        return nil, err
    }
    
    // Convert map to JSON
    jsonData, err := mv.Json()
    if err != nil {
        return nil, err
    }
    
    return jsonData, nil
}
```

**Advantages**:
- Two-phase conversion allows intermediate processing
- Error handling at each step
- Memory-efficient for moderate file sizes
- Preserves XML structure in JSON

**Current Limitations**:
- Loads entire XML into memory (not suitable for very large files)
- No schema validation
- No custom transformation rules
- Limited error context

**Future Enhancements**:
- Streaming parser for large files (SAX-style)
- XML schema validation
- Configurable transformation rules
- Better error messages with line numbers
- Support for XML namespaces

---

## 2. Infrastructure as Code (Terraform)

### 2.1 Overview

**Location**: `terraform/main.tf`, `variables.tf`, `outputs.tf`

**Terraform Version**: >= 1.3.0

**Providers**:
- AWS (~> 5.0): Cloud infrastructure
- Docker (~> 3.0): Image build and push
- Helm (~> 2.12): Kubernetes package management
- Kubernetes: K8s resource deployment

### 2.2 AWS Resources

#### 2.2.1 Elastic Container Registry (ECR)

```hcl
resource "aws_ecr_repository" "parser_repo" {
  name = "xml-json-parser"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

**Features**:
- Automatic security scanning
- Mutable tags for development
- Private repository

**Image Lifecycle**:
1. Dockerfile changes trigger rebuild
2. Docker provider builds image locally
3. Image pushed to ECR
4. Kubernetes pulls from ECR

#### 2.2.2 Elastic Kubernetes Service (EKS)

**Module**: `terraform-aws-modules/eks/aws` (v19.20.0)

**Configuration**:
```hcl
module "eks" {
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  vpc_id          = data.aws_vpc.default.id
  subnet_ids      = data.aws_subnets.default.ids
  
  # IAM roles (pre-existing for Lab environment)
  iam_role_arn    = "arn:aws:iam::XXX:role/LabEksClusterRole"
  create_iam_role = false
  
  eks_managed_node_groups = {
    default = {
      desired_size   = var.node_count
      max_size       = var.node_max
      min_size       = var.node_min
      instance_types = [var.instance_type]
      iam_role_arn   = "arn:aws:iam::XXX:role/LabEksNodeRole"
    }
  }
}
```

**Node Group Parameters** (configurable):
- `instance_type`: default `t3.medium` (2 vCPU, 4GB RAM)
- `node_count`: desired count
- `node_min` / `node_max`: auto-scaling boundaries

**Networking**:
- Uses default VPC
- Spans all available subnets
- Security groups managed by EKS module

**IAM Considerations**:
- Lab environment uses pre-existing roles
- Production would use `create_iam_role = true`

#### 2.2.3 S3 Bucket

```hcl
resource "aws_s3_bucket" "xml_json_output" {
  bucket        = "${var.cluster_name}-bucket"
  force_destroy = true  # Allows deletion with contents
}
```

**Configuration**:
- Dynamically named based on cluster
- `force_destroy = true`: for experimentation (delete easily)
- No versioning (can be added)
- No lifecycle rules (can be added)

**Future Enhancements**:
- Separate buckets for input/output
- Lifecycle policy (archive to Glacier after 30 days)
- Server-side encryption
- Access logging
- CORS configuration for web access

### 2.3 Docker Image Build & Push

```hcl
resource "docker_image" "parser" {
  name = "${aws_ecr_repository.parser_repo.repository_url}:latest"
  
  build {
    context    = "../../xml-json-converter"
    dockerfile = "../../xml-json-converter/Dockerfile"
    tag        = ["${aws_ecr_repository.parser_repo.repository_url}:latest"]
  }
  
  triggers = {
    # Rebuild if any file changes
    dir_sha1 = sha1(join("", [
      for f in fileset("../../xml-json-converter", "**") : 
      filesha1("../../xml-json-converter/${f}")
    ]))
  }
}
```

**Automatic Rebuild**:
- SHA1 hash of all files in project
- Any code change triggers image rebuild
- Push happens automatically after build

**ECR Authentication**:
- Handled by Docker provider
- Uses AWS credentials
- Token refreshed automatically

### 2.4 Kubernetes Resources

#### 2.4.1 Deployment

```hcl
resource "kubernetes_deployment" "parser" {
  metadata {
    name = "xml-json-parser"
    labels = { app = "parser" }
  }
  
  spec {
    replicas = var.replica_count
    
    selector {
      match_labels = { app = "parser" }
    }
    
    template {
      metadata {
        labels = { app = "parser" }
      }
      
      spec {
        container {
          name  = "parser"
          image = docker_registry_image.parser_push.name
          port {
            container_port = var.container_port  # 8080
          }
        }
      }
    }
  }
}
```

**Features**:
- Configurable replica count
- Automatic image pull from ECR
- Rolling update strategy (default)
- Restart policy: Always (default)

**Missing** (to be added):
- Resource requests/limits
- Liveness/readiness probes
- Environment variables for config
- Volume mounts
- Service account with IAM role (IRSA)

#### 2.4.2 Service

```hcl
resource "kubernetes_service" "parser_service" {
  metadata {
    name = "xml-json-parser-service"
  }
  
  spec {
    selector = { app = "parser" }
    
    port {
      port        = 80
      target_port = var.container_port
    }
    
    type = "LoadBalancer"
  }
}
```

**Type**: LoadBalancer
- AWS ELB provisioned automatically
- Public IP address assigned
- Traffic distributed across pods

**Alternative** (future):
- Use Ingress with ALB Ingress Controller
- Add TLS/SSL termination
- Path-based routing

#### 2.4.3 Monitoring Stack (Prometheus)

```hcl
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  
  create_namespace = true
  
  set {
    name  = "server.persistentVolume.enabled"
    value = "false"  # No persistence for experiments
  }
  
  set {
    name  = "alertmanager.enabled"
    value = "false"  # Not needed yet
  }
}
```

**Components Deployed**:
- Prometheus Server: metrics collection & storage
- Node Exporter: node-level metrics
- Kube State Metrics: Kubernetes object metrics
- Pushgateway: for batch jobs (optional)

**Configuration**:
- No persistent storage (metrics lost on restart)
- Alert Manager disabled
- Default scrape interval: 15s
- Retention: 15 days (default)

**Access**:
```bash
kubectl port-forward -n monitoring \
  svc/prometheus-server 9090:80
```

---

## 3. Containerization

### 3.1 Dockerfile

**Strategy**: Multi-stage build for minimal image size

#### Stage 1: Builder

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build binary
COPY . .
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -o parser .
```

**Key Points**:
- Uses official Go 1.22 image
- Dependency layer cached separately
- CGO disabled for static binary
- Linux/AMD64 target

#### Stage 2: Runtime

```dockerfile
FROM alpine:latest
WORKDIR /app

COPY --from=builder /app/parser .

EXPOSE 8080
CMD ["./parser"]
```

**Key Points**:
- Alpine Linux: ~5MB base image
- Only copies final binary
- No build tools in final image
- Total image size: ~20MB

**Security**:
- Minimal attack surface
- No shell utilities (if needed, use `busybox`)
- Non-root user (should be added)

**Improvements Needed**:
- Add non-root user:
  ```dockerfile
  RUN adduser -D appuser
  USER appuser
  ```
- Copy sample files if needed
- Add health check
- Version labels

---

## 4. Dependencies

### 4.1 Go Modules (`go.mod`)

**Go Version**: 1.25.1

**Direct Dependencies**:

```go
require (
    github.com/aws/aws-sdk-go-v2 v1.39.6
    github.com/aws/aws-sdk-go-v2/config v1.31.17
    github.com/aws/aws-sdk-go-v2/service/s3 v1.90.0
    github.com/clbanning/mxj/v2 v2.7.0
)
```

**AWS SDK v2**:
- Modern, modular AWS SDK
- Supports context for cancellation
- Better performance than v1
- Default credential chain (IAM roles, env vars, etc.)

**mxj Library**:
- XML manipulation library
- Efficient XML-to-JSON conversion
- Well-maintained

**Transitive Dependencies**:
- 18 indirect dependencies
- All AWS SDK internal packages
- `smithy-go`: AWS API client framework

---

## 5. Configuration & Variables

### 5.1 Terraform Variables (`variables.tf`)

**Expected Variables**:
- `region`: AWS region (e.g., `us-east-1`)
- `cluster_name`: EKS cluster name
- `node_count`: Desired node count
- `node_min`: Minimum nodes for auto-scaling
- `node_max`: Maximum nodes for auto-scaling
- `instance_type`: EC2 instance type
- `replica_count`: Number of parser pods
- `container_port`: Container port (8080)

**Example** `terraform.tfvars`:
```hcl
region         = "us-east-1"
cluster_name   = "xml-json-dev"
node_count     = 2
node_min       = 1
node_max       = 5
instance_type  = "t3.medium"
replica_count  = 3
container_port = 8080
```

### 5.2 Application Configuration

**Current**: Hardcoded values
**Future**: Environment variables

```go
// Future configuration
type Config struct {
    ServerPort  string `env:"SERVER_PORT" default:"8080"`
    S3Bucket    string `env:"S3_BUCKET" required:"true"`
    SQSQueue    string `env:"SQS_QUEUE_URL" required:"true"`
    AWSRegion   string `env:"AWS_REGION" default:"us-east-1"`
    LogLevel    string `env:"LOG_LEVEL" default:"info"`
}
```

---

## 6. Testing

### 6.1 Sample Data

**File**: `sample/test.xml`

```xml
<logs>
  <log><id>0</id><level>INFO</level><msg>Message 0</msg></log>
  <log><id>1</id><level>INFO</level><msg>Message 1</msg></log>
  ...
  <log><id>19</id><level>INFO</level><msg>Message 19</msg></log>
</logs>
```

**Characteristics**:
- 20 log entries
- Simple structure
- All INFO level
- ~500 bytes total

### 6.2 Expected Output

**File**: `sample/result-{timestamp}.json`

```json
{
  "logs": {
    "log": [
      {"id": "0", "level": "INFO", "msg": "Message 0"},
      {"id": "1", "level": "INFO", "msg": "Message 1"},
      ...
    ]
  }
}
```

### 6.3 Manual Testing

```bash
# Local testing
go run main.go
curl http://localhost:8080/convert

# Kubernetes testing
kubectl port-forward svc/xml-json-parser-service 8080:80
curl http://localhost:8080/convert

# Load testing
ab -n 1000 -c 10 http://localhost:8080/convert
```

### 6.4 Future Testing

- Unit tests for parser
- Integration tests with mocked S3
- End-to-end tests in test namespace
- Load tests with realistic data
- Chaos engineering (pod failures, network issues)

---

## 7. Deployment Workflow

### 7.1 Initial Deployment

```bash
# 1. Initialize Terraform
cd terraform
terraform init

# 2. Review plan
terraform plan

# 3. Deploy infrastructure
terraform apply

# 4. Get LoadBalancer URL
terraform output load_balancer_url

# 5. Test service
curl http://<lb-url>/convert
```

### 7.2 Update Workflow

```bash
# Code change → Rebuild → Redeploy

# 1. Modify Go code
vim handler/convert.go

# 2. Terraform detects change via SHA1 hash
terraform plan  # Shows docker_image will rebuild

# 3. Apply changes
terraform apply  # Builds, pushes, updates deployment

# 4. Kubernetes rolling update automatically
kubectl rollout status deployment/xml-json-parser
```

### 7.3 Monitoring

```bash
# Pod status
kubectl get pods -l app=parser

# Logs
kubectl logs -f deployment/xml-json-parser

# Metrics
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Open http://localhost:9090

# Resource usage
kubectl top pods
kubectl top nodes
```

---

## 8. Known Issues & Limitations

### 8.1 Current Issues

1. **No Authentication**: Anyone with LoadBalancer URL can use service
2. **Fixed Input Source**: Reads from local file instead of SQS
3. **No Request Validation**: No checks on input data
4. **S3 Error Handling**: Upload errors silently logged
5. **No Metrics**: No Prometheus instrumentation yet
6. **No Health Checks**: Kubernetes can't verify pod health
7. **Resource Limits**: No CPU/memory requests or limits set
8. **No Logging Structure**: Using basic `log.Println`

### 8.2 Security Considerations

1. **IAM Permissions**: Pods need IAM role for S3 access (use IRSA)
2. **Network Policies**: No network segmentation
3. **Secrets Management**: No secrets yet, but will need for future (use AWS Secrets Manager)
4. **Image Scanning**: Enabled on ECR, but not blocking
5. **Non-root Container**: Should run as non-root user

### 8.3 Performance Limitations

1. **Memory**: Entire XML loaded into memory
2. **Concurrency**: Single-threaded per request
3. **Connection Pooling**: S3 client not reused efficiently
4. **No Caching**: No caching layer

---

## 9. Next Development Steps

### Priority 1: Core Functionality
- [ ] Integrate Amazon SQS for job queue
- [ ] Implement worker pattern (poll SQS)
- [ ] Add Dead Letter Queue (DLQ)
- [ ] Structured logging with log levels

### Priority 2: Observability
- [ ] Add Prometheus metrics
- [ ] Implement health check endpoints
- [ ] Deploy Grafana dashboards
- [ ] Add distributed tracing (Jaeger)

### Priority 3: Production Readiness
- [ ] Add resource requests/limits
- [ ] Implement readiness/liveness probes
- [ ] Configure HPA
- [ ] Add retry logic with exponential backoff
- [ ] Implement circuit breakers
- [ ] Use IRSA for AWS permissions

### Priority 4: Enhancements
- [ ] Streaming XML parser for large files
- [ ] Batch processing support
- [ ] Custom transformation rules
- [ ] Multi-region support
- [ ] Cost optimization (spot instances)

---

This technical documentation provides a comprehensive overview of the current implementation, serving as a reference for development and troubleshooting.

