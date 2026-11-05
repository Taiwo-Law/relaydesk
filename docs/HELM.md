\# RelayDesk Helm Deployment



\## Overview



RelayDesk v1.0.0 is packaged as a reusable Helm chart for deployment to Kubernetes.



This implementation demonstrates Helm chart development, Kubernetes templating, application configuration, release management, upgrades, and rollbacks.



The chart was successfully tested using Docker Desktop Kubernetes.



\## Technologies



\- Helm v4.3.1

\- Kubernetes v1.36.1

\- Docker Desktop

\- kubectl

\- GitHub Container Registry (GHCR)

\- Python Flask and Gunicorn



\## Helm Chart Structure



The Helm chart is located at:



```text

helm/relaydesk/

├── .helmignore

├── Chart.yaml

├── values.yaml

└── templates/

&#x20;   ├── \_helpers.tpl

&#x20;   ├── configmap.yaml

&#x20;   ├── deployment.yaml

&#x20;   ├── service.yaml

&#x20;   ├── serviceaccount.yaml

&#x20;   └── NOTES.txt

```



\## Chart Metadata



\- Chart name: `relaydesk`

\- Chart version: `0.1.0`

\- Application version: `1.0.0`

\- Chart type: `application`



Chart versions are independent of application versions.



\## Kubernetes Resources



The Helm chart generates four resources:



1\. ServiceAccount

2\. ConfigMap

3\. ClusterIP Service

4\. Deployment



The chart uses an immutable GHCR image digest.



The Deployment includes readiness and liveness probes, CPU and memory resource requests and limits, and ConfigMap and Secret references.



\## Application Configuration



The Helm chart uses `values.yaml` to configure application settings.



Default configuration includes:



| Setting | Value |

|---|---|

| Replicas | 1 |

| Service type | ClusterIP |

| Service port | 5000 |

| Environment | development |

| Logging level | INFO |

| CPU request | 100m |

| CPU limit | 500m |

| Memory request | 128Mi |

| Memory limit | 512Mi |



Application configuration is provided through a Helm-managed ConfigMap named `relaydesk-config`.



The chart references an existing Kubernetes Secret named `relaydesk-demo-secret`.



The Secret value is not stored in the Helm chart.



The application ServiceAccount has automatic ServiceAccount token mounting disabled.



\## Helm Chart Validation



Validate the chart:



```powershell

helm lint helm/relaydesk

```



Render its Kubernetes resources:



```powershell

helm template relaydesk helm/relaydesk --namespace relaydesk-helm-test

```



The chart passed validation with zero failures.



\## Helm Test Environment



To avoid interfering with the existing kubectl-managed RelayDesk deployment, Helm was tested in a separate namespace:



```text

relaydesk-helm-test

```



Create the namespace if it does not already exist:



```powershell

kubectl create namespace relaydesk-helm-test

```



Create a disposable demonstration Secret:



```powershell

$DemoValue = \[guid]::NewGuid().ToString("N")



kubectl create secret generic relaydesk-demo-secret `

&#x20; --from-literal="DEMO\_API\_KEY=$DemoValue" `

&#x20; --namespace relaydesk-helm-test



Remove-Variable DemoValue

```



For production workloads, use appropriate secret-management practices instead of inline credentials.



\## Install RelayDesk with Helm



From the repository root:



```powershell

helm install relaydesk .\\helm\\relaydesk `

&#x20; --namespace relaydesk-helm-test `

&#x20; --wait `

&#x20; --timeout 3m

```



The initial installation completed successfully.



Verify the release:



```powershell

helm list --namespace relaydesk-helm-test

```



Verify Kubernetes resources:



```powershell

kubectl get pods,services,configmaps -n relaydesk-helm-test

```



The application Pod reached `1/1 Running` with zero restarts.



\## Application Verification



Forward the application Service to the local computer:



```powershell

kubectl port-forward -n relaydesk-helm-test service/relaydesk 8081:5000

```



In another PowerShell window, verify the application:



```powershell

Invoke-RestMethod http://localhost:8081/ | ConvertTo-Json

```



Expected response:



```json

{

&#x20; "service": "RelayDesk",

&#x20; "status": "running",

&#x20; "version": "1.0.0"

}

```



Verify the health endpoint:



```powershell

Invoke-RestMethod http://localhost:8081/health | ConvertTo-Json

```



Expected response:



```json

{

&#x20; "status": "healthy"

}

```



Both endpoints were successfully verified.



\## Verify ConfigMap and Secret Injection



Check the application environment and logging level:



```powershell

kubectl exec -n relaydesk-helm-test deployment/relaydesk -- python -c "from app import app; print('Environment:', app.config\['RELAYDESK\_ENV']); print('Logging level:', app.logger.level)"

```



The initial logging level was `20`, corresponding to INFO.



Verify that the demonstration Secret is present without printing its value:



```powershell

kubectl exec -n relaydesk-helm-test deployment/relaydesk -- python -c "import os; print('DEMO\_API\_KEY present:', bool(os.getenv('DEMO\_API\_KEY')))"

```



The check returned `True`.



\## Automatic ConfigMap Rollouts



The Deployment template uses a checksum annotation:



```yaml

checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}

```



When the Helm-rendered ConfigMap changes, the checksum changes.



This modifies the Deployment's Pod template and triggers a Kubernetes rolling update.



The mechanism ensures that new Pods receive updated ConfigMap values supplied as environment variables.



\## Helm Upgrade Exercise



The logging level was changed from INFO to DEBUG using:



```powershell

helm upgrade relaydesk .\\helm\\relaydesk `

&#x20; --namespace relaydesk-helm-test `

&#x20; --set configMap.data.LOG\_LEVEL=DEBUG `

&#x20; --wait `

&#x20; --timeout 3m

```



The upgrade completed successfully and created release revision 2.



Kubernetes replaced the application Pod.



Application verification confirmed:



```text

Environment: development

Logging level: 10

```



Logging level `10` corresponds to DEBUG.



No Docker image rebuild was required.



\## Helm Rollback Exercise



The previous release configuration was restored using:



```powershell

helm rollback relaydesk 1 `

&#x20; --namespace relaydesk-helm-test `

&#x20; --wait `

&#x20; --timeout 3m

```



The rollback succeeded and created revision 3.



The replacement Pod became healthy.



Application verification confirmed:



```text

Environment: development

Logging level: 20

```



The logging level was successfully restored to INFO.



\## Helm Release History



| Revision | Action | Result |

|---|---|---|

| 1 | Initial installation with INFO logging | Superseded |

| 2 | Upgrade to DEBUG logging | Superseded |

| 3 | Rollback to revision 1 | Deployed |



View release history:



```powershell

helm history relaydesk --namespace relaydesk-helm-test

```



\## Uninstall the Test Release



When the Helm test environment is no longer required:



```powershell

helm uninstall relaydesk --namespace relaydesk-helm-test

```



This removes the resources managed by the Helm release.



The separately created demonstration Secret and namespace are not removed automatically.



The existing kubectl-managed RelayDesk deployment in the `relaydesk` namespace is unaffected.



\## Current Limitations



\- The environment uses a single local Kubernetes node.

\- Helm deployments are initiated manually.

\- The chart depends on a separately provisioned Secret.

\- The Docker image digest must be updated when releasing new application versions.

\- Production-grade Secret management has not been implemented.

\- The chart has not been deployed to Amazon EKS.

\- Kubernetes deployments are not yet automated through GitHub Actions.



\## Future Improvements



\- Automate chart validation in GitHub Actions.

\- Introduce Helm chart packaging and versioning.

\- Create separate development and production values files.

\- Implement automated Kubernetes deployments.

\- Integrate production-grade Secret management.

\- Add Kubernetes metrics and monitoring.

\- Explore multi-node clusters and Amazon EKS.



\## Summary



The RelayDesk Helm implementation demonstrates:



\- Reusable Kubernetes packaging

\- Helm template development

\- Configurable deployment values

\- Immutable container image references

\- ConfigMap and Secret integration

\- Kubernetes health probes

\- Resource management

\- Least-privilege ServiceAccount configuration

\- Helm installation and verification

\- Application configuration upgrades

\- Automatic rolling updates

\- Helm release history and rollbacks



This implementation builds on the existing RelayDesk Docker, Terraform, AWS ECS/Fargate, CI/CD, security, and Kubernetes portfolio work.
