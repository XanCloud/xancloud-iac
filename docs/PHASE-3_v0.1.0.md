# Fase 3 — Blueprints de Workload

> **Duración estimada:** 2-3 semanas por blueprint | **Dependencia:** Fase 1 completa | **Estado:** No iniciada  
> **Nota:** Ejecutable en paralelo con Fase 2.

## Objetivo

Crear blueprints opinados para los patrones de workload más comunes, listos para desplegar sobre la landing zone de Fase 1.

## Entregables

### Blueprint: Web App con ECS Fargate
- Módulo `compute/ecs-fargate/` — Cluster, service, task definition, ALB
- Módulo `data/rds-aurora/` — Aurora Serverless v2 o RDS estándar
- Blueprint `web-app-ecs/` — VPC + ECS + RDS + monitoring compuestos

### Blueprint: Serverless API
- Módulo `compute/lambda/` — Lambda con layers, VPC attachment opcional
- Módulo `networking/api-gateway/` — API Gateway REST/HTTP
- Módulo `data/dynamodb/` — DynamoDB con auto-scaling
- Blueprint `serverless-api/` — APIGW + Lambda + DynamoDB compuestos

### Blueprint: EKS Platform
- Módulo `compute/eks/` — EKS con managed node groups, Fargate profiles
- Módulo `compute/eks-addons/` — CoreDNS, kube-proxy, VPC CNI, EBS CSI
- Blueprint `eks-platform/` — VPC + EKS + monitoring compuestos

### Módulos transversales
- Módulo `data/s3-bucket/` — S3 con encriptación, lifecycle, replicación
- Módulo `operations/monitoring/` — CloudWatch dashboards + alertas por workload
- Módulo `operations/backup/` — AWS Backup policies

## Criterio de completitud

- [ ] Al menos 2 blueprints funcionales y testeados
- [ ] Cada blueprint desplegable con `tofu apply` sobre una landing zone existente
- [ ] Documentación de uso y runbooks por blueprint
