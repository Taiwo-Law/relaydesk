# RelayDesk



RelayDesk is a production style Flask service built as an end to end DevOps portfolio project.



The project demonstrates how an application evolves from a simple locally running service into a containerized, automated, cloud-deployed, observable, and reliable production-style workload.



## Current Features



- Flask REST service
- Root application endpoint
- Health-check endpoint
- Isolated Python virtual environment
- Reproducible Python dependencies
- Git version control
- GitHub source repository
- Dockerized application
- Gunicorn production WSGI server
- Automated testing with pytest
- GitHub Actions continuous integration
- Automated Docker image builds in CI
- Container health smoke testing
- Automated container publishing to GitHub Container Registry
- Commit-SHA and `latest` Docker image tagging
- Published container pull-and-run verification 
- Infrastructure provisioning with Terraform
- AWS VPC networking across multiple public subnets
- Amazon ECS deployment using AWS Fargate
- GitHub Actions authentication to AWS using OIDC
- Automated ECS deployment from GitHub Actions
- Application change detection to prevent unnecessary deployments
- Amazon CloudWatch centralized container logging
- ECS CPU and memory monitoring
- CloudWatch CPU and memory alarms
- Amazon SNS email alerting for alarm and recovery events
- ECS container health checks
- Automatic unhealthy task replacement
- Post-deployment health verification
- ECS deployment circuit breaker with automatic rollback
- Cost-conscious ECS scale-to-zero workflow



## API Endpoints



| Endpoint | Purpose |

|----------|---------|

| `/` | Returns RelayDesk service status |

| `/health` | Application health check |



Example health response:



```json

{

  "status": "healthy"

}

```



## Technology Stack

- Python
- Flask
- Git
- GitHub
- Docker
- Gunicorn
- pytest
- GitHub Actions
- GitHub Container Registry (GHCR)
- Terraform
- AWS
- Amazon VPC
- Amazon ECS
- AWS Fargate
- AWS IAM
- GitHub OIDC
- Amazon CloudWatch
- Amazon SNS

## AWS Architecture

RelayDesk is deployed to AWS using Terraform-managed infrastructure.

The current architecture includes:

- A dedicated Amazon VPC
- Two public subnets across multiple Availability Zones
- An Internet Gateway and public routing
- An Amazon ECS cluster
- AWS Fargate for container compute
- A dedicated ECS task security group
- A Terraform-managed ECS task definition
- A Terraform-managed ECS service
- GitHub Actions authentication to AWS through OpenID Connect (OIDC)

The ECS service uses a configurable desired task count. During development and practice sessions, the service can be scaled to zero when not in use to minimize AWS costs.

## Monitoring, Observability and Reliability

RelayDesk includes AWS-native monitoring and reliability controls.

Application and Gunicorn logs are sent from ECS to Amazon CloudWatch Logs with a seven-day retention period.

Amazon CloudWatch monitors ECS CPU and memory utilization. The current alarms are configured for:

- CPU utilization above 70% for five consecutive minutes
- Memory utilization above 80% for five consecutive minutes

Alarm and recovery events are published to Amazon SNS and delivered through a confirmed email subscription.

RelayDesk also includes:

- ECS container health checks against `/health`
- Automatic replacement of unhealthy ECS tasks
- Post-deployment health verification from GitHub Actions
- Deployment health-check timeouts
- ECS deployment circuit breaker protection
- Automatic rollback to the previous healthy deployment when a new deployment fails

## CI/CD Pipeline

RelayDesk uses GitHub Actions for continuous integration and deployment.

The application deployment flow is:

```text
Git push
    ↓
Automated pytest tests
    ↓
Terraform formatting and validation
    ↓
Application change detection
    ↓
Docker image build
    ↓
Container smoke test
    ↓
Publish image to GHCR
    ↓
GitHub OIDC authentication to AWS
    ↓
Deploy to Amazon ECS
    ↓
Wait for ECS service stability
    ↓
Verify the live /health endpoint

```


## Planned DevOps Tooling

- Kubernetes
- Infrastructure automation and configuration management
- Advanced monitoring and dashboards
- Secrets management
- Infrastructure security scanning
- CI/CD security and policy checks
- Additional production deployment strategies





## Running Locally



Install the application dependencies:



```bash

pip install -r requirements.txt

```



Run the application:



```bash

python app.py

```



The service will be available at:



```text

http://127.0.0.1:5000

```



Health check:



```text

http://127.0.0.1:5000/health

```



## Project Goal



The goal of RelayDesk is to demonstrate practical DevOps and SRE skills through the complete application lifecycle, including development, containerization, CI/CD, infrastructure provisioning, cloud deployment, monitoring, security, and reliability improvements.



## Project Status



Work in progress. Additional DevOps capabilities will be introduced incrementally as the project evolves.


