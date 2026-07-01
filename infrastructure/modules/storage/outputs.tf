output "ingest_bucket_name" {
  value = aws_s3_bucket.ingest.id
}

output "ingest_bucket_arn" {
  value = aws_s3_bucket.ingest.arn
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed.id
}

output "processed_bucket_arn" {
  value = aws_s3_bucket.processed.arn
}

output "processed_bucket_regional_domain_name" {
  value = aws_s3_bucket.processed.bucket_regional_domain_name
}
