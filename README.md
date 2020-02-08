# testmon
Testing some CI/CD pipeline stuff

## Overview

This repo was built to test out docker and CI/CD pipelines.

#### The Application
Features of the test application:
- Python FastAPI framework
- Two endpoints
    - `/now` returns a status, current server time, and the client IP as seen by the server
    - `/tomorrow` returns a status, current server time + 1 day, and the client IP as seen by the server.

#### Terraform
The terraform template creates:
- **VPC / EC2**
    - Private and Public subnets across two availability zones
        - Elasticache subnets
        - Fargate task subnets
        - Public subnets for NAT Gateway and Load Balancer
    - Security groups
        - ECS
            - ingress TCP 80 from load balancer subnets
            - egress HTTPS to 0.0.0.0/0 in order to pull imagees from ECR
- **IAM**
    - CircleCI User, Role, and Role policy for pipeline automation
    - Roles/policies for ECS Task Execution
- **ECR**
    - Registry for testmon
- **ECS**
    - Fargate cluster
    - Note:  ECS Service and Task definintions will be created out of band of Terraform
    as Terraform does not play nicely with CI/CD deployments out of band of Terraform.
    Terraform also makes old tasks `INACTIVE`, which they cannot be rolled back to in the
    case of an issue.

#### CircleCI

- Runs linting, static analysis.
- Builds container. If on the release branch, pushes to AWS ECR.
- (coming soon) ECS-Deploy if on the release branch.


#### Initial deployment
1. Apply the terraform templates
2. Seed the ECS Service and Task Definition
    - ECS-Deploy (in the pipeline) does not bootstrap the ECS Service nor Task Definition.
    You must first seed the Service/Task Definition that ECS Deploy can then update during
    the CI/CD Pipeline.
    - Fill out variables and then run the `scrips/seed_tasks_and_services.sh` script to
    seed the task definition and service.
    - It's okay to reference a `dummy` or `fake` container image to get this part going.
3. Setup your CircleCI account.
    - Give access to repo
    - Setup environment context named `testmon` with the CircleCI user info from the terraform build.
        - AWS_ACCESS_KEY_ID
        - AWS_SECRET_ACCESS_KEY
        - AWS_DEFAULT_REGION
        - APP_NAME   ('testmon' in this case)
4. Commit code and watch the wheels turn. Commit to the `master` branch to see the image pushed and
for Fargate to begin running the application.
5. Get the load balancer DNS name to interact with the application.

#### Docker image for the app
```bash
$ docker build -t testmon:dev .
```
#### Run the container
```bash
$ docker run --name testmon2 -d -p 8080:8080 krayzpipes/testmon
```

## Test it with requests
```python
>>> import requests
>>> r = requests.get('http://127.0.0.1:8080/now')
>>> r.status_code
200
>>> r.json()
{'status': 'alive', 'time': 'Sat Feb  8 20:52:44 2020', 'ip': '172.16.0.5'}
```

```python
>>> import requests
>>> r = requests.get('http://127.0.0.1:8080/tomorrow')
>>> r.status_code
200
>>> r.json()
{'status': 'alive', 'time': 'Sun Feb  9 20:53:51 2020', 'ip': '172.16.0.5'}
```

# Terraform

Currently using terraform version 0.12.20.

Be sure to fill out your secret variables (AND DO NOT COMMIT THEM). The .gitignore file ignored `*.tfvars` for this purpose.

```bash
$ cp terraform.tfvars.example terraform.tfvars
```
Once you've added the secret variables, you can plan out the terraform work.
```bash
$ cd terraform/

$ terraform init

$ terraform plan
```

Terraform will plan the creation of an Elastic Container Registry, Repo, and will create a user
to be used by CircleCI to push/pull images.