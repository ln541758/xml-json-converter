output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.xml_json_output.bucket
}

output "parser_image_url" {
  value = docker_registry_image.parser_push.name
}

output "load_balancer_dns" {
  value = kubernetes_service.parser_service.status[0].load_balancer[0].ingress[0].hostname
}