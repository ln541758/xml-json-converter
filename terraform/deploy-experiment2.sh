#!/bin/bash

# Deployment script for Experiment 2: Elasticity Testing
# This script deploys the infrastructure with HPA enabled

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Experiment 2: Elasticity Testing"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  - HPA Enabled: Yes"
echo "  - Min Replicas: 2"
echo "  - Max Replicas: 10"
echo "  - Target CPU: 70%"
echo "  - Scale-up: Immediate"
echo "  - Scale-down: 5 minutes"
echo ""
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Error: terraform not found. Please install Terraform."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ Error: aws CLI not found. Please install AWS CLI."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found. Please install kubectl."
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Initialize Terraform
echo "Initializing Terraform..."
terraform init
echo ""

# Plan deployment
echo "Planning deployment..."
terraform plan -var-file="experiment2.tfvars" -out=exp2.tfplan
echo ""

# Confirm deployment
read -p "Do you want to apply this configuration? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f exp2.tfplan
    exit 0
fi

# Apply deployment
echo ""
echo "Deploying infrastructure..."
terraform apply exp2.tfplan
rm -f exp2.tfplan
echo ""

# Configure kubectl
echo "Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region us-west-2 --name "$CLUSTER_NAME"
echo ""

# Wait for nodes to be ready
echo "Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s
echo ""

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods -l app=parser --timeout=300s
echo ""

# Display deployment status
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""

echo "Cluster Information:"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Load Balancer: $(terraform output -raw load_balancer_dns)"
echo "  S3 Bucket: $(terraform output -raw s3_bucket_name)"
echo ""

echo "HPA Status:"
kubectl get hpa xml-json-parser-hpa
echo ""

echo "Pod Status:"
kubectl get pods -l app=parser
echo ""

echo "Service Status:"
kubectl get svc xml-json-parser-service
echo ""

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Monitor HPA:"
echo "   kubectl get hpa -w"
echo ""
echo "2. Monitor Pods:"
echo "   kubectl get pods -w"
echo ""
echo "3. Watch CPU Usage:"
echo "   watch -n 5 kubectl top pods"
echo ""
echo "4. Run Load Test:"
echo "   cd ../test"
echo "   ./run_load_test.sh"
echo ""
echo "5. Access Prometheus:"
echo "   kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
echo "   Open: http://localhost:9090"
echo ""
echo "6. View HPA Events:"
echo "   kubectl describe hpa xml-json-parser-hpa"
echo ""
echo "=========================================="
echo "Cost Alert:"
echo "=========================================="
echo "Estimated cost: ~\$0.22/hour (~\$5/day)"
echo "Remember to run 'terraform destroy' after experiments!"
echo ""

