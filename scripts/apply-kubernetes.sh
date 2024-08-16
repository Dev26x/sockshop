#!/bin/bash

set -e

# Navigate to the Kubernetes directory
cd "$(dirname "$0")/../kubernetes" || { echo "Kubernetes directory not found"; exit 1; }

aws eks update-kubeconfig --name "sock-shop" --region "us-east-1"

# Install NGINX Ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
if ! helm list -n ingress-nginx | grep -q nginx-ingress; then
    helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
else
    helm upgrade nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx
fi


# Install Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml

# Deploy microservices
kubectl apply -f deploy.yml


# Apply ClusterIssuer
kubectl apply -f clusterissuer.yml
sleep 10  # Give some time for the ClusterIssuer to be processed

# Apply the Ingress resource
kubectl apply -f ingress.yml

# Apply the certificate
kubectl apply -f certificate.yml
sleep 30  # Give some time for the certificate to be processed

# Final checks
echo "Ingress Status:"
kubectl get ingress -n sock-shop 
echo "Ingress Details:"
kubectl describe ingress socks-shop-ingress -n sock-shop
echo "Certificate Status:"
kubectl get certificates -n sock-shop
echo "Certificate Details:"
kubectl describe certificate socks-shop-tls -n sock-shop

echo "Kubernetes deployment completed successfully!"
