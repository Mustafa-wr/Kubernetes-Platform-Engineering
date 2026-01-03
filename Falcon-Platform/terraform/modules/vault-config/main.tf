terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# Enable the Key-Value (KV) Secret Engine
resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine for Falcon Platform"
}

# Create the Secret (The DB Password)
resource "vault_kv_secret_v2" "db_creds" {
  mount               = vault_mount.kv.path
  name                = "db-creds"
  cas                 = 1
  delete_all_versions = true
  
  data_json = jsonencode(
    {
      username = "db-user",
      password = var.db_password # Reference the variable 
    }
  )
}

# Create the Policy (Who can read what?)
resource "vault_policy" "internal_app" {
  name = "internal-app"

  policy = <<EOT
path "secret/data/db-creds" {
  capabilities = ["read"]
}
EOT
}

# Enable Kubernetes Authentication
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# Connect Vault to the Kubernetes API
# (In a real setup, Terraform fetches these from the AKS/EKS module outputs)
resource "vault_kubernetes_auth_backend_config" "config" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = var.token_reviewer_jwt
}

# Create the Role (The Bridge between K8s ServiceAccount and Vault Policy)
resource "vault_kubernetes_auth_backend_role" "backend" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "backend-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["team-backend"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.internal_app.name]
}