output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.processed.id
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.processed.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.processed.domain_name
}

output "origin_access_control_id" {
  value = aws_cloudfront_origin_access_control.processed.id
}
