# Kubernetes RBAC Security

User authentication and role-based access control implementation.

## Overview

| File | Purpose |
|------|---------|
| `onborad-new-user.sh` | Creates user certificate and kubeconfig with CSR approval |
| `rbac-developer.yaml` | Defines Role and RoleBinding for junior developer access |

## Setup

```bash
vagrant up
vagrant ssh kube-control-plane
```

The Vagrantfile provisions a control-plane node with kubectl configured.

## User Onboarding

```bash
sudo ./onborad-new-user.sh
```

Process:
1. Generates private key for user "jane"
2. Creates Certificate Signing Request (CSR) with CN=jane, O=developers
3. Submits CSR to Kubernetes API
4. Approves CSR automatically
5. Retrieves signed certificate
6. Configures kubeconfig with new credentials

Output: `jane.key`, `jane.crt`, and kubeconfig context `jane-context`

## RBAC Configuration

```bash
kubectl apply -f rbac-developer.yaml
```

Permissions granted to user "jane" in default namespace:
- View: pods, services, configmaps, deployments, statefulsets
- Execute: pod logs, exec, port-forward
- Deny: secrets, delete operations, scaling

## Testing

```bash
# Should succeed
kubectl --context=jane-context get pods

# Should fail (forbidden)
kubectl --context=jane-context get secrets
kubectl --context=jane-context delete pod <pod-name>
```

## Requirements

- Kubernetes cluster with certificate API enabled
- kubectl with admin access
- OpenSSL for certificate generation
