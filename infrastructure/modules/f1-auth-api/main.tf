variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "media-platform"
}

locals {
  name = "${var.project_name}-${var.environment}-f1"
}

# F1: Authentication and Application API
# Services intended:
# - Amazon Cognito (user auth)
# - API Gateway (REST/WebSocket)
# - AWS Lambda (backend logic)
# - DynamoDB (metadata/session store)
# - AWS WAF association

# TODO:
# - Cognito User Pool
# - API Gateway routes
# - Lambda handlers
# - IAM roles (least privilege)
# - JWT authorizer integration

output "module_status" {
  value = "F1-auth-api scaffold created"
}
