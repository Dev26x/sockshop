#!/bin/bash
set -e

# Function to navigate to directory and check for errors
navigate_and_execute() {
  local dir="$1"
  local command="$2"

  echo "Navigating to $dir"
  cd "$dir" || { echo "Directory $dir not found"; exit 1; }

  echo "Executing command: $command"
  eval "$command"
}

# Sleep 
echo "Sleeping for 300 seconds before starting the rollback..."
sleep 300

# Navigate to logging directory and delete resources
navigate_and_execute "$(dirname "$0")/../logging" "
  echo 'Deleting logging resources...'
  kubectl delete -f kibana.yml || true
  kubectl delete -f fluentd-daemon.yml || true
  kubectl delete -f fluentd-crb.yml || true
  kubectl delete -f fluentd-cr.yml || true
  kubectl delete -f fluentd-sa.yaml || true
  kubectl delete -f elasticsearch.yml || true
  kubectl delete secret tls elasticsearch-tls -n kube-system || true
"

# Navigate to alerting directory and delete resources
navigate_and_execute "$(dirname "$0")/../alerting" "
  echo 'Deleting alerting resources...'
  kubectl delete -f . || true
  kubectl delete secret slack-hook-url -n default || true
"

# Navigate to monitoring directory and delete resources
navigate_and_execute "$(dirname "$0")/../monitoring" "
  echo 'Deleting monitoring resources...'
  kubectl delete -f $(ls *-prometheus-*.yaml) || true
  kubectl delete -f $(ls *-grafana-*.yaml) || true
  kubectl delete -f 00-monitoring-ns.yaml || true
"

# Navigate to Kubernetes directory and delete resources
navigate_and_execute "$(dirname "$0")/../kubernetes" "
  echo 'Deleting Kubernetes resources...'
  kubectl delete -f ingress.yml || true
  kubectl delete -f certificate.yml || true
  kubectl delete -f clusterissuer.yml || true
  kubectl delete -f deploy.yml || true
  kubectl delete --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml || true
  helm uninstall nginx-ingress --namespace ingress-nginx || true
  kubectl delete namespace ingress-nginx || true
  kubectl delete namespace sock-shop || true
"

# Navigate to Terraform directory and run terraform destroy
navigate_and_execute "$(dirname "$0")/../terraform" "
  echo 'Running terraform destroy...'
  terraform destroy -auto-approve
"

echo "Rollback completed successfully."
