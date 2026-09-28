# RelayDesk



RelayDesk is a production-style Flask service built as an end-to-end DevOps portfolio project.



The project demonstrates how an application evolves from a simple locally running service into a containerized, automated, cloud-deployed, observable, and reliable production-style workload.



## Current Features



- Flask REST service

- Root application endpoint

- Health-check endpoint

- Isolated Python virtual environment

- Reproducible Python dependencies

- Git version control

- GitHub source repository



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



Currently:



- Python

- Flask

- Git

- GitHub



### Planned DevOps Tooling



- Docker

- GitHub Actions

- Terraform

- AWS

- Automated testing

- Monitoring and observability

- Production deployment practices



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


