# Cloud Infrastructure Reliability Toolkit

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

A production-ready, modular Terraform toolkit designed to demonstrate **infrastructure reliability**, **fault tolerance**, and **scalable architecture** on AWS.

## Architecture

```mermaid
graph TD
    User -->|HTTPS| ALB[Application LoadBalancer]
    
    subgraph VPC [VPC (Multi-AZ)]
        subgraph PublicSubnets [Public Subnets]
            ALB
            NAT[NAT Gateway]
        end
        
        subgraph PrivateSubnets [Private Subnets]
            subgraph ECSCluster [ECS Fargate Cluster]
                ServiceA[Service: API]
                AutoScaling[App Autoscaling]
            end
        end
        
        subgraph DBSubnets [Database Subnets]
            AuroraPrimary[Aurora Limitless Primary]
            AuroraReplica[Aurora Read Replica]
        end
    end
    
    ServiceA -->|SQL| AuroraPrimary
    AuroraPrimary -.->|Replication| AuroraReplica
    ServiceA -->|Logs| CW[CloudWatch Logs]
    ServiceA -.->|Async| Kafka[Kafka (Mocked)]
```

## Reliability Goals

1.  **Fault Isolation**: Services run in isolated subnets and security groups. Failures in one AZ do not trigger a total system outage due to Multi-AZ distribution.
2.  **Scalability**: ECS services utilize Target Tracking Scaling to automatically adjust task counts based on CPU utilization.
3.  **Data Durability**: Aurora PostgreSQL is configured for high availability (Multi-AZ) and automated backups.
4.  **Security**: No hardcoded secrets. All sensitive interaction is done via variable injection or (in a real world scenario) Secrets Manager/Parameter Store.

## Key Features & Modules

- **modules/ecs-service**:
    - Fargate compute for reduced operational overhead.
    - Built-in CPU-based autoscaling.
    - Log driver integration with CloudWatch.
- **modules/aurora-postgres**:
    - Parameterized for HA (Multi-AZ) or Dev (SDLC cost-savings).
    - Enforced encryption at rest.
- **modules/observability**:
    - Centralized log group management.
    - Placeholder for APM integration (Datadog/NewRelic).

## Failure Scenarios Handled

| Scenario | Handling Strategy |
|----------|-------------------|
| **Container Crash** | ECS Service scheduler detects unhealthy task and automatically replaces it. |
| **AZ Failure** | Load Balancer (ALB) routes traffic to healthy targets in other AZs. Aurora fails over to replica. |
| **Traffic Spike** | App Auto Scaling triggers scale-out alarm based on CPU metric > 70%. |

## Usage

### Prerequisites
- Terraform >= 1.5
- AWS CLI configured

### Quick Start (Dev Example)

1. **Initialize**
   ```bash
   cd examples/dev
   terraform init
   ```

2. **Validate**
   ```bash
   terraform validate
   ```

3. **Plan & Apply**
   ```bash
   terraform apply
   ```

## Repository Structure

```
├── modules/              # Reusable Terraform modules
│   ├── ecs-service/     # ECS Service, Task Definitions, Autoscaling
│   ├── aurora-postgres/ # RDS Aurora Cluster & Instances
│   └── observability/   # CloudWatch & Monitoring
├── examples/
│   └── dev/             # Complete environment composition
├── .github/workflows/    # CI Pipeline (Fmt, Validate, TFLint)
└── README.md
```

## Interview Talking Points

### Improving MTTR (Mean Time To Recovery)
- **Immutable Infrastructure**: By using Terraform, we ensure that infrastructure can be recreated identically in minutes if a catastrophic region failure occurs.
- **Automated Rollbacks**: ECS deployments (via CodeDeploy or built-in rolling update) allow for quick revert of bad container versions.
- **Observability Code**: Logging infrastructure is provisioned alongside the application, ensuring no blind spots during an incident.

### Ensuring Availability
- **Decoupling**: The architecture assumes asynchronous communication (via Kafka mock) to prevent cascading failures.
- **Redundancy**: Database layer uses Aurora's self-healing storage and read replicas. Compute layer spans 3 Availability Zones.
- **Drift Detection**: CI pipelines run `terraform plan` (future state) or `validate` to catch configuration drift before it hits production.
