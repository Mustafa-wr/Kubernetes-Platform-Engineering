#!/bin/bash
set -e

USERNAME="jane" # dummy username
GROUP="developers"

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

echo "Starting onboarding for user: $USERNAME"

# 1. Create Private Key
openssl genrsa -out $USERNAME.key 2048

# 2. Create Certificate Signing Request (CN=username, O=group)
openssl req -new -key $USERNAME.key -out $USERNAME.csr -subj "/CN=$USERNAME/O=$GROUP"

# 3. Send CSR to Kubernetes API
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $USERNAME
spec:
  request: $(cat $USERNAME.csr | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF

echo "⏳ Waiting for Admin approval (simulating approval)..."
kubectl certificate approve $USERNAME

# 4. Retrieve the Signed Certificate
kubectl get csr $USERNAME -o jsonpath='{.status.certificate}'| base64 -d > $USERNAME.crt

# 5. Generate Kubeconfig for the user
kubectl config set-credentials $USERNAME \
    --client-certificate=$USERNAME.crt \
    --client-key=$USERNAME.key \
    --embed-certs=true

kubectl config set-context $USERNAME-context \
    --cluster=kubernetes \
    --namespace=default \
    --user=$USERNAME

echo "✅ User $USERNAME created!"
echo "➡️  Test access: kubectl --context=$USERNAME-context get pods"
echo "➡️  Test denial: kubectl --context=$USERNAME-context get secrets"