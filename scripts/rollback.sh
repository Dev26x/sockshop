#!/bin/bash

# # Exit immediately if a command exits with a non-zero status
# set -e

# Rollback Grafana
echo "Starting rollback for Grafana..."
cd "$(dirname "$0")/../monitoring" || { echo "Monitoring directory not found"; exit 1; }
GRAFANA_MANIFESTS=$(ls *-grafana-*.yaml | awk '{ print " -f " $1 }' | grep -v grafana-import)
if kubectl get pods --namespace monitoring --selector=app=grafana &>/dev/null; then
    kubectl delete $GRAFANA_MANIFESTS
    echo "Grafana rollback completed."
else
    echo "Grafana is not currently deployed or not found."
fi

# Rollback Prometheus
echo "Starting rollback for Prometheus..."
PROMETHEUS_MANIFESTS=$(ls *-prometheus-*.yaml | awk '{ print " -f " $1 }')
if kubectl get pods --namespace monitoring --selector=app=prometheus &>/dev/null; then
    kubectl delete $PROMETHEUS_MANIFESTS
    echo "Prometheus rollback completed."
else
    echo "Prometheus is not currently deployed or not found."
fi

# Rollback Kubernetes resources
echo "Starting rollback for Kubernetes resources..."
cd "$(dirname "$0")/../kubernetes" || { echo "Kubernetes directory not found"; exit 1; }
if kubectl get deployments --namespace sock-shop &>/dev/null; then
    kubectl delete -f deploy.yml
    kubectl delete -f ingress.yml
    kubectl delete -f clusterissuer.yml
    kubectl delete -f certificate.yml
    echo "Kubernetes rollback completed."
else
    echo "Kubernetes resources are not currently deployed or not found."
fi

# Rollback Terraform
echo "Starting rollback for Terraform..."
cd "$(dirname "$0")/../terraform" || { echo "Terraform directory not found"; exit 1; }
terraform init
terraform destroy -auto-approve
echo "Terraform rollback completed."

echo "All resources have been rolled back successfully!"
