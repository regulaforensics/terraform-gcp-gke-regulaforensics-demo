# Product Overview

This repository contains **Terragrunt infrastructure-as-code** for deploying **Regula Forensics applications** on both Google Cloud Platform (GCP) and Amazon Web Services (AWS).

## Core Applications

- **DocReader**: Document verification and forensics application
- **FaceAPI**: Facial recognition and biometric analysis service

## Infrastructure Scope

The project provides production-grade infrastructure deployment for:

- **Multi-cloud support**: Both GCP (GKE) and AWS (EKS) implementations
- **Kubernetes orchestration**: Container-based application deployment
- **Database services**: PostgreSQL (Cloud SQL/RDS) for application data
- **Object storage**: Cloud Storage/S3 for file storage
- **Networking**: Private VPC with NAT gateways and security controls
- **Monitoring**: Integrated observability and logging

## Target Environment

Designed for enterprise deployment of Regula Forensics solutions with:
- High availability and scalability
- Security-first architecture with private networking
- Infrastructure automation and reproducibility
- Multi-environment support (dev/staging/prod)

## License Requirements

Requires valid Regula Forensics license file (`regula.license`) for application deployment.