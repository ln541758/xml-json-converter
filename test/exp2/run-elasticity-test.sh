#!/bin/bash

# Experiment 2: Elasticity Test
# Tests HPA auto-scaling with burst load

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Experiment 2: Elasticity Test"
echo "=========================================="
echo ""
echo "Test Phases:"
echo "  Phase 1: Baseline (10 msg/sec for 30s)"
echo "  Phase 2: Medium (100 msg/sec for 60s)" 
echo "  Phase 3: Burst (1000 msg/sec for 60s)"
echo "  Phase 4: Scale-down (10 msg/sec for 180s)"
echo ""

# Get infrastructure info
cd "$SCRIPT_DIR/../../terraform"
SQS_URL=$(terraform output -raw sqs_queue_url 2>/dev/null)
INPUT_BUCKET=$(terraform output -raw s3_input_bucket 2>/dev/null)

if [ -z "$SQS_URL" ]; then
    echo "❌ Error: Could not get SQS URL. Is infrastructure deployed?"
    echo "Run: cd terraform && ./deploy-experiment2.sh"
    exit 1
fi

# Check HPA is enabled
HPA_ENABLED=$(terraform output -raw hpa_enabled 2>/dev/null)
if [ "$HPA_ENABLED" != "true" ]; then
    echo "❌ Error: HPA not enabled. Use experiment2 configuration."
    exit 1
fi

echo "Infrastructure:"
echo "  SQS Queue: $SQS_URL"
echo "  Input Bucket: $INPUT_BUCKET"
echo "  HPA: ENABLED"
echo ""

# Prepare test data
echo "Preparing test XML files..."
cd "$SCRIPT_DIR/../../sample"
if [ ! -f "test.xml" ]; then
    echo "❌ Error: test.xml not found"
    exit 1
fi

# Upload sample file to S3
aws s3 cp test.xml s3://$INPUT_BUCKET/test.xml
echo "✅ Test file uploaded to S3"
echo ""

# Results file
RESULTS_FILE="$SCRIPT_DIR/elasticity-test-$(date +%Y%m%d-%H%M%S).csv"
echo "Timestamp,Phase,QueueDepth,PodCount,AvgCPU,MessagesProcessed" > "$RESULTS_FILE"

# Monitoring function
monitor_hpa() {
    local phase=$1
    local duration=$2
    local start_time=$(date +%s)
    
    echo "[$phase] Monitoring for ${duration}s..."
    
    while true; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $duration ]; then
            break
        fi
        
        # Get metrics
        queue_depth=$(aws sqs get-queue-attributes \
            --queue-url "$SQS_URL" \
            --attribute-names ApproximateNumberOfMessages \
            --query 'Attributes.ApproximateNumberOfMessages' \
            --output text)
        
        pod_count=$(kubectl get hpa xml-json-parser-hpa -o jsonpath='{.status.currentReplicas}' 2>/dev/null || echo "0")
        avg_cpu=$(kubectl get hpa xml-json-parser-hpa -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null || echo "0")
        
        # Log
        echo "$current_time,$phase,$queue_depth,$pod_count,$avg_cpu,$elapsed" >> "$RESULTS_FILE"
        echo "[$(date +%H:%M:%S)] $phase | Queue: $queue_depth | Pods: $pod_count | CPU: ${avg_cpu}%"
        
        sleep 5
    done
}

# Send messages at rate using batched API calls
send_messages_at_rate() {
    local rate=$1  # messages per second
    local duration=$2  # seconds
    local total_messages=$((rate * duration))
    local batch_size=10  # SQS batch limit
    local num_batches=$((total_messages / batch_size))
    
    # Keep concurrency reasonable to avoid overwhelming the system
    # Even for burst, we don't need massive parallelism - SQS can handle the queue
    local max_concurrent=30  # Safe default that won't kill your computer
    
    echo "Sending $total_messages messages in $num_batches batches at ${rate} msg/sec for ${duration}s..."
    echo "Concurrency: $max_concurrent concurrent batches"
    
    local batch_count=0
    local start_time=$(date +%s)
    
    for i in $(seq 1 $num_batches); do
        # Progress indicator (less frequent to not interfere with monitoring)
        if [ $((i % 1000)) -eq 0 ]; then
            echo "  [SEND] Progress: $i / $num_batches batches sent..."
        fi
        # Build batch entries (10 messages per batch)
        local entries=""
        for j in $(seq 0 9); do
            local msg_id="msg-$(date +%s%N)-$i-$j"
            if [ -z "$entries" ]; then
                entries="Id=$msg_id,MessageBody=test.xml"
            else
                entries="$entries Id=$msg_id,MessageBody=test.xml"
            fi
        done
        
        # Send batch in background
        aws sqs send-message-batch \
            --queue-url "$SQS_URL" \
            --entries $entries \
            --output text > /dev/null 2>&1 &
        
        batch_count=$((batch_count + 1))
        
        # Wait after every max_concurrent batches to limit parallelism
        if [ $((batch_count % max_concurrent)) -eq 0 ]; then
            wait  # Wait for current batch to finish
            
            # Only enforce rate limiting for low-rate phases (baseline/scale-down)
            if [ $rate -lt 50 ]; then
                local messages_sent=$((i * batch_size))
                local elapsed=$(($(date +%s) - start_time))
                local expected_time=$((messages_sent / rate))
                
                if [ $elapsed -lt $expected_time ]; then
                    local sleep_time=$((expected_time - elapsed))
                    if [ $sleep_time -gt 0 ]; then
                        sleep $sleep_time
                    fi
                fi
            fi
        fi
    done
    
    wait  # Wait for remaining batches
    echo "✅ Sent $total_messages messages ($num_batches batches)"
}

# Start test
echo "=========================================="
echo "Starting Elasticity Test"
echo "=========================================="
echo ""

# Check initial state
echo "Initial HPA status:"
kubectl get hpa xml-json-parser-hpa
echo ""

read -p "Press Enter to start Phase 1 (Baseline)..."

# Phase 1: Baseline
echo ""
echo "Phase 1: Baseline Load"
send_messages_at_rate 10 30 &
SEND_PID=$!
monitor_hpa "Baseline" 30
wait $SEND_PID

sleep 10

# Phase 2: Medium
read -p "Press Enter to start Phase 2 (Medium Load)..."
echo ""
echo "Phase 2: Medium Load"
send_messages_at_rate 100 60 &
SEND_PID=$!
monitor_hpa "Medium" 60
wait $SEND_PID

sleep 10

# Phase 3: Burst
read -p "Press Enter to start Phase 3 (BURST)..."
echo ""
echo "Phase 3: BURST LOAD"
send_messages_at_rate 1000 60 &
SEND_PID=$!
monitor_hpa "Burst" 60
wait $SEND_PID

sleep 10

# Phase 4: Scale-down
read -p "Press Enter to start Phase 4 (Scale-down)..."
echo ""
echo "Phase 4: Scale-down Observation"
send_messages_at_rate 10 180 &
SEND_PID=$!
monitor_hpa "ScaleDown" 180
wait $SEND_PID

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""
echo "View HPA events:"
echo "  kubectl describe hpa xml-json-parser-hpa"
echo ""
echo "Export Prometheus data:"
echo "  kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
echo ""

