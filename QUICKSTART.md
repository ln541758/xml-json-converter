# Quick Start

## Experiment 1: Horizontal Scaling (Already Completed ✅)

Fixed replicas (1, 2, 4, 8) with HTTP API + Locust testing

```bash
cd terraform
./deploy-experiment1.sh 4        # Deploy with 4 replicas
cd ../test
./run_load_test.sh http://$(cd ../terraform && terraform output -raw load_balancer_dns)
```

Results in `test/exp1/*.html`

---

## Experiment 2: Elasticity (SQS + HPA)

Auto-scaling (2-10 pods) with SQS burst testing

```bash
cd terraform
./deploy-experiment2.sh           # Deploy with HPA
cd ../test/exp2
./run-elasticity-test.sh          # Run burst test
```

### Monitor (separate terminals)

```bash
watch -n 5 kubectl get hpa        # HPA scaling
watch -n 5 kubectl get pods       # Pod count
watch -n 5 kubectl top pods       # CPU usage
```

Results in `test/exp2/*.csv`

---

## Cleanup

```bash
cd terraform
./cleanup.sh
```
