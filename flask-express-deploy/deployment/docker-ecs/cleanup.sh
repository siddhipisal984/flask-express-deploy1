#!/bin/bash
# Stop/delete ECS services to avoid charges
# Fill in the values printed at the end of create-ecs-infra.sh

CLUSTER_NAME="flask-express-cluster"
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo ">>> Scaling down ECS services..."
aws ecs update-service --cluster $CLUSTER_NAME --service flask-backend-service --desired-count 0 --region $AWS_REGION
aws ecs update-service --cluster $CLUSTER_NAME --service express-frontend-service --desired-count 0 --region $AWS_REGION

echo ">>> Deleting ECS services..."
aws ecs delete-service --cluster $CLUSTER_NAME --service flask-backend-service --region $AWS_REGION
aws ecs delete-service --cluster $CLUSTER_NAME --service express-frontend-service --region $AWS_REGION

echo ">>> Deleting ECS cluster..."
aws ecs delete-cluster --cluster $CLUSTER_NAME --region $AWS_REGION

echo "Done. Remember to also delete ECR images and VPC resources to avoid storage costs."
