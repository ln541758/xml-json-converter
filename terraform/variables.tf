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
  description = "Number of parser pods"
  default     = 4
}

variable "container_port" {
  description = "Port of parser service"
  default     = 8080
}