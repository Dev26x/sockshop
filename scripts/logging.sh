#!/bin/bash

# Navigate to logging directory
cd "$(dirname "$0")/../logging" || { echo "Logging directory not found"; exit 1; }

# Apply Elasticsearch Deployment and Service
kubectl create secret tls elasticsearch-tls \
  --cert=/path/to/your/fullchain.pem \
  --key=/path/to/your/privkey.pem \
  -n kube-system


kubectl apply -f elasticsearch.yml
echo "Elasticsearch deployed."

# Apply Fluentd ServiceAccount
kubectl apply -f fluentd-sa.yaml
echo "Fluentd ServiceAccount created."

# Apply Fluentd ClusterRole
kubectl apply -f fluentd-cr.yml
echo "Fluentd ClusterRole created."

# Apply Fluentd ClusterRoleBinding
kubectl apply -f fluentd-crb.yml
echo "Fluentd ClusterRoleBinding created."

# Apply Fluentd DaemonSet
kubectl apply -f fluentd-daemon.yml
echo "Fluentd DaemonSet deployed."

# Apply Kibana Deployment and Service
kubectl apply -f kibana.yml
echo "Kibana deployed."

# Wait for all pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l name=elasticsearch -n kube-system --timeout=120s
kubectl wait --for=condition=ready pod -l name=fluentd -n kube-system --timeout=120s
kubectl wait --for=condition=ready pod -l name=kibana -n kube-system --timeout=120s

# Get the status of the deployments
echo "Checking the status of the deployments..."
kubectl get pods -n kube-system
kubectl get services -n kube-system

# Print access information for Kibana
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT=$(kubectl get svc kibana -n kube-system -o jsonpath='{.spec.ports[0].nodePort}')
echo "Kibana is accessible at: http://$NODE_IP:$NODE_PORT"
