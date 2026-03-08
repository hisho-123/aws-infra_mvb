output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "db_master_endpoint" {
  description = "The endpoint of the master database"
  value       = aws_db_instance.master.endpoint
}

output "db_replica_endpoint" {
  description = "The endpoint of the replica database"
  value       = aws_db_instance.replica.endpoint
}

# ========================================
# CI/CD 関連 Outputs
# ========================================

output "frontend_s3_bucket" {
  description = "フロントエンド静的ファイル用 S3 バケット名"
  value       = aws_s3_bucket.frontend.bucket
}

output "codedeploy_artifacts_bucket" {
  description = "CodeDeploy アーティファクト用 S3 バケット名"
  value       = aws_s3_bucket.codedeploy_artifacts.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront ディストリビューション ID (invalidation 用)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront ドメイン名"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "codedeploy_app_name" {
  description = "CodeDeploy アプリケーション名"
  value       = aws_codedeploy_app.backend.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy デプロイメントグループ名"
  value       = aws_codedeploy_deployment_group.backend.deployment_group_name
}

output "github_actions_backend_role_arn" {
  description = "GitHub Actions (backend repo) 用 IAM ロール ARN"
  value       = aws_iam_role.github_actions_backend.arn
}

output "github_actions_frontend_role_arn" {
  description = "GitHub Actions (frontend repo) 用 IAM ロール ARN"
  value       = aws_iam_role.github_actions_frontend.arn
}

output "acm_certificate_frontend_arn" {
  description = "CloudFront 用 ACM 証明書 ARN (us-east-1)"
  value       = aws_acm_certificate.frontend.arn
}
