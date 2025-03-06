variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "stockholm_webhook_url" {
  description = "Discord webhook URL for Stockholm jobs"
  type        = string
  sensitive   = true
}

variable "oslo_webhook_url" {
  description = "Discord webhook URL for Oslo jobs"
  type        = string
  sensitive   = true
}