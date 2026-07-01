module "storage" {
  source = "./modules/storage"

  project_name              = var.project_name
  environment               = var.environment
  aws_account_id            = data.aws_caller_identity.current.account_id
  aws_region                = data.aws_region.current.name
  force_destroy             = var.force_destroy
  ingest_expiration_days    = var.ingest_expiration_days
  processed_transition_days = var.processed_transition_days
}

module "delivery" {
  source = "./modules/delivery"

  project_name                 = var.project_name
  environment                  = var.environment
  processed_bucket_name        = module.storage.processed_bucket_name
  processed_bucket_arn         = module.storage.processed_bucket_arn
  processed_bucket_domain_name = module.storage.processed_bucket_regional_domain_name
  cloudfront_price_class       = var.cloudfront_price_class
}
