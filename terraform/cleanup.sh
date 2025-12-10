#!/bin/bash

# Cleanup script to destroy all infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Infrastructure Cleanup"
echo "=========================================="
echo ""

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "No terraform state found. Nothing to destroy."
    exit 0
fi

# Show current resources
echo "Current infrastructure:"
terraform show
echo ""

# Confirm destruction
read -p "⚠️  This will destroy ALL infrastructure. Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Determine which var file to use
VAR_FILE=""
if terraform show | grep -q "xml-json-parser-hpa"; then
    echo "Detected Experiment 2 configuration (HPA enabled)"
    VAR_FILE="experiment2.tfvars"
elif [ -f "experiment1.tfvars" ]; then
    echo "Detected Experiment 1 configuration"
    VAR_FILE="experiment1.tfvars"
fi

# Destroy infrastructure
echo ""
echo "Destroying infrastructure..."
if [ -n "$VAR_FILE" ]; then
    terraform destroy -var-file="$VAR_FILE" -auto-approve
else
    terraform destroy -auto-approve
fi

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""

# Verify deletion
echo "Verifying resource deletion..."
RESOURCES=$(aws resourcegroupstaggingapi get-resources \
    --tag-filters Key=Project,Values=xml-json-converter \
    --query 'ResourceTagMappingList[*].ResourceARN' \
    --output text 2>/dev/null || echo "")

if [ -z "$RESOURCES" ]; then
    echo "✅ All resources successfully deleted"
else
    echo "⚠️  Warning: Some resources may still exist:"
    echo "$RESOURCES"
    echo ""
    echo "You may need to manually delete these resources from AWS Console."
fi

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Verify AWS costs in Billing Dashboard"
echo "2. Check for any remaining resources:"
echo "   aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=xml-json-converter"
echo ""

