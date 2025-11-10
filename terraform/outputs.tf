output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.xml_json_output.bucket
}

output "parser_image_url" {
  value = docker_registry_image.parser.name
}

output "load_balancer_dns" {
  value = kubernetes_service.parser_service.status[0].load_balancer[0].ingress[0].hostname
}