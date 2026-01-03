# Secrets Management

## Overview

HashiCorp Vault provides centralized secrets management with Kubernetes authentication.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Application   │     │     Vault       │
│      Pod        │────>│     Server      │
│                 │     │                 │
│ ┌─────────────┐ │     │ ┌─────────────┐ │
│ │Vault Agent  │ │     │ │   KV v2     │ │
│ │  Sidecar    │ │     │ │  Secrets    │ │
│ └─────────────┘ │     │ └─────────────┘ │
└─────────────────┘     └─────────────────┘
```

## Vault Installation

Deployed via ArgoCD in dev mode:

```yaml
# gitops/core/vault.yaml
source:
  repoURL: https://helm.releases.hashicorp.com
  chart: vault
  targetRevision: 0.28.0
  helm:
    values: |
      server:
        dev:
          enabled: true
      injector:
        enabled: true
```

## Access Vault

```bash
make vault-access
# http://localhost:8200
# Token: root
```

## Terraform Configuration

The `vault-config` module configures:

### Secrets Engine

```hcl
resource "vault_mount" "kv" {
  path = "secret"
  type = "kv"
  options = { version = "2" }
}
```

### Database Credentials

```hcl
resource "vault_kv_secret_v2" "db_creds" {
  mount = vault_mount.kv.path
  name  = "db-creds"
  data_json = jsonencode({
    username = "db-user"
    password = var.db_password
  })
}
```

### Access Policy

```hcl
resource "vault_policy" "internal_app" {
  name = "internal-app"
  policy = <<EOT
path "secret/data/db-creds" {
  capabilities = ["read"]
}
EOT
}
```

### Kubernetes Authentication

```hcl
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_role" "backend" {
  role_name                        = "backend-role"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["team-backend"]
  token_policies                   = ["internal-app"]
}
```

## Inject Secrets into Pods

Add annotations to enable Vault Agent injection:

```yaml
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "backend-role"
    vault.hashicorp.com/agent-inject-secret-config.txt: "secret/data/db-creds"
    vault.hashicorp.com/agent-inject-template-config.txt: |
      {{- with secret "secret/data/db-creds" -}}
      postgres://{{ .Data.data.username }}:{{ .Data.data.password }}@db-host:5432
      {{- end -}}
```

Secrets are written to `/vault/secrets/config.txt` inside the container.

## Application Generator Integration

The `create-app.sh` wizard prompts for Vault integration:

```
Does this app need database secrets from Vault? (y/n): y
Enter Vault Role Name (e.g., backend-role): backend-role
Enter Secret Path (e.g., secret/data/db-creds): secret/data/db-creds
```

Automatically generates the required annotations.

## Security Notes

- Dev mode is for demonstration only
- Production requires:
  - Persistent storage
  - Unseal keys management
  - TLS encryption
  - Audit logging
