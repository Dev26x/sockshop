#!/bin/bash

# Navigate to the kubernetes directory from the scripts directory
cd "$(dirname "$0")/../kubernetes" || { echo "Kubernetes directory not found"; exit 1; }

# Install NGINX Ingress controller
echo "Installing NGINX Ingress controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Check if NGINX Ingress is already installed
if ! helm list -n ingress-nginx | grep -q nginx-ingress; then
    helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace || { echo "NGINX Ingress installation failed"; exit 1; }
else
    echo "NGINX Ingress controller already installed."
fi

# Wait for the Ingress controller to get an external IP
echo "Waiting for NGINX Ingress controller to get an external IP..."

# List services in the ingress-nginx namespace and check their status
echo "Listing services in the ingress-nginx namespace..."
kubectl get svc -n ingress-nginx || { echo "Failed to retrieve services"; exit 1; }

# Retrieve service name
SERVICE_NAME=$(kubectl get svc -n ingress-nginx -o jsonpath='{.items[?(@.metadata.name == "nginx-ingress-controller")].metadata.name}' || { echo "Failed to retrieve service name"; exit 1; })

if [ -z "$SERVICE_NAME" ]; then
    echo "No services with name 'nginx-ingress-controller' found in the ingress-nginx namespace"
    exit 1
fi

echo "Using service name: $SERVICE_NAME"
# Wait for the service to have an external IP
kubectl wait --for=condition=loadBalancer --timeout=300s svc/$SERVICE_NAME -n ingress-nginx || { echo "NGINX Ingress service did not get an external IP in time"; exit 1; }

# Install Cert-Manager
echo "Installing Cert-Manager..."
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml || { echo "Cert-Manager installation failed"; exit 1; }

# Wait for Cert-Manager components to be fully deployed
echo "Waiting for Cert-Manager components to be fully deployed..."
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=300s || { echo "Cert-Manager deployment did not complete in time"; exit 1; }
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=300s || { echo "Cert-Manager webhook did not complete in time"; exit 1; }

# Deploy microservices
echo "Deploying microservices..."
kubectl apply -f deploy.yml || { echo "Microservices deployment failed"; exit 1; }

# Wait for services to be ready
echo "Waiting for microservices to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n sock-shop || { echo "Microservices did not become ready in time"; exit 1; }

# Apply ClusterIssuer
echo "Applying ClusterIssuer..."
kubectl apply -f clusterissuer.yml || { echo "ClusterIssuer application failed"; exit 1; }

# Verify ClusterIssuer Status
echo "Verifying ClusterIssuer status..."
kubectl wait --for=condition=Ready clusterissuer/letsencrypt-prod --timeout=120s || { echo "ClusterIssuer is not ready"; exit 1; }

# Apply the Ingress resource
echo "Applying Ingress resource..."
kubectl apply -f ingress.yml || { echo "Ingress resource application failed"; exit 1; }

# Wait for Ingress to be ready
echo "Waiting for Ingress to be ready..."
kubectl wait --for=condition=available --timeout=300s ingress/socks-shop-ingress -n sock-shop || { echo "Ingress did not become available in time"; exit 1; }

# Apply the certificate
echo "Applying certificate..."
kubectl apply -f certificate.yml || { echo "Certificate application failed"; exit 1; }

# Verify the Ingress
echo "Checking Ingress..."
kubectl get ingress -n sock-shop
kubectl describe ingress socks-shop-ingress -n sock-shop

# Monitor Certificates
echo "Monitoring Certificates..."
kubectl get certificates
kubectl describe certificate socks-shop-tls -n sock-shop
