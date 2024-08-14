#!/bin/bash

# Navigate to the kubernetes directory
cd ../kubernetes 

# Directory containing Kubernetes manifests
K8S_DIR="../kubernetes"

# Delete Ingress configuration
echo "Deleting Ingress configuration..."
kubectl delete -f "$K8S_DIR/ingress.yml"

# Delete application deployment
echo "Deleting application deployment..."
kubectl delete -f "$K8S_DIR/deploy.yml"

# Delete Let's Encrypt Cert Manager configuration
echo "Deleting Let's Encrypt Cert Manager configuration..."
kubectl delete -f "$K8S_DIR/cert-manager.yml"

# Delete Cert Manager
echo "Deleting Cert Manager..."
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.12.1/cert-manager.yaml

# Delete Cert Manager CRDs
echo "Deleting Cert Manager CRDs..."
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.12.1/cert-manager.crds.yaml

# Delete Ingress Controller
echo "Deleting NGINX Ingress Controller..."
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

echo "Rollback completed successfully!"
