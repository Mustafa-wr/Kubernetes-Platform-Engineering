# Architecture

## Overview

The Falcon Platform consists of two main layers:

1. **Infrastructure Layer** - Provisioned with Terraform
2. **GitOps Layer** - Managed with ArgoCD

## Infrastructure Layer (Terraform)

### Network Configuration

| Resource | CIDR |
|----------|------|
| VNet | 10.0.0.0/16 |
| System Subnet | 10.0.1.0/24 |
| User Subnet | 10.0.2.0/24 |
| Service CIDR | 172.16.0.0/16 |
| DNS Service IP | 172.16.0.10 |

### AKS Cluster

**System Node Pool:**
- Name: `system`
- VM Size: Standard_B2s
- Node Count: 1
- Purpose: Critical addons only (CoreDNS, metrics-server, kube-proxy)
- `only_critical_addons_enabled: true`

**User Node Pool (Spot):**
- Name: `userspot`
- VM Size: Standard_D2s_v3
- Node Count: 1-3 (autoscaling)
- Priority: Spot instances
- Taint: `kubernetes.azure.com/scalesetpriority=spot:NoSchedule`

### Network Profile

```
Network Plugin: Azure CNI
Network Policy: Calico
Load Balancer: Standard SKU
```

### Terraform Modules

| Module | Path | Purpose |
|--------|------|---------|
| network | `modules/network/` | VNet and subnet creation |
| aks | `modules/aks/` | AKS cluster and node pools |
| vault-config | `modules/vault-config/` | Vault secrets and Kubernetes auth |

## GitOps Layer (ArgoCD)

### App of Apps Pattern

```
root.yaml (Entry Point)
    │
    ├── core.yaml ──────────> system.yaml, dashboard.yaml, vault.yaml
    ├── ingress-nginx.yaml
    ├── kyverno.yaml
    ├── monitoring.yaml
    ├── policies.yaml ──────> disallow-root.yaml, disallow-latest-tag.yaml
    ├── tenants.yaml ───────> backend.yaml
    ├── backend-api.yaml
    ├── backend-db.yaml
    ├── podinfo.yaml
    └── guest.yaml
```

### Directory Structure

```
gitops/
├── root.yaml           # App of Apps entry point
├── apps/               # ArgoCD Application manifests
├── core/               # Platform infrastructure resources
├── policies/           # Kyverno ClusterPolicies
└── tenants/            # Tenant namespace configurations
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VNet (10.0.0.0/16)                      │  │
│  │  ┌─────────────────┐  ┌─────────────────────────────────┐ │  │
│  │  │  System Subnet  │  │         User Subnet             │ │  │
│  │  │  (10.0.1.0/24)  │  │        (10.0.2.0/24)            │ │  │
│  │  │                 │  │                                  │ │  │
│  │  │  ┌───────────┐  │  │  ┌───────────┐ ┌───────────┐   │ │  │
│  │  │  │  System   │  │  │  │   Spot    │ │   Spot    │   │ │  │
│  │  │  │   Node    │  │  │  │  Node 1   │ │  Node 2   │   │ │  │
│  │  │  │           │  │  │  │           │ │           │   │ │  │
│  │  │  │ - CoreDNS │  │  │  │ - Apps    │ │ - Apps    │   │ │  │
│  │  │  │ - Metrics │  │  │  │ - Ingress │ │ - Vault   │   │ │  │
│  │  │  │           │  │  │  │ - Kyverno │ │ - Grafana │   │ │  │
│  │  │  └───────────┘  │  │  └───────────┘ └───────────┘   │ │  │
│  │  └─────────────────┘  └─────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Sync Strategy

All ArgoCD applications use:
- **Automated Sync**: Changes from Git applied automatically
- **Self-Heal**: Manual cluster changes reverted
- **Auto-Prune**: Deleted resources removed from cluster
- **CreateNamespace**: Namespaces created automatically
