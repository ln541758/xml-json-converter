terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ECR authentication for Docker provider
data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = split("/", aws_ecr_repository.parser_repo.repository_url)[0]
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ECR
resource "aws_ecr_repository" "parser_repo" {
  name                 = "xml-json-parser"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Project = "xml-json-converter"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EKS cluster - using direct resources for AWS Lab compatibility
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = "1.29"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "xml-json-parser-nodes"
  node_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = var.node_count
    max_size     = var.node_max
    min_size     = var.node_min
  }

  instance_types = [var.instance_type]

  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# S3 buckets
resource "aws_s3_bucket" "xml_input" {
  bucket        = "${var.cluster_name}-${data.aws_caller_identity.current.account_id}-input"
  force_destroy = true
  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

resource "aws_s3_bucket" "xml_json_output" {
  bucket        = "${var.cluster_name}-${data.aws_caller_identity.current.account_id}-output"
  force_destroy = true
  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# SQS Dead Letter Queue
resource "aws_sqs_queue" "parser_dlq" {
  name = "${var.cluster_name}-dlq"
  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# SQS Main Queue
resource "aws_sqs_queue" "parser_queue" {
  name                       = "${var.cluster_name}-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 20      # Enable long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.parser_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# Build the Docker image
resource "docker_image" "parser" {
  name = "${aws_ecr_repository.parser_repo.repository_url}:latest"

  build {
    context    = "${path.module}/.."
    dockerfile = "Dockerfile"
  }

  # Force rebuild on every terraform apply
  triggers = {
    always_run = timestamp()
  }
}

# Push the image to ECR
resource "docker_registry_image" "parser" {
  name = docker_image.parser.name

  # Keep old images in ECR (don't delete on destroy)
  keep_remotely = true

  # Force push on every apply to ensure latest image is in ECR
  triggers = {
    image_id = docker_image.parser.image_id
  }
}

# Kubernetes provider for deployment
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}


# Deploy parser on EKS
resource "kubernetes_deployment_v1" "parser" {
  depends_on = [aws_eks_node_group.main, docker_registry_image.parser]

  metadata {
    name = "xml-json-parser"
    labels = {
      app = "parser"
    }
  }
  spec {
    replicas = var.enable_hpa ? var.hpa_min_replicas : var.replica_count
    selector {
      match_labels = {
        app = "parser"
      }
    }
    template {
      metadata {
        labels = {
          app = "parser"
        }
      }
      spec {
        container {
          name  = "parser"
          image = "${aws_ecr_repository.parser_repo.repository_url}:latest"
          # Always pull the latest image from ECR
          image_pull_policy = "Always"
          port {
            container_port = var.container_port
          }
          env {
            name  = "SQS_QUEUE_URL"
            value = aws_sqs_queue.parser_queue.url
          }
          env {
            name  = "S3_INPUT_BUCKET_NAME"
            value = aws_s3_bucket.xml_input.bucket
          }
          env {
            name  = "S3_OUTPUT_BUCKET_NAME"
            value = aws_s3_bucket.xml_json_output.bucket
          }
          env {
            name  = "AWS_REGION"
            value = var.region
          }
          # Resource requests and limits for HPA
          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
        }
      }
    }
  }
}

# Service to expose parser API
resource "kubernetes_service_v1" "parser_service" {
  metadata {
    name = "xml-json-parser-service"
  }
  spec {
    selector = {
      app = "parser"
    }
    port {
      port        = 80
      target_port = var.container_port
    }
    type = "LoadBalancer"
  }
}

# Horizontal Pod Autoscaler for Experiment 2
resource "kubernetes_horizontal_pod_autoscaler_v2" "parser_hpa" {
  count      = var.enable_hpa ? 1 : 0
  depends_on = [kubernetes_deployment_v1.parser]

  metadata {
    name = "xml-json-parser-hpa"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.parser.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    # CPU-based scaling
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_target_cpu_percent
        }
      }
    }

    # Scaling behavior
    behavior {
      scale_up {
        stabilization_window_seconds = var.hpa_scale_up_stabilization
        select_policy                = "Max"
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 15
        }
        policy {
          type           = "Pods"
          value          = 2
          period_seconds = 15
        }
      }
      scale_down {
        stabilization_window_seconds = var.hpa_scale_down_stabilization
        select_policy                = "Min"
        policy {
          type           = "Percent"
          value          = 50
          period_seconds = 60
        }
      }
    }
  }
}

# Metrics Server (required for HPA)
resource "helm_release" "metrics_server" {
  count      = var.enable_hpa ? 1 : 0
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }
}

# prometheus
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"

  create_namespace = true

  set {
    name  = "server.persistentVolume.enabled"
    value = "false"
  }

  set {
    name  = "alertmanager.enabled"
    value = "false"
  }
}

