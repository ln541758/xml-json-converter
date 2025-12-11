# Terraform Variables for Experiment 2: Elasticity Testing
# This configuration enables HPA (Horizontal Pod Autoscaler) to test auto-scaling behavior

# Basic cluster configuration
region       = "us-west-2"
cluster_name = "xml-json-exp2-elasticity"

# Node configuration for Experiment 2
# Using fewer nodes with HPA to allow for pod scaling within node capacity
node_count    = 3
node_min      = 2
node_max      = 5
instance_type = "t3.medium"

# HPA Configuration (Experiment 2 Specifications)
enable_hpa                   = true
hpa_min_replicas             = 2
hpa_max_replicas             = 10
hpa_target_cpu_percent       = 70
hpa_scale_up_stabilization   = 0   # Immediate scale-up
hpa_scale_down_stabilization = 300 # 5 minutes cooldown

# Resource requests and limits for accurate CPU-based scaling
cpu_request    = "500m"  # 500 millicores
cpu_limit      = "1000m" # 1 core
memory_request = "512Mi"
memory_limit   = "1Gi"

# Container configuration
container_port = 8080

# Note: replica_count is ignored when enable_hpa = true
# HPA will manage pod count between hpa_min_replicas and hpa_max_replicas

