# Terraform Infrastructure

## Two Experiment Configurations

### Experiment 1: Horizontal Scaling (HTTP-based)
Fixed replicas (1, 2, 4, 8 pods) - Already completed ✅

```bash
./deploy-experiment1.sh 4   # Deploy with 4 replicas
```

Uses HTTP API + LoadBalancer + Locust testing

### Experiment 2: Elasticity (SQS-based)
HPA auto-scaling (2-10 pods)

```bash
./deploy-experiment2.sh     # Deploy with HPA
```

Uses SQS queue + worker pods + burst testing

## Cleanup

```bash
./cleanup.sh
```

## Monitor

```bash
kubectl get hpa -w          # HPA (Exp 2 only)
kubectl get pods -w         # Pods
kubectl top pods            # CPU usage
```

## Infrastructure

Both experiments create:
- EKS cluster
- SQS queue + DLQ  
- S3 buckets (input + output)
- ECR repository
- Prometheus

Experiment 2 additionally creates:
- HPA resource
- Metrics Server


