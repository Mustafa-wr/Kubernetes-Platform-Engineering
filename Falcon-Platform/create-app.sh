# this scripts creates a new app in the platform
#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Falcon Platform App Generator ===${NC}"
echo "This wizard will help you onboard your application to the cluster."
echo ""

# 1. Ask for Basic Info
read -p "Enter Application Name (e.g., payment-service): " APP_NAME
read -p "Enter Docker Image (e.g., ghcr.io/stefanprodan/podinfo:6.3.5): " APP_IMAGE
read -p "How many replicas? (default: 1): " APP_REPLICAS
APP_REPLICAS=${APP_REPLICAS:-1}

# Ask for the Team
echo ""
echo -e "${BLUE}--- Tenant Selection ---${NC}"
echo "Available Teams: backend, frontend (coming soon), data"
read -p "Which team owns this app? (default: backend): " TEAM_NAME
TEAM_NAME=${TEAM_NAME:-backend}
NAMESPACE="team-$TEAM_NAME"

# 2. Ask for Vault Integration
echo ""
echo -e "${BLUE}--- Security Configuration ---${NC}"
read -p "Does this app need database secrets from Vault? (y/n): " USE_VAULT

VAULT_BLOCK=""
if [[ "$USE_VAULT" == "y" || "$USE_VAULT" == "Y" ]]; then
    read -p "Enter Vault Role Name (e.g., backend-role): " VAULT_ROLE
    read -p "Enter Secret Path (e.g., secret/data/db-creds): " VAULT_PATH
    
    # Construct the annotations block
    VAULT_BLOCK=$(cat <<EOF
        podAnnotations:
          vault.hashicorp.com/agent-inject: "true"
          vault.hashicorp.com/role: "$VAULT_ROLE"
          vault.hashicorp.com/agent-inject-secret-config.txt: "$VAULT_PATH"
          vault.hashicorp.com/agent-inject-template-config.txt: |
            {{- with secret "$VAULT_PATH" -}}
            postgres://{{ .Data.data.username }}:{{ .Data.data.password }}@db-host:5432
            {{- end -}}
EOF
)
fi

# 3. Ask for Environment Variables
echo ""
echo -e "${BLUE}--- Environment Variables ---${NC}"
read -p "Do you want to add an Environment Variable? (y/n): " ADD_ENV

ENV_BLOCK=""
if [[ "$ADD_ENV" == "y" || "$ADD_ENV" == "Y" ]]; then
    echo "        env:" > /tmp/env_block.tmp # <--- FIXED
    while [[ "$ADD_ENV" == "y" || "$ADD_ENV" == "Y" ]]; do
        read -p "  Variable Name (e.g., FEATURE_X): " ENV_NAME
        read -p "  Value: " ENV_VALUE
        echo "          - name: $ENV_NAME" >> /tmp/env_block.tmp
        echo "            value: \"$ENV_VALUE\"" >> /tmp/env_block.tmp
        read -p "Add another? (y/n): " ADD_ENV
    done
    ENV_BLOCK=$(cat /tmp/env_block.tmp)
    rm /tmp/env_block.tmp
fi

# 4. Generate the YAML File
OUTPUT_FILE="gitops/apps/${APP_NAME}.yaml"

echo ""
echo -e "${GREEN}Generating manifest at $OUTPUT_FILE...${NC}"

cat > $OUTPUT_FILE <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/mustafa-wr/Kubernetes-Platform-Engineering.git
    path: Falcon-Platform/internal-charts/standard-service
    targetRevision: main
    helm:
      values: |
        replicaCount: $APP_REPLICAS
        image: $APP_IMAGE
        
$VAULT_BLOCK

$ENV_BLOCK

  destination:
    server: https://kubernetes.default.svc
    namespace: $NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo -e "${GREEN}Done!${NC}"
echo "Ready to deploy? Run: git add . && git commit -m 'feat: add $APP_NAME' && git push"