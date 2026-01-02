#!/bin/bash
set -e

echo " Bootstrapping ArgoCD..."

# 1. Add ArgoCD Helm Repo
echo "Adding Helm Repo..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 2. Install ArgoCD (High Availability mode disabled for cost saving)
echo "Installing ArgoCD Chart..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=LoadBalancer \
  --set server.insecure=true \
  --wait

echo "ArgoCD Installed!"

# 3. Get the Password
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq -r .status.loadBalancer.ingress[0].ip)

echo ""
echo "Access Details:"
echo "URL:      http://$ARGOCD_SERVER"
echo "User:     admin"
echo "Password: $ADMIN_PASSWORD"