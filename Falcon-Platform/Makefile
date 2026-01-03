.PHONY: help azure-deploy azure-destroy kind-create kind-delete gitops-bootstrap gitops-deploy clean status create-app

SHELL := /bin/bash
KIND_CLUSTER_NAME := falcon-local
AZURE_RG := falcon-dev-rg
AZURE_CLUSTER := falcon-dev-aks
TF_DIR := terraform/environments/dev

help:
	@echo "Falcon Platform - Deployment Commands"
	@echo ""
	@echo "Azure (Production):"
	@echo "  make azure-deploy     Deploy AKS cluster with Terraform"
	@echo "  make azure-destroy    Destroy AKS cluster"
	@echo "  make azure-creds      Configure kubectl for AKS"
	@echo ""
	@echo "Local (Kind):"
	@echo "  make kind-create      Create local Kind cluster"
	@echo "  make kind-delete      Delete local Kind cluster"
	@echo ""
	@echo "GitOps:"
	@echo "  make gitops-bootstrap Install ArgoCD"
	@echo "  make gitops-deploy    Deploy root application (App of Apps)"
	@echo "  make argocd-password  Get ArgoCD admin password"
	@echo ""
	@echo "Platform:"
	@echo "  make create-app       Run app generator wizard"
	@echo "  make status           Show cluster and ArgoCD status"
	@echo ""
	@echo "Full Workflows:"
	@echo "  make local            Kind + ArgoCD + Apps (full local setup)"
	@echo "  make cloud            Azure + ArgoCD + Apps (full cloud setup)"

# =============================================================================
# Azure Deployment
# =============================================================================

azure-login:
	@if ! az account show > /dev/null 2>&1; then \
		echo "Logging into Azure..."; \
		az login; \
	else \
		echo "Already authenticated: $$(az account show --query user.name -o tsv)"; \
	fi

azure-deploy: azure-login
	@echo "Deploying Azure infrastructure..."
	@cd $(TF_DIR) && terraform init -upgrade
	@cd $(TF_DIR) && terraform apply -auto-approve -lock-timeout=5m
	@echo "Deployment complete."
	@$(MAKE) azure-creds

azure-destroy: azure-login
	@echo "Destroying Azure infrastructure..."
	@cd $(TF_DIR) && terraform destroy -auto-approve
	@echo "Infrastructure destroyed."

azure-creds:
	@echo "Configuring kubectl..."
	@az aks get-credentials --resource-group $(AZURE_RG) --name $(AZURE_CLUSTER) --overwrite-existing
	@kubectl get nodes

# =============================================================================
# Local Kind Cluster
# =============================================================================

kind-create:
	@echo "Creating Kind cluster..."
	@kind create cluster --name $(KIND_CLUSTER_NAME) --config kind-config.yaml --wait 60s
	@kubectl cluster-info --context kind-$(KIND_CLUSTER_NAME)
	@echo "Kind cluster ready."

kind-delete:
	@echo "Deleting Kind cluster..."
	@kind delete cluster --name $(KIND_CLUSTER_NAME)
	@echo "Cluster deleted."

# =============================================================================
# GitOps (ArgoCD)
# =============================================================================

gitops-bootstrap:
	@echo "Installing ArgoCD..."
	@helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
	@helm repo update
	@helm upgrade --install argocd argo/argo-cd \
		--namespace argocd \
		--create-namespace \
		--set server.service.type=NodePort \
		--set server.service.nodePortHttp=30080 \
		--set server.insecure=true \
		--wait
	@echo "ArgoCD installed."
	@$(MAKE) argocd-password

gitops-deploy:
	@echo "Deploying App of Apps..."
	@kubectl apply -f gitops/root.yaml
	@echo "Root application deployed. ArgoCD will sync all apps."

argocd-password:
	@echo "ArgoCD Credentials:"
	@echo "  URL:      http://localhost:30080"
	@echo "  Username: admin"
	@echo -n "  Password: " && kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo ""

# =============================================================================
# Platform Tools
# =============================================================================

create-app:
	@./create-app.sh

status:
	@echo "=== Cluster Nodes ==="
	@kubectl get nodes 2>/dev/null || echo "No cluster connected"
	@echo ""
	@echo "=== ArgoCD Applications ==="
	@kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not installed"
	@echo ""
	@echo "=== Pods (All Namespaces) ==="
	@kubectl get pods -A --field-selector=status.phase!=Running 2>/dev/null | head -20 || true

grafana-access:
	@echo "Starting Grafana port-forward..."
	@echo "Access: http://localhost:3000 (admin/admin)"
	@kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

vault-access:
	@echo "Starting Vault port-forward..."
	@echo "Access: http://localhost:8200 (token: root)"
	@kubectl port-forward svc/vault -n vault 8200:8200

# =============================================================================
# Full Workflows
# =============================================================================

local: kind-create gitops-bootstrap gitops-deploy
	@echo ""
	@echo "Local environment ready."
	@$(MAKE) status

cloud: azure-deploy gitops-bootstrap gitops-deploy
	@echo ""
	@echo "Cloud environment ready."
	@$(MAKE) status

clean: kind-delete
	@echo "Cleanup complete."
