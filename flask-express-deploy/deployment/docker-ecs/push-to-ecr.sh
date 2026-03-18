#!/bin/bash
# =============================================================
# Push Docker images to Amazon ECR
# Prerequisites: AWS CLI configured, Docker running
# Usage: AWS_REGION=us-east-1 AWS_ACCOUNT_ID=123456789012 bash push-to-ecr.sh
# =============================================================

set -e

AWS_REGION=${AWS_REGION:-"us-east-1"}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo ">>> Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# ---- Create ECR repositories ----
echo ">>> Creating ECR repositories..."
aws ecr create-repository --repository-name flask-backend --region $AWS_REGION 2>/dev/null || echo "flask-backend repo already exists"
aws ecr create-repository --repository-name express-frontend --region $AWS_REGION 2>/dev/null || echo "express-frontend repo already exists"

# ---- Build and push Flask backend ----
echo ">>> Building Flask backend image..."
docker build -t flask-backend ../../backend/
docker tag flask-backend:latest $ECR_REGISTRY/flask-backend:latest
docker push $ECR_REGISTRY/flask-backend:latest
echo "Flask image pushed: $ECR_REGISTRY/flask-backend:latest"

# ---- Build and push Express frontend ----
echo ">>> Building Express frontend image..."
docker build -t express-frontend ../../frontend/
docker tag express-frontend:latest $ECR_REGISTRY/express-frontend:latest
docker push $ECR_REGISTRY/express-frontend:latest
echo "Express image pushed: $ECR_REGISTRY/express-frontend:latest"

echo ""
echo "=== Images pushed to ECR ==="
echo "Backend : $ECR_REGISTRY/flask-backend:latest"
echo "Frontend: $ECR_REGISTRY/express-frontend:latest"
echo ""
echo "Next: Run create-ecs-infra.sh to deploy on ECS"
