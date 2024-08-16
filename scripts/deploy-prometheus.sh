#!/bin/bash

set -e

# Navigate to the monitoring directory
cd "$(dirname "$0")/../monitoring" || { echo "Monitoring directory not found"; exit 1; }

aws eks update-kubeconfig --name "sockshop" --region "us-east-1"

# Define the namespace YAML file and NodePorts
MONITORING_NAMESPACE_FILE="00-monitoring-ns.yaml"
PROMETHEUS_NODEPORT=31090

# Define the Prometheus manifests
PROMETHEUS_MANIFESTS=$(ls *-prometheus-*.yaml | awk '{ print " -f " $1 }')

# Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create -f $MONITORING_NAMESPACE_FILE || echo "Namespace already exists."

# Deploy Prometheus
echo "Deploying Prometheus..."
kubectl apply $PROMETHEUS_MANIFESTS

# Wait for Prometheus to be deployed
sleep 45

# Check if Prometheus is running
PROMETHEUS_STATUS=$(kubectl get pods --namespace monitoring --selector=app=prometheus --output=jsonpath='{.items[*].status.phase}')
if [ "$PROMETHEUS_STATUS" == "Running" ]; then
  echo "Prometheus is running on NodePort $PROMETHEUS_NODEPORT"
else
  echo "Failed to deploy Prometheus"
  exit 1
fi

# Auto port forward Prometheus service and exit after 10 seconds

echo "Starting port-forwarding for Prometheus..."
{
  kubectl port-forward service/grafana -n monitoring 9090:9090 &
  PORT_FORWARD_PID=$!
  sleep 10
  kill $PORT_FORWARD_PID
  echo "Port-forwarding stopped after 10 seconds."
}
