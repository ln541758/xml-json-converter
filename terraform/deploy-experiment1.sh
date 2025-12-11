#!/bin/bash

# Deployment script for Experiment 1: Horizontal Scaling Performance
# This script deploys the infrastructure with fixed replica count

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default replica count
REPLICA_COUNT=${1:-1}

echo "=========================================="
echo "Experiment 1: Horizontal Scaling"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  - HPA Enabled: No"
echo "  - Fixed Replicas: $REPLICA_COUNT"
echo "  - Instance Type: t3.medium"
echo ""
echo "=========================================="
echo ""

# Validate replica count
if [[ ! "$REPLICA_COUNT" =~ ^[1248]$ ]]; then
    echo "❌ Error: Replica count must be 1, 2, 4, or 8"
    echo "Usage: $0 [1|2|4|8]"
    exit 1
fi

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
terraform plan -var-file="experiment1.tfvars" -var="replica_count=$REPLICA_COUNT" -out=exp1.tfplan
echo ""

# Confirm deployment
read -p "Do you want to apply this configuration? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f exp1.tfplan
    exit 0
fi

# Apply deployment
echo ""
echo "Deploying infrastructure..."
terraform apply exp1.tfplan
rm -f exp1.tfplan
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
echo "  SQS Queue: $(terraform output -raw sqs_queue_url)"
echo "  S3 Input: $(terraform output -raw s3_input_bucket)"
echo "  S3 Output: $(terraform output -raw s3_output_bucket)"
echo "  Replica Count: $REPLICA_COUNT"
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
echo "1. Monitor Pods:"
echo "   kubectl get pods -w"
echo ""
echo "2. Watch CPU/Memory Usage:"
echo "   watch -n 5 kubectl top pods"
echo ""
echo "3. Run Load Test (see test/README.md):"
echo "   cd ../test"
echo "   ./run_load_test.sh http://\$(cd ../terraform && terraform output -raw load_balancer_dns)"
echo ""
echo "4. Scale to Different Replica Count:"
echo "   ./deploy-experiment1.sh [1|2|4|8]"
echo ""
echo "=========================================="
echo "Cost Alert:"
echo "=========================================="
echo "Estimated cost: ~\$0.32/hour (~\$8/day)"
echo "Remember to run 'terraform destroy' after experiments!"
echo ""




