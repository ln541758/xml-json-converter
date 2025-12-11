# Terraform Variables for Experiment 1: Horizontal Scaling Performance
# This configuration uses fixed replica counts to test linear scaling

# Basic cluster configuration
region       = "us-west-2"
cluster_name = "xml-json-exp1-scaling"

# Node configuration for Experiment 1
node_count    = 8
node_min      = 1
node_max      = 8
instance_type = "t3.medium"

# Disable HPA for Experiment 1 (testing fixed replica counts)
enable_hpa    = false
replica_count = 8 # Change this to 1, 2, 4, or 8 for different test runs

# Resource configuration (not critical without HPA, but good practice)
cpu_request    = "500m"
cpu_limit      = "1000m"
memory_request = "512Mi"
memory_limit   = "1Gi"

# Container configuration
container_port = 8080




