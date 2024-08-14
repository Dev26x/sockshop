#!/bin/bash

# navigate to monitoring folder
cd "$(dirname "$0")/../monitoring" || { echo "Monitoring directory not found"; exit 1; }

# Define the namespace YAML file and NodePorts
MONITORING_NAMESPACE_FILE="00-monitoring-ns.yaml"
PROMETHEUS_NODEPORT=31090

# Define the Grafana and Prometheus manifests
PROMETHEUS_MANIFESTS=$(ls *-prometheus-*.yaml | awk '{ print " -f " $1 }')

# Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create -f $MONITORING_NAMESPACE_FILE

# Deploy Prometheus
echo "Deploying Prometheus..."
kubectl apply $PROMETHEUS_MANIFESTS

# Wait for Prometheus to be deployed
echo "Waiting for Prometheus to be deployed..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app=prometheus \
  --timeout=120s

# Check if Prometheus is running
PROMETHEUS_STATUS=$(kubectl get pods --namespace monitoring --selector=app=prometheus --output=jsonpath='{.items[*].status.phase}')
if [ "$PROMETHEUS_STATUS" == "Running" ]; then
  echo "Prometheus is running on NodePort $PROMETHEUS_NODEPORT"
else
  echo "Failed to deploy Prometheus"
  exit 1
fi

kubectl port-forward service/prometheus -n monitoring 9090:9090
