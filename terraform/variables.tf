variable "region" {
  default = "us-west-2"
}

variable "cluster_name" {
  default = "xml-json-experiment"
}

variable "node_count" {
  description = "Number of parser instances (1,2,4,8)"
  default     = 1
}

variable "node_max" {
  description = "Number of maximum parser instances (1,2,4,8)"
  default     = 1
}

variable "node_min" {
  description = "Number of minimum parser instances (1,2,4,8)"
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type for parser nodes"
  default     = "t3.medium"
}

variable "replica_count" {
  description = "Number of parser pods (used when HPA is disabled)"
  default     = 8
}

variable "container_port" {
  description = "Port of parser service"
  default     = 8080
}

# HPA Configuration for Experiment 2
variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_target_cpu_percent" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 70
}

variable "hpa_scale_up_stabilization" {
  description = "Stabilization window for scale-up in seconds"
  type        = number
  default     = 0
}

variable "hpa_scale_down_stabilization" {
  description = "Stabilization window for scale-down in seconds"
  type        = number
  default     = 300
}

# Resource requests and limits
variable "cpu_request" {
  description = "CPU request for each pod"
  type        = string
  default     = "500m"
}

variable "cpu_limit" {
  description = "CPU limit for each pod"
  type        = string
  default     = "1000m"
}

variable "memory_request" {
  description = "Memory request for each pod"
  type        = string
  default     = "512Mi"
}

variable "memory_limit" {
  description = "Memory limit for each pod"
  type        = string
  default     = "1Gi"
}