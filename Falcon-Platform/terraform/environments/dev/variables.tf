variable "location" {
  description = "The Azure Region to deploy resources"
  type        = string
  default     = "uaenorth" # UAE for latency
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "falcon"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true # Hides it from output logs
}