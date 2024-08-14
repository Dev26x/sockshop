#!/bin/bash

#navigate to monitoring directory
cd "$(dirname "$0")/../monitoring/grafana" || { echo "Grafana directory not found"; exit 1; }

# Define the namespace YAML file and NodePorts
MONITORING_NAMESPACE_FILE="00-monitoring-ns.yaml"
GRAFANA_NODEPORT=31300

# Define the Grafana manifests
GRAFANA_MANIFESTS=$(ls *-grafana-*.yaml | awk '{ print " -f " $1 }' | grep -v grafana-import)

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply $GRAFANA_MANIFESTS

# Wait for Grafana to be deployed
echo "Waiting for Grafana to be deployed..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app=grafana \
  --timeout=120s

# Check if Grafana is running
GRAFANA_STATUS=$(kubectl get pods --namespace monitoring --selector=app=grafana --output=jsonpath='{.items[*].status.phase}')
if [ "$GRAFANA_STATUS" == "Running" ]; then
  echo "Grafana is running on NodePort $GRAFANA_NODEPORT"
else
  echo "Failed to deploy Grafana"
  exit 1
fi

# Import Grafana dashboards
echo "Importing Grafana dashboards..."
kubectl apply -f 23-grafana-import-dash-batch.yaml

echo "Monitoring stack deployed successfully!"

kubectl port-forward service/grafana -n monitoring 31300:80