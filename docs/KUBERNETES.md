# RelayDesk Kubernetes Deployment

## Overview

RelayDesk v1.0.0 has been deployed successfully to a local Kubernetes cluster using Docker Desktop.

This implementation demonstrates Kubernetes orchestration, health monitoring, scaling, self-healing, rolling updates, and rollbacks.

## Technologies

- Kubernetes v1.36.1
- Docker Desktop
- kubectl
- Docker
- GitHub Container Registry (GHCR)
- Python Flask and Gunicorn

## Kubernetes Architecture

The application uses:

- A dedicated `relaydesk` namespace
- A Kubernetes Deployment
- A ReplicaSet that maintains the desired Pod count
- A ClusterIP Service exposing port 5000
- HTTP readiness and liveness probes
- CPU and memory resource requests and limits
- An immutable SHA-256 image reference

The environment currently uses one local Kubernetes node.

## Deployment Manifests

The Kubernetes manifests are stored in:

```text
k8s/
├── namespace.yaml
├── deployment.yaml
└── service.yaml
```

Deploy the application:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Verify the Deployment:

```powershell
kubectl rollout status deployment/relaydesk -n relaydesk
kubectl get pods,services -n relaydesk
```

## Application Access

Forward local traffic to the Kubernetes Service:

```powershell
kubectl port-forward -n relaydesk service/relaydesk 8080:5000
```

Application endpoints:

- `http://localhost:8080/`
- `http://localhost:8080/health`

The application root endpoint returns RelayDesk version `1.0.0`.

## Health Probes

The Deployment uses HTTP GET requests to `/health`.

**Readiness probe**

- Initial delay: 5 seconds
- Interval: 5 seconds
- Timeout: 2 seconds
- Failure threshold: 3

**Liveness probe**

- Initial delay: 15 seconds
- Interval: 10 seconds
- Timeout: 2 seconds
- Failure threshold: 3

Readiness controls whether Pods receive Service traffic.

Liveness allows Kubernetes to restart unhealthy containers.

## Scaling Exercise

RelayDesk was successfully scaled from one to three Pods.

```powershell
kubectl scale deployment/relaydesk --replicas=3 -n relaydesk
```

All three replicas reached Ready status.

The Deployment was subsequently scaled back to one replica.

## Self-Healing Exercise

One running Pod was deliberately deleted.

The Deployment's ReplicaSet automatically created a replacement Pod.

The application recovered to the desired state of three healthy replicas.

This demonstrated Kubernetes desired-state reconciliation.

## Rolling Update Exercise

A rolling update was triggered by adding a temporary environment variable:

```powershell
kubectl set env deployment/relaydesk RELAYDESK_ROLLOUT=exercise-1 -n relaydesk
```

Kubernetes created a new Deployment revision and replaced the application Pod.

The rollout completed successfully.

## Rollback Exercise

The previous Deployment configuration was restored using:

```powershell
kubectl rollout undo deployment/relaydesk -n relaydesk
```

The rollback completed successfully.

The temporary environment variable was removed, and the application continued responding correctly.

## Final Verification

After rollback, the application returned:

```json
{
  "service": "RelayDesk",
  "status": "running",
  "version": "1.0.0"
}
```

The health endpoint returned:

```json
{
  "status": "healthy"
}
```

## Current Limitations

- The cluster uses one local Kubernetes node.
- Multiple replicas do not provide protection against complete node failure.
- Application access currently uses local port forwarding.
- Kubernetes deployments are performed manually using kubectl.
- AWS EKS has not yet been implemented.

## Future Improvements

- Kubernetes ConfigMaps and Secrets
- Helm charts
- Automated Kubernetes deployments through GitHub Actions
- Multi-node cluster architecture
- AWS EKS deployment
