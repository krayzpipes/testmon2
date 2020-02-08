# testmon
Testing some CI/CD pipeline stuff

Master: [![CircleCI](https://circleci.com/gh/krayzpipes/testmon/tree/master.svg?style=svg)](https://circleci.com/gh/krayzpipes/testmon/tree/master)


## Overview

This repo was built to test out docker and CI/CD pipelines.

#### The Application
Features of the test application:
- Python FastAPI framework with Redis backend
- Designed to alert the client if their jobs took to long to run (ex: Cronjob)
    - HTTP POST body with `{"app_id": "abcd", "action": "start", "duration": 3600}` would:
        - Store the app_id as a key in the redis backend.
        - Start the monitor by taking the sum of the current time + duration, and saving it as
        the value in the redis backend. This is considered the `expiration` time.
    - HTTP POST body with `{"app_id": "abcd", "action": "stop"}` would:
        - Look for a key named `abcd` in the redis backend.
        - Take the value from the redis backend and see if the current time is before or after
        the value that was stored in the redis backend.
        - If the current time is later than the expiration time, then the respone to this HTTP POST
        will contain a message saying the job was late.

#### Terraform
The terraform template creates:
- **VPC / EC2**
    - Private and Public subnets across two availability zones
        - Elasticache subnets
        - Fargate task subnets
        - Public subnets for NAT Gateway and Load Balancer
    - DNS association with private Route53 zone 'testmon.local'
    - Security groups
        - Load balancer
            - ingress traffic from CIDRs in terraform.tfvars
            - egress HTTP to ECS tasks/target group
        - ECS
            - ingress HTTP from load balancers
            - egress HTTPS to 0.0.0.0/0 in order to pull imagees from ECR
            - egress to the Redis Elasticache cluster
        - Elasitache
            - Ingress from ECS
- **IAM**
    - CircleCI User, Role, and Role policy for pipeline automation
    - Roles/policies for ECS Task Execution
- **Route53**
    - Private hosted zone `testmon.local` associated with the created VPC
    - CNAME record `redis.testmon.local` that points to the Elasticache node
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

## Local app testing

#### Docker image with python dependencies
```bash
$ docker build -t krayzpipes/pylibraries -f pylibraries.Dockerfile .
```

#### Docker image for the app
```bash
$ docker build -t krayzpipes/dev-testmon -f dev.Dockerfile .
```

OR you can build it in one file (takes longer so not as good for dev) if you plan
on deploying to a registry or as part of a pipeline:

#### Docker image for releases
This installs all dependencies, copies over source code, all in one.
```bash
$ docker build -t krayzpipes/testmon .
```

#### Docker image for redis
```bash
$ docker build -t -f redis.Dockerfile krayzpipes/redis .
```

#### Create docker network
```bash
# We'll use this to let the containers talk to each other.
$ docker network create testmon-net
```

#### Run the containers
```bash
# Make sure you name the redis container red1... otherwise change
# your dockerfile to reflect the actual name you designated.
$ docker run --network testmon-net --name red1 -d krayzpipes/redis
$ docker run --network testmon-net --name web1 -d -p 8080:80 krayzpipes/testmon
```

or 

```bash
$ docker run --network testmon-net --name red1 -d krayzpipes/redis
$ docker run --network testmon-net --name webdev1  -d krayzpipes/dev-testmon
```

## Test it with requests
```python
import json

import requests

start = {"app_id": "abcdefg", "action": "start", "duration": 3600}
stop = {"app_id": "abcdefg", "action": "stop"}

start_request = requests.post('http://127.0.0.1:8080/testmon/monitor', json=start)
print(start_request)

stop_request = requests.post('http://127.0.0.1:8080/testmon/monitor', json=stop)
print(stop_request)
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