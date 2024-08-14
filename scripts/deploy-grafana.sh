#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Navigate to Grafana directory
cd "$(dirname "$0")/../monitoring/grafana" || { echo "Grafana directory not found"; exit 1; }

# Define the namespace YAML file and NodePorts
MONITORING_NAMESPACE_FILE="../00-monitoring-ns.yaml"
GRAFANA_NODEPORT=31300

# Ensure the Kubernetes context is correct
kubectl config current-context || { echo "Kubeconfig context not found or Kubernetes cluster is not accessible"; exit 1; }

# Check if the monitoring namespace already exists
if kubectl get namespace monitoring &>/dev/null; then
  echo "Namespace 'monitoring' already exists."
else
  # Create monitoring namespace
  echo "Creating monitoring namespace..."
  kubectl create -f "$MONITORING_NAMESPACE_FILE"
fi

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply -f 09-grafana-sa.yaml
kubectl apply -f 10-grafana-deployment.yaml
kubectl apply -f 11-grafana-service.yaml
kubectl apply -f 12-grafana-configmap.yaml
kubectl apply -f 13-grafana-dashboards.yaml

# Wait for Grafana to be deployed
echo "Waiting for Grafana to be deployed..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app=grafana \
  --timeout=120s

# Check if Grafana is running
GRAFANA_STATUS=$(kubectl get pods --namespace monitoring --selector=app=grafana --output=jsonpath='{.items[*].status.phase}')
if [[ "$GRAFANA_STATUS" == *"Running"* ]]; then
  echo "Grafana is running on NodePort $GRAFANA_NODEPORT"
else
  echo "Failed to deploy Grafana"
  exit 1
fi

# Import Grafana dashboards
echo "Importing Grafana dashboards..."
kubectl apply -f 23-grafana-import-dash-batch.yaml

echo "Grafana stack deployed successfully!"

# Optional: Port forward Grafana service
read -p "Would you like to port-forward Grafana to your local machine? (y/n): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
  echo "Starting port-forwarding..."
  kubectl port-forward service/grafana -n monitoring 31300:80
else
  echo "Port-forwarding skipped."
fi
