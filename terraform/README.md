# Terraform Infrastructure

Infrastructure-as-Code for deploying the XML-JSON converter service on AWS EKS.

## Quick Start

**Experiment 1 - Horizontal Scaling**:
```bash
./deploy-experiment1.sh 4   # Deploy with 4 replicas (HTTP-based)
```

**Experiment 2 - Elasticity**:
```bash
./deploy-experiment2.sh     # Deploy with HPA (SQS-based)
```

**Cleanup**:
```bash
./cleanup.sh                # Destroy all infrastructure
```

---

## Infrastructure Components

**Common Resources** (both experiments):
- **EKS Cluster** (Kubernetes 1.29)
- **SQS Queue + DLQ** (message processing)
- **S3 Buckets** (input + output storage)
- **ECR Repository** (Docker images)
- **Prometheus** (monitoring)

**Experiment 1 Specific**:
- Fixed pod replicas (configurable via tfvars)
- LoadBalancer service for HTTP access

**Experiment 2 Specific**:
- Horizontal Pod Autoscaler (HPA)
- Metrics Server for CPU-based scaling
- Min: 2 pods, Max: 10 pods, Target: 70% CPU

---

## Configuration Files

- **`experiment1.tfvars`** - Variables for horizontal scaling test
- **`experiment2.tfvars`** - Variables for elasticity test
- **`main.tf`** - Core infrastructure definition
- **`variables.tf`** - Input variables
- **`outputs.tf`** - Terraform outputs (LoadBalancer DNS, SQS URL, etc.)

---

## Monitoring

```bash
# View HPA status (Experiment 2 only)
kubectl get hpa -w

# View pod status
kubectl get pods -w

# View CPU usage
kubectl top pods

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
# Open http://localhost:9090
```

---

## Manual Terraform Commands

If you prefer manual control over the deployment scripts:

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file=experiment1.tfvars

# Apply configuration
terraform apply -var-file=experiment1.tfvars -auto-approve

# View outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file=experiment1.tfvars -auto-approve
```





