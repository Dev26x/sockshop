#!/bin/bash

# Check if Terraform is installed
if ! command -v terraform &> /dev/null
then
    echo "Terraform not found, installing..."
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install terraform
else
    echo "Terraform is already installed"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl not found, installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
    echo "kubectl is already installed"
fi

# Navigate to the terraform directory from the scripts directory
cd "$(dirname "$0")/../terraform" || { echo "Terraform directory not found"; exit 1; }

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Create an execution plan
echo "Creating Terraform execution plan..."
terraform plan

# Apply the changes
echo "Applying Terraform changes..."
terraform apply --auto-approve

#!/bin/bash

# ... (previous Terraform commands)

# Extract the region and cluster name from Terraform outputs
REGION=$(terraform output -raw region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

# Update kubeconfig for EKS cluster
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Output the values for use in later steps
if [ -n "$GITHUB_OUTPUT" ]; then
    # We're in a GitHub Actions environment
    echo "region=$REGION" >> $GITHUB_OUTPUT
    echo "cluster_name=$CLUSTER_NAME" >> $GITHUB_OUTPUT
else
    # We're in a local environment
    echo "Region: $REGION"
    echo "Cluster Name: $CLUSTER_NAME"
fi

echo "Terraform setup completed successfully!"

