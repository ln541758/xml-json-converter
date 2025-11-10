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
  name = "xml-json-parser"
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

# S3 bucket for results
resource "aws_s3_bucket" "xml_json_output" {
  bucket        = "${var.cluster_name}-${data.aws_caller_identity.current.account_id}-bucket"
  force_destroy = true
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
resource "kubernetes_deployment" "parser" {
  depends_on = [aws_eks_node_group.main, docker_registry_image.parser]
  
  metadata {
    name = "xml-json-parser"
    labels = {
      app = "parser"
    }
  }
  spec {
    replicas = var.replica_count
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
            name  = "S3_BUCKET_NAME"
            value = aws_s3_bucket.xml_json_output.bucket
          }
          env {
            name  = "AWS_REGION"
            value = var.region
          }
        }
      }
    }
  }
}

# Service to expose parser API
resource "kubernetes_service" "parser_service" {
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

