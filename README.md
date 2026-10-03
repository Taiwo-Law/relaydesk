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

- Docker

- Gunicorn

- pytest

- GitHub Actions

- GitHub Container Registry (GHCR)



### Planned DevOps Tooling

- Terraform

- AWS

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


