# Cloud Infrastructure Reliability Toolkit

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

A modular Terraform toolkit for provisioning **fault-tolerant, auto-scaling cloud infrastructure** on AWS. Built around production reliability patterns including Multi-AZ redundancy, automated recovery, and infrastructure-as-code reproducibility.

---

## Overview

This project codifies cloud reliability best practices into reusable Terraform modules. It provisions a complete application stack — networking, compute, database, and observability — with self-healing and horizontal scaling built in from the ground up.

The architecture targets a three-tier topology deployed across three AWS Availability Zones:

- **Network layer** — VPC with isolated public, private, and database subnet tiers
- **Compute layer** — ECS Fargate with CPU-based Target Tracking autoscaling
- **Data layer** — Aurora PostgreSQL with encrypted storage, automated backups, and read-replica failover
- **Observability layer** — CloudWatch log aggregation with APM integration points

---

## Modules

### `modules/ecs-service`

Deploys a containerized workload on ECS Fargate with production-grade defaults.

| Capability | Detail |
|---|---|
| Compute | AWS Fargate (serverless containers) — no EC2 instance management |
| Networking | `awsvpc` mode; tasks placed in private subnets with no public IP |
| Autoscaling | Target Tracking on `ECSServiceAverageCPUUtilization` (default threshold: 70%, range: 1–5 tasks) |
| Logging | Native `awslogs` driver integration with CloudWatch |
| Load Balancing | Optional ALB target group attachment via dynamic block |
| Configuration | Environment variables and Secrets Manager/Parameter Store references injected at task level |

### `modules/aurora-postgres`

Provisions an Aurora PostgreSQL cluster parameterized for both development and production topologies.

| Capability | Detail |
|---|---|
| Engine | Aurora PostgreSQL 15.4 |
| High Availability | Configurable instance count — single instance for dev, multi-instance with read replicas for production |
| Encryption | Storage encrypted at rest (enforced, non-optional) |
| Backups | Automated daily backups with configurable retention (default: 7 days, window: 07:00–09:00 UTC) |
| Network Isolation | Deployed into dedicated database subnets; `publicly_accessible` defaults to `false` |

### `modules/observability`

Manages centralized logging and alerting infrastructure with extension points for third-party APM.

| Capability | Detail |
|---|---|
| Log Aggregation | CloudWatch Log Group with validated retention period |
| Alarm Notifications | SNS topic with optional email subscription |
| ECS Alarms | CPU utilization and memory utilization threshold alarms |
| Aurora Alarms | Free storage space, connection count, and replica lag alarms |
| ALB Alarms | HTTP 5xx error rate alarm |
| APM Integration | Scaffold for Datadog/New Relic forwarder (CloudFormation stack placeholder) |

### `modules/security-groups`

Provisions dedicated, least-privilege security groups for each network tier.

| Security Group | Ingress | Egress |
|---|---|---|
| ALB | 80, 443 from `0.0.0.0/0` | Container port → ECS SG only |
| ECS Tasks | Container port from ALB SG only | 5432 → Aurora SG; 443 → internet (ECR/CloudWatch) |
| Aurora | 5432 from ECS SG only | None required |

### `modules/alb`

Provisions a production-ready Application Load Balancer with conditional TLS termination.

| Capability | Detail |
|---|---|
| Load Balancer | Internet-facing ALB across public subnets (multi-AZ) |
| TLS | HTTPS listener with `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.2+); HTTP→HTTPS 301 redirect |
| Dev mode | When `certificate_arn` is empty, creates an HTTP-only listener (no TLS) |
| Target Group | `target_type = "ip"` for Fargate `awsvpc`; 30s deregistration delay |
| Health Check | Configurable path, interval, thresholds, and matcher |
| Access Logs | Optional S3 access log delivery for audit and compliance |
| Safety | `enable_deletion_protection` variable (default `true` in prod) |

### `modules/secrets`

Manages application and database credentials in AWS Secrets Manager with ECS-native integration.

| Capability | Detail |
|---|---|
| DB Credentials | JSON secret at `<app_name>/db/credentials` storing `{username, password}` |
| App Secrets | JSON secret at `<app_name>/app/secrets` storing JWT keys, API tokens |
| ECS Integration | `ecs_secret_refs` output maps directly to the task definition `secrets` block |
| Rotation Safety | `lifecycle.ignore_changes` on `secret_string` prevents Terraform from reverting out-of-band rotations |
| Recovery | Configurable `recovery_window_in_days`: 0 for dev (force delete), 7–30 for production |

---

## Reliability Design

### Fault Isolation

Services, databases, and load balancers are distributed across three Availability Zones in separate subnet tiers with independent security groups. A failure in any single AZ does not propagate to the remaining zones.

### Self-Healing Compute

The ECS service scheduler continuously monitors task health. Unhealthy tasks are drained and replaced automatically without operator intervention.

### Elastic Scaling

Application Auto Scaling uses a Target Tracking policy on average CPU utilization. When the metric exceeds the configured threshold (default 70%), additional Fargate tasks are launched. Scale-in occurs automatically when demand subsides.

### Data Durability & Failover

Aurora PostgreSQL replicates data six ways across three AZs at the storage layer. When provisioned with multiple instances, automatic failover promotes a read replica to primary in the event of a writer failure.

### Async Decoupling

The architecture supports asynchronous inter-service communication (Kafka placeholder) to prevent cascading failures during downstream degradation.

---

## Failure Scenarios

| Scenario | Recovery Mechanism |
|---|---|
| Container crash | ECS scheduler detects the unhealthy task and launches a replacement automatically |
| Availability Zone failure | ALB routes traffic to healthy targets in remaining AZs; Aurora fails over to replica |
| Traffic spike | Target Tracking autoscaling provisions additional Fargate tasks within ~30 seconds |
| Configuration drift | CI pipeline runs `terraform plan` / `terraform validate` to detect divergence before it reaches production |
| Catastrophic environment loss | Full environment is reproducible via `terraform apply` — no manual reconstruction required |

---

## Prerequisites

| Requirement | Version |
|---|---|
| Terraform | >= 1.5 |
| AWS Provider | >= 5.0 |
| AWS CLI | Configured with valid credentials and appropriate IAM permissions |

**Required IAM permissions:** VPC, ECS, RDS, CloudWatch Logs, IAM role/policy management, Application Auto Scaling.

---

## Quick Start

```bash
# 1. Initialize providers and modules
cd examples/dev
terraform init

# 2. Validate syntax and configuration
terraform validate

# 3. Preview the execution plan
terraform plan

# 4. Provision the infrastructure
terraform apply
```

> **Note:** The dev example uses a default database password for convenience. In production, inject credentials via `terraform.tfvars` (git-ignored), environment variables, or AWS Secrets Manager.

---

## Repository Structure

```
├── bootstrap/                    # One-time remote state backend (S3 + DynamoDB)
├── modules/
│   ├── ecs-service/              # ECS Fargate service, task definition, autoscaling
│   ├── aurora-postgres/          # Aurora PostgreSQL cluster, instances, parameter group
│   ├── observability/            # CloudWatch logs, SNS alarms, ECS/Aurora/ALB monitoring
│   ├── security-groups/          # Dedicated least-privilege SGs per network tier
│   ├── alb/                      # Application Load Balancer, target group, listeners
│   └── secrets/                  # Secrets Manager for DB credentials and app secrets
├── examples/
│   ├── dev/                      # Dev environment (HTTP-only ALB, 1 Aurora instance)
│   │   ├── main.tf
│   │   ├── backend.tf            # S3 remote state backend configuration
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── prod/                     # Production (HTTPS ALB, HA Aurora, per-AZ NAT)
│       ├── main.tf
│       ├── backend.tf            # S3 remote state backend configuration
│       ├── variables.tf
│       └── outputs.tf
├── .github/
│   └── workflows/
│       └── terraform.yml         # CI: fmt, validate, tflint, tfsec, checkov
├── .gitignore
└── README.md
```

---

## Module Dependency Graph

The `examples/dev/main.tf` composition layer wires modules together with the following data flow:

- **VPC** → `public_subnets` → **ALB** (internet-facing, multi-AZ)
- **VPC** → `private_subnets` + `vpc_id` → **Security Groups** → SG IDs → **ALB**, **ECS Service**, and **Aurora PostgreSQL**
- **VPC** → `database_subnet_group_name` → **Aurora PostgreSQL**
- **ALB** → `target_group_arn` → **ECS Service** (registers task IPs as targets)
- **ALB** → `lb_arn_suffix` + `target_group_arn_suffix` → **Observability** (5xx alarm dimensions)
- **Secrets** → `ecs_secret_refs` → **ECS Service** (injected as in-memory env vars at task launch)
- **Secrets** → `db_credentials_secret_arn` + `app_secrets_arn` → **IAM execution role** (least-privilege policy)
- **Observability** → `log_group_name` → **ECS Service** (log configuration)
- **Observability** → (receives) `aurora_cluster_id`, `ecs_cluster_name`, `ecs_service_name` → creates alarms against those resources
- **Aurora PostgreSQL** → `cluster_endpoint` → **ECS Service** (injected as `DB_HOST`)

---

## Configuration Reference

### Dev Environment Defaults

| Parameter | Default | Purpose |
|---|---|---|
| `region` | `us-east-1` | AWS deployment region |
| `single_nat_gateway` | `true` | Cost optimization for non-production |
| `instance_count` (Aurora) | `1` | Single writer, no replicas |
| `desired_count` (ECS) | `1` | Single task |
| `autoscaling_cpu_threshold` | `70` | CPU % that triggers scale-out |
| `autoscaling_max_capacity` | `5` | Upper bound on task count |
| `retention_days` (Logs) | `30` | CloudWatch log retention |
| `backup_retention_period` | `7` | Aurora backup retention in days |

### Production Recommendations

- Set `instance_count >= 2` for Aurora to enable automatic failover
- Disable `single_nat_gateway` for per-AZ NAT redundancy
- Set `skip_final_snapshot = false` and configure `final_snapshot_identifier`
- Replace default database password with Secrets Manager integration
- Attach an ALB target group to the ECS service for external traffic ingress
- Increase `autoscaling_max_capacity` based on expected peak load

---

## License

MIT

---

## Senior-Level Enhancements

This section documents the architectural improvements applied to bring the project from a functional mid-level implementation to a production-orientated platform engineering reference.

### Before vs. After: Architecture Maturity

| Dimension | Before | After |
|---|---|---|
| **Security Groups** | Default VPC security group shared across all resources | Dedicated SG per tier (ALB, ECS, Aurora) with explicit least-privilege rules |
| **ECS Deployment** | No circuit breaker; default min/max percentages | Circuit breaker with auto-rollback; configurable min healthy % and max % |
| **Autoscaling** | CPU only (single axis) | CPU + memory (dual axis); cooldown periods explicit |
| **Aurora Observability** | No query or OS visibility | Performance Insights + Enhanced Monitoring (IAM role provisioned) |
| **Aurora Safety** | No deletion protection or parameter group | `deletion_protection` variable; custom parameter group for log tuning |
| **Unified Alerting** | No alarms — logs only | SNS topic + CloudWatch alarms for ECS CPU, ECS memory, Aurora storage, Aurora connections, Aurora replica lag, ALB 5xx |
| **Task Role** | No task role (execution role only) | Separate scoped task role; IAM separation enforced |
| **Container Insights** | Disabled | Enabled on ECS cluster — memory, network, disk metrics per task |
| **Outputs** | No outputs in composition layer | Full outputs: cluster name, service name, endpoints, SG IDs, alarm topic ARN |
| **Variable Validation** | No input validation | Validation blocks on all critical variables in all modules |
| **Production Environment** | Dev example only | `examples/prod/` with HA Aurora, per-AZ NAT, tighter deployment configs |
| **CI/CD Pipeline** | Single-job skeleton (fmt + validate only) | 6-job pipeline: fmt, validate-dev, validate-prod, tflint, tfsec, checkov |
| **Remote State** | Local state only | Commented S3 + DynamoDB backend block ready to activate |

---

### Security Hardening

**Dedicated Security Groups (`modules/security-groups`)**

The default VPC security group was replaced with a purpose-built module that provisions independent security groups for each traffic tier. Each group has explicit ingress and egress rules scoped to the minimum required path:

- ALB accepts public HTTPS/HTTP and forwards only to ECS on the container port
- ECS tasks accept traffic only from the ALB and send database traffic only to Aurora
- Aurora accepts PostgreSQL connections only from ECS tasks

This eliminates lateral movement risk between tiers and satisfies CIS AWS Foundations Benchmark network segmentation requirements.

**Scoped IAM Task Role**

The execution role (which grants ECS the ability to pull images and write logs) is now separated from the task role (which grants the application container AWS API access). This prevents container workloads from inheriting the broad permissions required for ECS control-plane operations.

---

### Reliability Improvements

**ECS Deployment Circuit Breaker**

```hcl
deployment_circuit_breaker {
  enable   = true
  rollback = true
}
```

Prevents a bad container image from replacing all healthy tasks. If the new task set fails to reach steady state, ECS automatically rolls back to the previous task definition revision.

**Deployment Safety Bounds**

`deployment_minimum_healthy_percent = 100` and `deployment_maximum_percent = 200` ensure zero-downtime rolling updates. The service always maintains full desired capacity and provisions replacement tasks before terminating running ones.

**Aurora Deletion Protection**

`deletion_protection = true` by default (overridden to `false` in dev) blocks accidental `terraform destroy` from wiping the production database. Combined with `skip_final_snapshot = false`, a snapshot is always taken before any cluster termination.

---

### Observability Improvements

**SNS Alarm Routing**

All CloudWatch alarms publish to a single SNS topic (`{app_name}-alarms`). This provides a single subscription point that can be routed to email, PagerDuty, Slack, or OpsGenie without modifying individual alarm resources.

**CloudWatch Alarms Provisioned**

| Alarm | Metric | Purpose |
|---|---|---|
| ECS CPU high | `ECSServiceAverageCPUUtilization` | Human-facing signal when CPU is critically high (above autoscaling threshold) |
| ECS memory high | `ECSServiceAverageMemoryUtilization` | Catches memory-bound failures invisible to CPU-only monitoring |
| Aurora free storage low | `FreeLocalStorage` | Early warning before storage exhaustion causes cluster unavailability |
| Aurora connections high | `DatabaseConnections` | Prevents silent connection pool exhaustion at the database layer |
| Aurora replica lag | `AuroraReplicaLag` | Production HA signal — elevated lag indicates replica reads are stale |
| ALB 5xx errors | `HTTPCode_Target_5XX_Count` | Application error rate — primary user-facing health signal |

**Aurora Performance Insights + Enhanced Monitoring**

Performance Insights (query-level metrics) and Enhanced Monitoring (OS-level metrics including swap, file descriptors, CPU steal) are enabled for production by default. A dedicated IAM role with `AmazonRDSEnhancedMonitoringRole` is provisioned by the module when `monitoring_interval > 0`.

**ECS Container Insights**

Enabled on the ECS cluster via the `setting` block. Provides per-task memory, network I/O, disk I/O, and CPU metrics that the default CloudWatch ECS namespace does not include.

---

### Scalability Improvements

**Dual-Axis Autoscaling**

A second Target Tracking policy on `ECSServiceAverageMemoryUtilization` (default 75%) runs in parallel with the CPU policy. ECS uses whichever policy requires more capacity. This prevents silent OOM failures in memory-bound workloads (e.g., JVM, Node.js).

**Explicit Cooldown Periods**

`scale_in_cooldown = 300` and `scale_out_cooldown = 60` are now explicit module variables rather than left at AWS defaults. The asymmetry is intentional: scale out fast (60s), scale in conservatively (300s) to avoid thrash.

---

### DevOps & CI/CD

The skeleton CI pipeline was replaced with a 6-job workflow:

| Job | Tool | Purpose |
|---|---|---|
| `fmt` | `terraform fmt --check --recursive` | Enforces HCL formatting across all files |
| `validate-dev` | `terraform validate` | Validates dev composition against all module schemas |
| `validate-prod` | `terraform validate` | Validates prod composition; stubs required variables |
| `tflint` | TFLint | Provider-specific linting; catches deprecated arguments and missing fields |
| `security` | tfsec | Static analysis for AWS security misconfigurations (HIGH/CRITICAL fail) |
| `checkov` | Checkov | CIS AWS Benchmark policy scan (soft-fail during adoption) |

---

### AWS Well-Architected Alignment

| Pillar | Improvement Made |
|---|---|
| **Operational Excellence** | Outputs in composition layer; working CI/CD with security scanning; remote state backend scaffold |
| **Security** | Dedicated least-privilege security groups; separate execution/task IAM roles; `deletion_protection` default |
| **Reliability** | Deployment circuit breaker; dual-axis autoscaling; Aurora deletion protection; connection alarms |
| **Performance Efficiency** | Dual-axis Target Tracking (CPU + memory); Container Insights for rightsizing data |
| **Cost Optimization** | Dev/prod separation explicit; dev disables enhanced monitoring and Performance Insights; prod uses `r6g` instance class |

---

---

## Production-Readiness Enhancements

This section documents the final architectural upgrades that close the three critical gaps previously identified: secrets management, load balancer ingress, and remote state backend.

### Secrets Manager Integration (`modules/secrets`)

Prior state: Database credentials were passed as a plaintext `db_password` Terraform variable, visible in state files and task definitions.

**What changed:**

- Two Secrets Manager secrets are provisioned per environment: `<app_name>/db/credentials` (JSON: `username`, `password`) and `<app_name>/app/secrets` (JSON: `jwt_secret`, `app_key`).
- The ECS task definition `secrets` block references secret ARNs with JSON-key extraction (`arn:...:username::`) — the ECS agent resolves these at task launch. Credentials never appear in the task definition, CloudWatch Logs, or `terraform show` output.
- A scoped `aws_iam_role_policy` on the execution role grants `secretsmanager:GetSecretValue` to exactly the two secret ARNs in that environment. A compromised role cannot access secrets from any other environment or path.
- `lifecycle.ignore_changes` on `secret_string` prevents `terraform apply` from reverting credentials that were rotated outside Terraform (e.g., via Lambda rotation or the AWS CLI).
- Dev uses `recovery_window_in_days = 0` for instant teardown. Prod uses `30` for a 30-day soft-delete recovery window.

### Application Load Balancer (`modules/alb`)

Prior state: No load balancer resource existed. ECS tasks were not reachable from the internet.

**What changed:**

- An internet-facing ALB spans all public subnets (3 AZs). If an AZ fails, ALB stops routing to targets in that AZ automatically — no manual intervention.
- `target_type = "ip"` on the target group is required for Fargate `awsvpc` networking. `deregistration_delay = 30s` reduces rolling deployment time.
- When `certificate_arn` is provided (prod): port 443 HTTPS listener uses `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.2+, ECDHE forward secrecy); port 80 redirects to HTTPS via 301. When empty (dev): port 80 forwards directly to the target group.
- `drop_invalid_header_fields = true` mitigates HTTP request smuggling attacks.
- `enable_deletion_protection = true` in prod prevents `terraform destroy` from removing a live ALB.
- Health check path, interval, thresholds, and matcher are configurable. The default `/health` path expects a dedicated liveness endpoint.
- `lb_arn_suffix` and `target_group_arn_suffix` outputs wire directly into the observability module so the ALB 5xx alarm tracks the correct load balancer.

### Remote State Backend (`bootstrap/`)

Prior state: Commented-out backend block; state stored locally. No locking. No shared state for team collaboration.

**What changed:**

- A dedicated `bootstrap/` workspace provisions the S3 bucket and DynamoDB table required by the Terraform S3 backend.
- S3 bucket: versioning enabled, AES-256 server-side encryption, all public access blocked, `DenyInsecureTransport` bucket policy, 90-day noncurrent version expiry.
- DynamoDB table: `PAY_PER_REQUEST` billing, point-in-time recovery, server-side encryption. The `LockID` attribute prevents concurrent `terraform apply` runs from corrupting state.
- Dedicated `backend.tf` files in `examples/dev/` and `examples/prod/` configure the S3 backend with separate key paths, providing state isolation within a shared bucket.
- Migration from local to remote state: `terraform init` detects the new backend and prompts to copy existing state. No data loss. Verified with `terraform state list`.

### IAM Hardening

- Execution role: `AmazonECSTaskExecutionRolePolicy` (base) + a scoped inline policy restricted to the two Secrets Manager ARNs in the current environment.
- Task role: Separate IAM role for application-level AWS API access. No inherited control-plane permissions.
- RDS Enhanced Monitoring: Dedicated IAM role (`AmazonRDSEnhancedMonitoringRole`) provisioned by the Aurora module only when `monitoring_interval > 0`.