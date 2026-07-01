variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "force_destroy" {
  type = bool
}

variable "ingest_expiration_days" {
  type = number
}

variable "processed_transition_days" {
  type = number
}
