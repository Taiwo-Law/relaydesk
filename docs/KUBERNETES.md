\# RelayDesk Kubernetes Deployment



\## Overview



RelayDesk v1.0.0 has been successfully deployed to a local Kubernetes cluster using Docker Desktop.



This implementation demonstrates Kubernetes container orchestration, health monitoring, scaling, self-healing, rolling updates, deployment rollbacks, and configuration management using ConfigMaps and Secrets.



The Kubernetes environment is intended for local development and DevOps/SRE portfolio practice.



\## Technologies



\- Kubernetes v1.36.1

\- Docker Desktop

\- kubectl

\- Docker

\- GitHub Container Registry (GHCR)

\- Python Flask and Gunicorn

\- Kubernetes ConfigMaps

\- Kubernetes Secrets



\## Kubernetes Architecture



The application uses:



\- A dedicated `relaydesk` namespace

\- A Kubernetes Deployment

\- A ReplicaSet that maintains the desired Pod count

\- A ClusterIP Service exposing port 5000

\- HTTP readiness and liveness probes

\- CPU and memory resource requests and limits

\- An immutable SHA-256 container image reference

\- A ConfigMap for non-sensitive environment configuration

\- A Kubernetes Secret for demonstration of sensitive configuration injection



The local environment currently uses one Kubernetes node, `desktop-control-plane`.



The Deployment normally maintains one application Pod. During scaling exercises, the application was successfully increased to three Pods and subsequently returned to one.



\## Deployment Manifests



The Kubernetes manifests are stored in:



```text

k8s/

├── namespace.yaml

├── configmap.yaml

├── deployment.yaml

└── service.yaml

```



The Secret is created separately and is not stored in a committed Secret manifest.



\### Step 1: Verify Kubernetes Connectivity



From the repository root, check the active Kubernetes context:



```powershell

kubectl config current-context

kubectl get nodes

```



For the local Docker Desktop environment, the expected context is `docker-desktop`.



Verify that the Kubernetes node reports `Ready` before deploying.



\### Step 2: Create the Namespace and ConfigMap



Apply the namespace:



```powershell

kubectl apply -f k8s/namespace.yaml

```



Apply the ConfigMap:



```powershell

kubectl apply -f k8s/configmap.yaml

```



Verify:



```powershell

kubectl get namespace relaydesk

kubectl get configmap relaydesk-config -n relaydesk

```



\### Step 3: Create the Demonstration Secret



The Deployment references a Kubernetes Secret named `relaydesk-demo-secret`.



Create a demonstration Secret using a generated, non-production value:



```powershell

$DemoValue = \[guid]::NewGuid().ToString("N")



kubectl create secret generic relaydesk-demo-secret `

&#x20; --from-literal="DEMO\_API\_KEY=$DemoValue" `

&#x20; -n relaydesk --dry-run=client -o yaml | kubectl apply -f -



Remove-Variable DemoValue

```



This is an intentionally disposable demonstration value, not a production credential.



Verify the Secret exists without displaying its contents:



```powershell

kubectl get secret relaydesk-demo-secret -n relaydesk



kubectl describe secret relaydesk-demo-secret -n relaydesk

```



The expected Secret type is `Opaque`, containing the key `DEMO\_API\_KEY`.



\*\*Security considerations:\*\*



\- Do not commit real passwords, tokens, or Secret values to GitHub.

\- Do not store production credentials directly in PowerShell command history.

\- Kubernetes Secrets are not automatically encrypted at rest in every cluster configuration.

\- Base64 encoding is not encryption.

\- Production environments require appropriate RBAC, encryption at rest, and secret-management policies.

\- This demonstration Secret is not used to authenticate against an external service.



\### Step 4: Deploy RelayDesk



Apply the Deployment:



```powershell

kubectl apply -f k8s/deployment.yaml

```



Apply the Service:



```powershell

kubectl apply -f k8s/service.yaml

```



\### Step 5: Verify the Deployment



Wait for the rollout:



```powershell

kubectl rollout status deployment/relaydesk -n relaydesk --timeout=120s

```



Inspect the Kubernetes resources:



```powershell

kubectl get deployment relaydesk -n relaydesk



kubectl get pods,services -n relaydesk

```



When operating with one replica, the Deployment should show `1/1` ready, and the application Pod should show `Running`.



\## Application Access



RelayDesk uses a ClusterIP Service, which exposes the application internally within Kubernetes.



For local access from Windows, forward port 8080 to the application's Service port 5000:



```powershell

kubectl port-forward -n relaydesk service/relaydesk 8080:5000

```



Keep this PowerShell window open while accessing the application.



In another PowerShell window, test the application:



```powershell

Invoke-RestMethod http://localhost:8080/ | ConvertTo-Json

```



Expected response:



```json

{

&#x20; "service": "RelayDesk",

&#x20; "status": "running",

&#x20; "version": "1.0.0"

}

```



Test the health endpoint:



```powershell

Invoke-RestMethod http://localhost:8080/health | ConvertTo-Json

```



Expected response:



```json

{

&#x20; "status": "healthy"

}

```



Port forwarding stops when the forwarding process is terminated.



\## Container Image Management



The Kubernetes Deployment uses an immutable SHA-256 image reference from GitHub Container Registry.



This ensures Kubernetes deploys the intended container image instead of depending on the mutable `latest` tag.



During implementation, Kubernetes initially ran an older RelayDesk image, even though the `latest` tag in GHCR contained version 1.0.0.



We resolved this by identifying and deploying the exact GHCR image digest.



The application version was then successfully verified through its HTTP endpoint.



Using immutable image references improves deployment traceability and reproducibility.



When releasing a future application version, the image digest in the Deployment must be updated to reference the new tested image.



\## Resource Management



The Deployment defines the following resource requirements:



| Resource | Request | Limit |

|---|---|---|

| CPU | 100m | 500m |

| Memory | 128Mi | 512Mi |



Resource requests help Kubernetes schedule Pods based on available capacity.



Resource limits constrain the resources a container can consume.



These settings are suitable for the current lightweight RelayDesk application and local development environment.



\## Health Probes



RelayDesk uses Kubernetes readiness and liveness probes.



Both probes send HTTP GET requests to `/health` on port 5000.



\### Readiness Probe



Configuration:



\- Initial delay: 5 seconds

\- Check interval: 5 seconds

\- Timeout: 2 seconds

\- Failure threshold: 3



The readiness probe determines whether the application Pod should receive traffic through the Kubernetes Service.



If readiness checks fail repeatedly, Kubernetes marks the Pod as not ready and removes it from the Service's ready endpoints.



\### Liveness Probe



Configuration:



\- Initial delay: 15 seconds

\- Check interval: 10 seconds

\- Timeout: 2 seconds

\- Failure threshold: 3



The liveness probe determines whether the container should be restarted after repeated health-check failures.



\### Verification



Inspect the configured probes:



```powershell

kubectl describe pods -n relaydesk -l app=relaydesk

```



The Pod description should display both readiness and liveness checks.



These probes were successfully configured and recognized by Kubernetes.



\## Kubernetes ConfigMaps



\### Purpose



A ConfigMap allows non-sensitive application configuration to be managed separately from the Docker image.



RelayDesk uses a ConfigMap named `relaydesk-config`.



The ConfigMap stores:



```text

RELAYDESK\_ENV=development

LOG\_LEVEL=INFO

```



These settings are defined in:



```text

k8s/configmap.yaml

```



\### ConfigMap Integration



The Deployment references the ConfigMap through `envFrom`:



```yaml

envFrom:

&#x20; - configMapRef:

&#x20;     name: relaydesk-config

```



This makes the ConfigMap values available as environment variables inside the application container.



\### Verification



Inspect the ConfigMap:



```powershell

kubectl get configmap relaydesk-config -n relaydesk -o yaml

```



Verify the environment variables inside the running container:



```powershell

kubectl exec -n relaydesk deployment/relaydesk -- printenv RELAYDESK\_ENV LOG\_LEVEL

```



Expected output:



```text

development

INFO

```



Both values were successfully verified during implementation.



\### Important Note



The current Flask application does not yet use these variables to change application behavior.



ConfigMap values injected as environment variables are read when the container starts. Updating the ConfigMap does not automatically update environment variables inside already-running containers.



A new Pod must be started to receive updated environment values.



\## Kubernetes Secrets



\### Purpose



Kubernetes Secrets provide a mechanism for supplying sensitive configuration to application containers.



RelayDesk uses a demonstration Secret named:



```text

relaydesk-demo-secret

```



The Secret contains a key named:



```text

DEMO\_API\_KEY

```



\### Secret Integration



The Deployment references the Secret using `secretKeyRef`:



```yaml

env:

&#x20; - name: DEMO\_API\_KEY

&#x20;   valueFrom:

&#x20;     secretKeyRef:

&#x20;       name: relaydesk-demo-secret

&#x20;       key: DEMO\_API\_KEY

```



This allows Kubernetes to inject the Secret value into the container without including the value directly in `deployment.yaml`.



The Secret must exist in the `relaydesk` namespace before the application Pod can start successfully.



\### Verify Secret Injection



To confirm that the environment variable exists without exposing the actual value:



```powershell

kubectl exec -n relaydesk deployment/relaydesk -- python -c "import os; print('DEMO\_API\_KEY present:', bool(os.getenv('DEMO\_API\_KEY')))"

```



Expected result:



```text

DEMO\_API\_KEY present: True

```



This verification was completed successfully.



\### Security Considerations



\- Secret values are not included in the committed Deployment manifest.

\- The demonstration Secret is created locally.

\- Secret values can be accessible to processes running inside the container.

\- Environment variables are not appropriate for every sensitive-data use case.

\- RBAC should restrict access to Kubernetes Secrets.

\- Production environments should enable appropriate encryption at rest and consider dedicated secret-management solutions.



The current Flask application does not actively consume the demonstration API key.



The exercise verifies configuration injection, not the effectiveness of production security controls.



\## Scaling Exercise



RelayDesk was successfully scaled from one to three Pods.



Scale up:



```powershell

kubectl scale deployment/relaydesk --replicas=3 -n relaydesk

```



Verify:



```powershell

kubectl get deployment relaydesk -n relaydesk



kubectl get pods -n relaydesk -o wide

```



All three Pods reached Ready status.



Scale back to one replica:



```powershell

kubectl scale deployment/relaydesk --replicas=1 -n relaydesk

```



Verify:



```powershell

kubectl get deployment relaydesk -n relaydesk

```



The Deployment returned to one healthy replica.



The committed Deployment manifest also specifies one replica, so applying it restores the configured replica count if it was changed manually.



\## Self-Healing Exercise



\### Purpose



Demonstrate how Kubernetes automatically reconciles the number of running Pods with the desired number of replicas.



During testing, RelayDesk was configured with three replicas.



One running Pod was deliberately deleted.



\### Delete a Pod



Select an application Pod:



```powershell

$POD\_TO\_DELETE = kubectl get pods -n relaydesk `

&#x20; -l app=relaydesk `

&#x20; -o jsonpath='{.items\[0].metadata.name}'

```



Delete the selected Pod:



```powershell

kubectl delete pod $POD\_TO\_DELETE -n relaydesk --wait=false

```



Observe the Pods:



```powershell

kubectl get pods -n relaydesk --watch

```



Press Ctrl+C to stop watching.



\### Verification



```powershell

kubectl get deployment relaydesk -n relaydesk



kubectl get pods -n relaydesk -o wide

```



Kubernetes automatically created a replacement Pod.



The Deployment returned to three healthy replicas, demonstrating desired-state reconciliation.



This exercise demonstrated recovery from an individual Pod deletion, not recovery from the failure of the entire Kubernetes node.



\## Rolling Update Exercise



\### Purpose



Demonstrate how Kubernetes updates application Pods while maintaining the desired availability of the Deployment.



A rolling update was triggered using a temporary environment variable:



```powershell

kubectl set env deployment/relaydesk RELAYDESK\_ROLLOUT=exercise-1 -n relaydesk

```



Changing the Pod template caused Kubernetes to create a new Deployment revision and replace the existing Pod.



Verify the rollout:



```powershell

kubectl rollout status deployment/relaydesk -n relaydesk --timeout=120s

```



Inspect the Pods:



```powershell

kubectl get pods -n relaydesk -o wide

```



Inspect the Deployment history:



```powershell

kubectl rollout history deployment/relaydesk -n relaydesk

```



The rolling update completed successfully.



The application image and functional behavior remained unchanged during this exercise.



\## Rollback Exercise



\### Purpose



Demonstrate how Kubernetes restores a previous Deployment configuration.



The temporary environment-variable change was reversed using:



```powershell

kubectl rollout undo deployment/relaydesk -n relaydesk

```



Wait for the rollback:



```powershell

kubectl rollout status deployment/relaydesk -n relaydesk --timeout=120s

```



Verify the Deployment:



```powershell

kubectl get deployment relaydesk -n relaydesk



kubectl get pods -n relaydesk -o wide

```



Confirm that the temporary environment variable is absent:



```powershell

kubectl get deployment relaydesk -n relaydesk `

&#x20; -o jsonpath='{.spec.template.spec.containers\[0].env}'

```



The rollback completed successfully, and the temporary environment variable was removed.



The application remained healthy after the rollback.



\## Final Application Verification



Following the rolling-update and rollback exercises, RelayDesk returned:



```json

{

&#x20; "service": "RelayDesk",

&#x20; "status": "running",

&#x20; "version": "1.0.0"

}

```



The health endpoint returned:



```json

{

&#x20; "status": "healthy"

}

```



The ConfigMap values and demonstration Secret were subsequently injected into the application container and verified successfully.



\## Current Limitations



\- The Kubernetes cluster uses one local node.

\- Multiple replicas do not provide protection against complete node failure.

\- Application access uses local port forwarding.

\- Kubernetes deployments are performed manually using kubectl.

\- ConfigMap settings are not yet used by the Flask application.

\- The demonstration Secret is injected but is not used by application logic.

\- Production-grade Secret security controls have not been implemented or validated.

\- GitHub Actions does not yet automatically deploy to Kubernetes.

\- AWS EKS has not yet been implemented.



\## Future Improvements



\- Make the Flask application consume environment-based configuration.

\- Introduce appropriate Kubernetes startup probes where needed.

\- Develop reusable Helm charts.

\- Implement Kubernetes CI/CD through GitHub Actions.

\- Introduce configuration and Secret management for multiple environments.

\- Explore multi-node Kubernetes clusters.

\- Integrate application-level metrics and Kubernetes monitoring.

\- Deploy RelayDesk to Amazon EKS.

\- Replace demonstration credentials with an appropriate production secret-management approach.



\## Summary



RelayDesk's local Kubernetes implementation demonstrates:



\- Declarative Kubernetes resource management

\- Container orchestration

\- Immutable container image deployment

\- HTTP health probes

\- Resource requests and limits

\- Horizontal application scaling

\- Pod self-healing

\- Rolling updates and rollbacks

\- ConfigMap-based configuration injection

\- Secret-based environment-variable injection

\- Operational verification using kubectl



These capabilities build on the existing RelayDesk AWS ECS/Fargate, Terraform, Docker, GitHub Actions, security scanning, and monitoring implementation.



The next development milestones will focus on application configuration, Kubernetes automation, Helm, and eventual AWS EKS deployment.
