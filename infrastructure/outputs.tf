output "aws_account_id" {
  description = "AWS account ID used to derive globally unique bucket names."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region used for regional resources."
  value       = data.aws_region.current.name
}

output "ingest_bucket_name" {
  description = "Private bucket used for temporary media ingestion."
  value       = module.storage.ingest_bucket_name
}

output "processed_bucket_name" {
  description = "Private bucket used as the CloudFront content origin."
  value       = module.storage.processed_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution identifier."
  value       = module.delivery.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Development CloudFront domain used to validate private-origin delivery."
  value       = module.delivery.cloudfront_domain_name
}

output "cloudfront_url" {
  description = "HTTPS base URL for the development CloudFront distribution."
  value       = "https://${module.delivery.cloudfront_domain_name}"
}
