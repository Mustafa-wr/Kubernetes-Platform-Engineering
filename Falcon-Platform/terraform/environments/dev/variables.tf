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
  sensitive   = true
}

variable "vault_db_password" {
  type        = string
  description = "Password to inject into Vault for the DB"
  sensitive   = true
}