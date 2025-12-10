output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "s3_input_bucket" {
  value = aws_s3_bucket.xml_input.bucket
}

output "s3_output_bucket" {
  value = aws_s3_bucket.xml_json_output.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.parser_queue.url
}

output "sqs_dlq_url" {
  value = aws_sqs_queue.parser_dlq.url
}

output "parser_image_url" {
  value = docker_registry_image.parser.name
}

output "load_balancer_dns" {
  value = kubernetes_service_v1.parser_service.status[0].load_balancer[0].ingress[0].hostname
}

output "hpa_enabled" {
  value       = var.enable_hpa
  description = "Whether HPA is enabled"
}

output "hpa_configuration" {
  value = var.enable_hpa ? {
    min_replicas             = var.hpa_min_replicas
    max_replicas             = var.hpa_max_replicas
    target_cpu_percent       = var.hpa_target_cpu_percent
    scale_up_stabilization   = var.hpa_scale_up_stabilization
    scale_down_stabilization = var.hpa_scale_down_stabilization
  } : null
  description = "HPA configuration details"
}