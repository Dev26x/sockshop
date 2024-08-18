# Microservices Deployment with IaC and CI/CD

## Project Overview

This project demonstrates a complete setup for deploying microservices using Infrastructure as Code (IaC) with Terraform and Kubernetes. It includes a robust CI/CD pipeline using GitHub Actions, along with monitoring and alerting solutions.

![AWS infrastructure](capstone-images/project-image.png)

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Setup](#setup)
5. [Infrastructure (Terraform)](#infrastructure-terraform)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Monitoring and Logging](#Monitoring-and-Logging)
8. [Alerting](#alerting)
9. [Scripts](#scripts)
10. [CI/CD Pipeline](#cicd-pipeline)
11. [Result](#Result)


## Features

- Infrastructure as Code using Terraform
- Kubernetes deployment with NGINX Ingress and Cert-Manager
- Monitoring with Prometheus and Grafana
- Alerting with Alertmanager
- Comprehensive CI/CD pipeline with GitHub Actions

## Prerequisites

- AWS Account
- GitHub Account
- Terraform (v1.3 or later)
- kubectl
- Helm

## Project Structure

```
.
├── .github/workflows/
│   ├── terraform.yml
│   ├── kubernetes.yml
│   ├── monitoring.yml
│   └── alerting.yml
├── Alerting/
│   ├── alertmanager-configmap.yml
│   ├── alertmanager-dep.yml
│   └── alertmanager-svc.yml
├── Monitoring/
│   ├── [Prometheus & Grafana configuration files]
├── Kubernetes/
│   ├── certificate.yml
│   ├── clusterissuer.yml
│   ├── deploy.yml
│   └── ingress.yml
├── Scripts/
│   ├── run-terraform.sh
│   ├── apply-kubernetes.sh
│   ├── deploy-prometheus.sh
│   ├── deploy-grafana.sh
│   ├── alerting.sh
│   └── rollback.sh
└── Terraform/
├── main.tf
├── outputs.tf
├── provider.tf
├── terraform.tf
└── variables.tf

```

## Setup

1. Clone this repository:
git clone https://github.com/Dev26x/sockshop.git
cd sockshop
Copy
2. Set up AWS credentials:
- Create an IAM user with appropriate permissions
- Configure AWS CLI with the credentials

3. Set up GitHub Secrets:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_CLUSTER_NAME

4. Set up GitHub Variables:
- AWS_REGION (e.g., us-east-1)


## Infrastructure (Terraform)

The infrastructure is managed using Terraform. Key components include:

- VPC with public and private subnets
- EKS cluster with managed node groups

![terraform main](capstone-images/main.tf.png)

## Kubernetes Deployment

The project uses Kubernetes for orchestrating the microservices. Key components:

![Kubernetes architecture](capstone-images/kuber.png)

- NGINX Ingress Controller
- Cluster Issuer
- Cert-Manager for SSL/TLS
- Microservices deployment
- Ingress

By running the kubernetes script, these files are installed/applied to deploy microservices, issue certificate and secure the domain.

View all services and deployments using:  `kubectl get all -A`

![Alt text](capstone-images/kubectl-all.png)

Certificate issued:
![certificate](capstone-images/certificate-proof.png)

*Remember to create A records in your domain dns pointing to the load balancer, and also create the same A record in your route 53 hosted zone.*

## Monitoring and Logging

![monitoring](capstone-images/monitoring-alerting-img.png)

Monitoring and logging  is set up using Prometheus and Grafana.

I exposed prometheus and grafana to my dash board using port forwarding with these command:
```
kubectl port-forward service/prometheus 31090:9090 -n monitoring

kubectl port-forward service/grafana 31300:3000 -n monitoring

```

![Alt text](capstone-images/promtheus-metrics.png)

![Alt text](capstone-images/grafana-dashboard-2.png)

![Alt text](capstone-images/grafana-dashboard-1.png)

![Alt text](capstone-images/grafana-dashboard.png)

I also edited my prometheus errror rules to aid the alert manager with metrics for alerting.

![Alt text](capstone-images/Prometheus-error-rules.png)

![Alt text](capstone-images/prometheus-alerts.png)

## Alerting

By running the alerting.sh script, Alerting is configured with Alertmanager, which routes alerts to Slack.

Slack Alert
![slack alert](capstone-images/slack-alert.png)

By port-forwarding, alert manager can be viewed in the browser.

![Alt text](capstone-images/alertManagerView.png)

![Alt text](capstone-images/alertManager2.png)


## Scripts

### Terraform script

![Terraform script](capstone-images/terraformscript.png)

Purpose: Manages infrastructure provisioning and updates using Terraform.
- Terraform Initialization and Apply: The script initializes Terraform and applies the configuration to set up infrastructure resources, such as VPCs, EKS clusters, and other components.
- Outputs Variables: Outputs essential variables needed by subsequent workflows (e.g., Kubernetes cluster name, region).


### Kubernetes Script

![kubernetes script](capstone-images/kube-script.png)

Purpose: Deploys Kubernetes resources.
- Applies Kubernetes manifests using kubectl.
- Ensures that all necessary Kubernetes objects (e.g., Deployments, Services, Ingresses) are created or updated.


### Monitoring and Logging Scripts

Prometheus 
![Prometheus script](capstone-images/prometheus-script.png)

Purpose: Deploys Prometheus monitoring tool.
- Applies Prometheus manifests to the Kubernetes cluster.
- Configures Prometheus for monitoring.


Grafana 
![Grafana script](capstone-images/grafana-script.png)

Purpose: Deploys Grafana for visualization.
- Applies Grafana manifests to the Kubernetes cluster.
- Sets up Grafana dashboards and configurations.


### Alerting Script

![Alert script](capstone-images/alertscript.png)

Purpose: Configures and deploys alerting setups.
- Applies alerting configurations, such as Alertmanager and related alerting rules.
- Sets up the alerting pipeline to integrate with Prometheus.


## CI/CD Pipeline

The CI/CD pipeline is implemented using GitHub Actions and consists of four workflows:

1. Terraform

    ![terraform workflow](capstone-images/terraform-wkflw.png)


2. Kubernetes Deployment

    ![kubernetes workflow](capstone-images/kubernetes-wkflw.png)


3. Monitoring and Logging

    Prometheus workflow
    ![prometheus workflow](capstone-images/prometheus-wkflw.png)


    Grafana workflow
    ![grafana workflow](capstone-images/grafana-wkflw.png)


4. Alerting

    ![alerting workflow](capstone-images/alert-wkflw.png)


## Result

The application is accessible on my domain (www.dev26x.com.ng) over HTTPS and secured using Let’s Encrypt for certificates.

![frontend](capstone-images/FRONTEND.png)
