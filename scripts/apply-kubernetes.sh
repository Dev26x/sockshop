#!/bin/bash

# Navigate to the kubernetes directory from the scripts directory
cd "$(dirname "$0")/../kubernetes" || { echo "Kubernetes directory not found"; exit 1; }

# Install NGINX Ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Wait for the Ingress controller to get an external IP
kubectl get svc -n ingress-nginx

# Install Cert-Manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

# Wait for Cert-Manager to be fully deployed
echo "Waiting for Cert-Manager and its webhook to be ready..."
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=120s || { echo "Cert-Manager webhook is not ready"; exit 1; }

# Deploy microservices
kubectl apply -f deploy.yml

# Wait for services to be ready
sleep 60

# Apply ClusterIssuer
echo "Applying ClusterIssuer..."
kubectl apply -f clusterissuer.yml

# Verify ClusterIssuer Status
echo "Verifying ClusterIssuer status..."
kubectl wait --for=condition=Ready clusterissuer/letsencrypt-prod --timeout=120s || { echo "ClusterIssuer is not ready"; exit 1; }

# Apply the Ingress resource
kubectl apply -f ingress.yml

# Wait for Ingress to be ready
sleep 60

# Apply the certificate 
kubectl apply -f certificate.yml

# Verify the Ingress
kubectl get ingress -n sock-shop 
kubectl describe ingress socks-shop-ingress -n sock-shop

# Monitor Certificates
kubectl get certificates
kubectl describe certificate socks-shop-tls -n sock-shop  
