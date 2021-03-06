#!/usr/bin/env bash

# This script assumes that the cluster name, service name, and family name will all be the same.
# So be sure to change it as you need to.

# Terraform does not handle deploying new task definitions very well. As far as Fargate is
# concerned, it is wise to only deploy your cluster via Terraform and leave the task
# definition / service deployment and updates to something tied more closely with your code
# builds--for example, ecs-deploy.

# In order to use tools like ECS-Deploy, you must first have service and task definitions available.
# Before using ECS-deploy, and AFTER deploying your terraform tempmlates, run this seed script to
# get things rolling. Then you can use ecs-deploy to update / deploy. You should only need to run
# this seed script for your first deployment.

DESIRED_TASK_COUNT=2
ECR_IMAGE_TAG=$(git rev-parse --short HEAD)
ECR_IMAGE_URL=036544028716.dkr.ecr.us-east-1.amazonaws.com/testmon
ECR_REDIS_URL=036544028716.dkr.ecr.us-east-1.amazonaws.com/redis
ECS_CLUSTER_ARN=arn:aws:ecs:us-east-1:036544028716:cluster/testmon
ECS_SECURITY_GROUP=sg-04ae2264c4084fa97
ECS_SERVICE_NAME=testmon
ECS_SUBNET_ONE=subnet-0c7a8e545d70df9b6
ECS_SUBNET_TWO=subnet-09bedac8b2d59c538
TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:us-east-1:036544028716:targetgroup/tf-testmon-dev-lb-tg/d723f9b5c11822fa
TASK_FAMILY=testmon
TASK_EXECUTION_ROLE_ARN=arn:aws:iam::036544028716:role/ecsTestmonTaskExecutionRole

does_cluster_exist () {
  clusters=$(aws ecs describe-clusters --cluster $ECS_SERVICE_NAME)
  if [ 0 -eq "$(echo $clusters | jq '.clusters | length')" ]
  then
    echo "Cluster $ECS_SERVICE_NAME was not found. Deploy cluster first. Exiting..."
    exit 1
  fi
  if [ "INACTIVE" = "$(echo $clusters | jq -r '.clusters[0].status')" ]
  then
    echo "Found cluster but it is inactive. Please resolve inactive cluster '$ECS_SERVICE_NAME'. Exiting..."
    exit 1
  fi
  echo "Found existing cluster $ECS_SERVICE_NAME. Will continue with script..."
}

register_task_definition () {
  register_response=$(aws ecs register-task-definition --cli-input-json "${TASK_DEFINITION_JSON}")
  TASK_DEFINITION_ARN=$(echo $register_response | jq -r '.taskDefinition.taskDefinitionArn')
  echo "${TASK_DEFINITION_ARN}"
}

create_ecs_service () {
  echo "Checking to see if service already exists"
  if [ "0" == "$(aws ecs describe-services --cluster $ECS_SERVICE_NAME --service $ECS_SERVICE_NAME | jq '.services | length')" ]
  then
    echo "Service does not exists. Creating new service."
    service_response="$(aws ecs create-service --cli-input-json "${ECS_SERVICE_JSON}")"
    if [ "$?" != "0" ]
    then
      echo "Error when creating ECS Service. Resolve and try again. Exiting..."
      exit 1
    fi
    echo "Created ECS service:"
    echo $service_response | jq
  else
    echo "Service '$ECS_SERVICE_NAME' already exists. Exiting..."
    exit 1
  fi
}


TASK_DEFINITION_JSON=$(cat <<EOF
{
  "executionRoleArn": "$TASK_EXECUTION_ROLE_ARN",
  "containerDefinitions": [
    {
      "portMappings": [
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 80
        }
      ],
      "cpu": 256,
      "memory": 512,
      "image": "$ECR_IMAGE_URL:latest",
      "name": "testmon"
    },
    {
      "portMappings": [
        {
          "hostPort": 6379,
          "protocol": "tcp",
          "containerPort": 6379
        }
      ],
      "cpu": 256,
      "memory": 512,
      "image": "$ECR_REDIS_URL:latest",
      "name": "redis"
    }
  ],
  "placementConstraints": [],
  "cpu": "1024",
  "memory": "2048",
  "family": "$TASK_FAMILY",
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "networkMode": "awsvpc"
}
EOF
)

does_cluster_exist
echo "Registering task definition..."
TASK_DEFINITION_ARN="$(register_task_definition)"

if [ -z $TASK_DEFINITION_ARN ]
then
  echo "Issue registering task definition. Exiting..."
  exit 1
fi

echo "Task Definition arn: $TASK_DEFINITION_ARN"


ECS_SERVICE_JSON=$(cat <<EOF
{
  "serviceName": "testmon",
  "cluster": "$ECS_CLUSTER_ARN",
  "loadBalancers": [
    {
      "targetGroupArn": "$TARGET_GROUP_ARN",
      "containerName": "testmon",
      "containerPort": 80
    }
  ],
  "desiredCount": $DESIRED_TASK_COUNT,
  "launchType": "FARGATE",
  "platformVersion": "LATEST",
  "taskDefinition": "$TASK_DEFINITION_ARN",
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 100
  },
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": [
        "$ECS_SUBNET_ONE",
        "$ECS_SUBNET_TWO"
      ],
      "securityGroups": [
        "$ECS_SECURITY_GROUP"
      ],
      "assignPublicIp": "DISABLED"
    }
  },
  "healthCheckGracePeriodSeconds": 0,
  "schedulingStrategy": "REPLICA",
  "enableECSManagedTags": false
}
EOF
)

create_ecs_service
