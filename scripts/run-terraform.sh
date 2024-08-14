#!/bin/bash

# Navigate to your Terraform directory
cd ../terraform

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Create an execution plan
echo "Creating Terraform execution plan..."
terraform plan

# Apply the changes
echo "Applying Terraform changes..."
terraform apply --auto-approve

# Extract the region and cluster name from Terraform outputs
REGION=$(terraform output -raw region)
CLUSTER_NAME=$(terraform output -raw cluster_name)

# Update kubeconfig for EKS cluster
echo "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

echo "Terraform and EKS setup completed successfully!"
