#!/bin/bash

set -e

# Navigate to the Kubernetes directory from the scripts directory
cd "$(dirname "$0")/../kubernetes" || { echo "Kubernetes directory not found"; exit 1; }

# Install NGINX Ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
if helm list --namespace ingress-nginx | grep -q nginx-ingress; then
  echo "NGINX Ingress controller already installed. Uninstalling it first."
  helm uninstall nginx-ingress --namespace ingress-nginx
  sleep 30
fi
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Wait for the Ingress controller to get an external IP
echo "Waiting for the Ingress controller to get an external IP..."
while ! kubectl get svc -n ingress-nginx | grep -q 'EXTERNAL-IP'; do
  sleep 10
done

# Install Cert-Manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
echo "Waiting for Cert-Manager to be fully deployed..."
sleep 180

# Check Cert-Manager status
kubectl get pods -n cert-manager
kubectl get svc -n cert-manager

# Deploy microservices
kubectl apply -f deploy.yml

# Wait for services to be ready
echo "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment -n sock-shop

# Apply ClusterIssuer
kubectl apply -f clusterissuer.yml

# Verify ClusterIssuer
echo "Verifying ClusterIssuer status..."
kubectl describe clusterissuer letsencrypt-prod

# Apply the Ingress resource
kubectl apply -f ingress.yml

# Wait for Ingress to be ready
echo "Waiting for Ingress to be ready..."
kubectl wait --for=condition=ready --timeout=120s ingress -n sock-shop

# Apply the certificate
kubectl apply -f certificate.yml

# Verify Certificate
echo "Verifying Certificate status..."
kubectl get certificates
kubectl describe certificate socks-shop-tls -n sock-shop

# Final checks
kubectl get ingress -n sock-shop 
kubectl describe ingress socks-shop-ingress -n sock-shop
