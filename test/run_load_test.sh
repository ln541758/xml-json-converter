#!/bin/bash

# Load test runner for XML-JSON converter
# This script runs a Locust load test with 100 concurrent users

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}XML-JSON Converter Load Test${NC}"
echo "================================"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if locust is installed
if ! command -v locust &> /dev/null; then
    echo -e "${YELLOW}Locust is not installed. Installing...${NC}"
    pip install -r "$SCRIPT_DIR/requirements.txt"
fi

# Default values
HOST=${1:-http://localhost:8080}
USERS=${2:-100}
SPAWN_RATE=${3:-100}
RUN_TIME=${4:-60s}

echo "Configuration:"
echo "  Host: $HOST"
echo "  Users: $USERS"
echo "  Spawn Rate: $SPAWN_RATE users/sec"
echo "  Run Time: $RUN_TIME"
echo "================================"
echo ""

# Run the load test
cd "$SCRIPT_DIR"
locust -f locustfile.py \
    --host="$HOST" \
    --users="$USERS" \
    --spawn-rate="$SPAWN_RATE" \
    --run-time="$RUN_TIME" \
    --headless \
    --html=load_test_report.html \
    --csv=load_test_results

echo ""
echo -e "${GREEN}Load test completed!${NC}"
echo "Results saved to:"
echo "  - $SCRIPT_DIR/load_test_report.html (detailed HTML report)"
echo "  - $SCRIPT_DIR/load_test_results_*.csv (CSV data)"

