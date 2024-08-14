

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

