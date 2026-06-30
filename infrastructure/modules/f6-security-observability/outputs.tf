output "boundary_arn" {
  description = "IAM boundary policy ARN"
  value       = aws_iam_policy.permissions_boundary.arn
}

output "waf_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.regional.arn
}
