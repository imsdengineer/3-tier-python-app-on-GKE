# 3-Tier Python Microservice Application Deployment

![GKE](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)

## Project Overview

This project automates the deployment of a 3-tier Python microservice application to a private GKE cluster using:
- **Terraform** for infrastructure provisioning
- **Helm** for application deployment
- **GitHub Actions** for CI/CD pipelines
- **MS Teams** for alerting and notifications

## Project Owner
**Imran Ali**  
📧 [imsdengineer@gmail.com](mailto:imsdengineer@gmail.com)

## Features

- 🛠 **Infrastructure as Code**: Complete GKE private cluster provisioning via Terraform
- 🚀 **Automated CI/CD**: GitHub Actions workflows for infrastructure and application deployment
- 🔔 **Real-time Alerts**: MS Teams integration for deployment notifications
- 🐳 **Containerized Microservices**: Three-tier architecture (frontend, backend, database)
- ⚖ **Scalable Architecture**: Designed for easy scaling of components
- 🔒 **Private Cluster**: Enhanced security with private GKE cluster

## Folder Structure


## Folder Structure

3-tier-python-app-on-GKE/
├── .github/
│   └── workflows/
│       ├── 1-setup-prerequisites.yml
│       ├── 2-deploy-infra.yml
│       ├── 3-deploy-app.yml
│       └── alerts.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
├── helm/
│   └── three-tier-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       │   ├── frontend/
│       │   │   ├── deployment.yaml
│       │   │   └── service.yaml
│       │   ├── backend/
│       │   │   ├── deployment.yaml
│       │   │   └── service.yaml
│       │   ├── database/
│       │   │   ├── statefulset.yaml
│       │   │   └── service.yaml
│       │   └── ingress.yaml
│       └── charts/
├── scripts/
│   ├── setup-gcloud.sh
│   ├── setup-kubectl.sh
│   └── setup-helm.sh
└── README.md