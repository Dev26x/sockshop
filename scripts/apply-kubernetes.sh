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
sleep 180

# Deploy microservices
kubectl apply -f deploy.yml

# Wait for services to be ready
sleep 60

# Apply ClusterIssuer
kubectl apply -f clusterissuer.yml

# Apply the Ingress resource
kubectl apply -f ingress.yml

# Wait for Ingress to be ready
sleep 60

# Apply the certificate 
kubectl apply -f certificate.yml

#Verify ClusterIssuer Status
sleep 120
kubectl describe clusterissuer letsencrypt-prod

#Check Ingress
sleep 60

kubectl get ingress -n sock-shop 

kubectl describe ingress socks-shop-ingress -n sock-shop

#Monitor Certificates
kubectl get certificates

kubectl describe certificate socks-shop-tls -n sock-shop  




