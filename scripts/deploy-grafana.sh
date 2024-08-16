#!/bin/bash

set -e

aws eks update-kubeconfig --name "hakeem-shop" --region "us-east-1"

# Navigate to the monitoring directory
cd "$(dirname "$0")/../monitoring" || { echo "Monitoring directory not found"; exit 1; }

# Define the namespace YAML file and NodePorts
MONITORING_NAMESPACE_FILE="00-monitoring-ns.yaml"
GRAFANA_NODEPORT=31300

# Define the Grafana manifests
GRAFANA_MANIFESTS=$(ls *-grafana-*.yaml | awk '{ print " -f " $1 }' | grep -v grafana-import)

# Create monitoring namespace if it doesn't exist
if kubectl get namespace monitoring &>/dev/null; then
  echo "Namespace 'monitoring' already exists."
else
  echo "Creating monitoring namespace..."
  kubectl create -f $MONITORING_NAMESPACE_FILE
fi

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply $GRAFANA_MANIFESTS

# Wait for Grafana to be deployed
sleep 45

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

echo "Monitoring stack deployed successfully!"

# Auto port forward Grafana service and exit after 10 seconds
echo "Starting port-forwarding for Grafana..."
{
  kubectl port-forward service/grafana -n monitoring 31300:80 &
  PORT_FORWARD_PID=$!
  sleep 10
  kill $PORT_FORWARD_PID
  echo "Port-forwarding stopped after 10 seconds."
}