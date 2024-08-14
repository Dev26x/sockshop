# #!/bin/bash

# # Navigate to the alerting directory
# cd ../alerting

# # Define file paths
# ALERTMANAGER_CONFIGMAP_FILE="../alerting/alertmanager-configmap.yaml"
# ALERTMANAGER_DEPLOYMENT_FILE="../alerting/alertmanager-dep.yaml"
# ALERTMANAGER_SERVICE_FILE="../alerting/alertmanager-svc.yaml"

# # Define the secret name and key (use meaningful names)
# SECRET_NAME="slack-webhook-url"
# SECRET_KEY="webhook-url"

# # The Slack Hook URL should be defined in the environment or hardcoded
# SLACK_HOOK_URL="https://hooks.slack.com/services/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"

# # Create the Kubernetes secret for Slack Hook URL
# create_secret() {
#   echo "Creating Kubernetes secret for Slack Hook URL..."
#   kubectl create secret generic $SECRET_NAME --from-literal=$SECRET_KEY=$SLACK_HOOK_URL
# }

# # Apply the Alertmanager ConfigMap
# apply_configmap() {
#   echo "Applying Alertmanager ConfigMap..."
#   kubectl apply -f $ALERTMANAGER_CONFIGMAP_FILE
# }

# # Deploy Alertmanager
# deploy_alertmanager() {
#   echo "Deploying Alertmanager..."
#   kubectl apply -f $ALERTMANAGER_DEPLOYMENT_FILE
# }

# # Create Alertmanager Service
# create_service() {
#   echo "Creating Alertmanager Service..."
#   kubectl apply -f $ALERTMANAGER_SERVICE_FILE
# }

# # Run the functions
# create_secret || { echo "Failed to create secret"; exit 1; }
# apply_configmap
# deploy_alertmanager
# create_service

# echo "Alerting setup completed successfully!"

# Navigate to alerting directory
cd "$(dirname "$0")/../alerting" || { echo "Alerting directory not found"; exit 1; }

kubectl create secret generic slack-hook-url \
  --from-literal=slack-hook-url=https://hooks.slack.com/services/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 \
  -n default

kubectl get secrets -n default | grep slack-hook-url

# apply alerting files
kubectl apply -f .

# check alert pod
kubectl get pods -n default | grep alertmanager

kubectl describe service alertmanager -n default   

