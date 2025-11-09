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
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# ECR login for Docker provider
provider "docker" {
  registry_auth {
    address  = "${aws_ecr_repository.parser_repo.repository_url}"
    username = "AWS"
    password = data.aws_ecr_authorization_token.ecr_auth.authorization_token
  }
}

data "aws_ecr_authorization_token" "ecr_auth" {}

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

# EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  vpc_id          = data.aws_vpc.default.id
  subnet_ids      = data.aws_subnets.default.ids

  iam_role_arn    = "arn:aws:iam::533267314891:role/c169671a4380641l11480718t1w533267-LabEksClusterRole-pWgqHzcPNGLI"
  create_iam_role = false

  eks_managed_node_groups = {
    default = {
      desired_size   = var.node_count
      max_size       = var.node_max
      min_size       = var.node_min
      instance_types = [var.instance_type]

      iam_role_arn = "arn:aws:iam::533267314891:role/c169671a4380641l11480718t1w533267-LabEksNodeRole-gXoz4U7aOk8"
    }
  }

  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# S3 bucket for results
resource "aws_s3_bucket" "xml_json_output" {
  bucket        = "${var.cluster_name}-bucket"
  force_destroy = true
  tags = {
    Project = "xml-json-converter"
    Env     = "experiment"
  }
}

# build and push docker image
resource "docker_image" "parser" {
  name = "${aws_ecr_repository.parser_repo.repository_url}:latest"

  build {
    context    = "../../xml-json-converter"
    dockerfile = "../../xml-json-converter/Dockerfile"
    tag        = ["${aws_ecr_repository.parser_repo.repository_url}:latest"]
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("../../xml-json-converter", "**") : filesha1("../../xml-json-converter/${f}")]))
  }
}

resource "docker_registry_image" "parser_push" {
  name          = docker_image.parser.name
  keep_remotely = true
  triggers = {
    image_id = docker_image.parser.image_id
  }
}

# Kubernetes provider for deployment
data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}


# Deploy parser on EKS
resource "kubernetes_deployment" "parser" {
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
          image = docker_registry_image.parser_push.name   # Auto-pulled from ECR
          port {
            container_port = var.container_port
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

