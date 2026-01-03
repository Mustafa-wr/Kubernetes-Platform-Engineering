variable "kubernetes_host" {
  type        = string
  description = "The API URL of the Kubernetes cluster (e.g., https://10.0.0.1:443)"
}

variable "kubernetes_ca_cert" {
  type        = string
  description = "The CA Certificate of the Kubernetes cluster"
}

variable "token_reviewer_jwt" {
  type        = string
  sensitive   = true
  description = "The JWT token for Vault to authenticate with K8s"
}

variable "db_password" {
  type        = string
  description = "The password for the database user. DO NOT SET DEFAULT."
  sensitive   = true
}