#!/bin/bash
# =============================================================
# Create VPC, ECS Cluster, and deploy services
# Prerequisites: AWS CLI configured, images already in ECR
# Usage: AWS_REGION=us-east-1 AWS_ACCOUNT_ID=123456789012 bash create-ecs-infra.sh
# =============================================================

set -e

AWS_REGION=${AWS_REGION:-"us-east-1"}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
CLUSTER_NAME="flask-express-cluster"

echo "=== Step 1: Create VPC ==="
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $AWS_REGION \
  --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=flask-express-vpc
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "VPC created: $VPC_ID"

# Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region $AWS_REGION \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Internet Gateway: $IGW_ID"

# Public Subnets (2 AZs for ALB requirement)
SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 --availability-zone ${AWS_REGION}a \
  --query 'Subnet.SubnetId' --output text)
SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 --availability-zone ${AWS_REGION}b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id $SUBNET1_ID --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $SUBNET2_ID --map-public-ip-on-launch
echo "Subnets: $SUBNET1_ID, $SUBNET2_ID"

# Route Table
RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_ID \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET1_ID
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET2_ID
echo "Route table configured"

echo ""
echo "=== Step 2: Security Groups ==="
# Backend SG
BACKEND_SG=$(aws ec2 create-security-group \
  --group-name flask-backend-sg --description "Flask backend SG" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $BACKEND_SG \
  --protocol tcp --port 5000 --cidr 10.0.0.0/16

# Frontend SG
FRONTEND_SG=$(aws ec2 create-security-group \
  --group-name express-frontend-sg --description "Express frontend SG" \
  --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $FRONTEND_SG \
  --protocol tcp --port 3000 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $FRONTEND_SG \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Security groups: backend=$BACKEND_SG, frontend=$FRONTEND_SG"

echo ""
echo "=== Step 3: ECS Cluster ==="
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION
echo "Cluster created: $CLUSTER_NAME"

echo ""
echo "=== Step 4: IAM Role for ECS Task Execution ==="
aws iam create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}' 2>/dev/null || echo "Role already exists"
aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true

echo ""
echo "=== Step 5: Register Task Definitions ==="

# Flask backend task
aws ecs register-task-definition --region $AWS_REGION \
  --family flask-backend-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 --memory 512 \
  --execution-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole \
  --container-definitions "[
    {
      \"name\": \"flask-backend\",
      \"image\": \"${ECR_REGISTRY}/flask-backend:latest\",
      \"portMappings\": [{\"containerPort\": 5000, \"protocol\": \"tcp\"}],
      \"essential\": true,
      \"logConfiguration\": {
        \"logDriver\": \"awslogs\",
        \"options\": {
          \"awslogs-group\": \"/ecs/flask-backend\",
          \"awslogs-region\": \"${AWS_REGION}\",
          \"awslogs-stream-prefix\": \"ecs\"
        }
      }
    }
  ]"

# Express frontend task
aws ecs register-task-definition --region $AWS_REGION \
  --family express-frontend-task \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 --memory 512 \
  --execution-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole \
  --container-definitions "[
    {
      \"name\": \"express-frontend\",
      \"image\": \"${ECR_REGISTRY}/express-frontend:latest\",
      \"portMappings\": [{\"containerPort\": 3000, \"protocol\": \"tcp\"}],
      \"essential\": true,
      \"environment\": [
        {\"name\": \"FLASK_URL\", \"value\": \"http://flask-backend.local:5000\"}
      ],
      \"logConfiguration\": {
        \"logDriver\": \"awslogs\",
        \"options\": {
          \"awslogs-group\": \"/ecs/express-frontend\",
          \"awslogs-region\": \"${AWS_REGION}\",
          \"awslogs-stream-prefix\": \"ecs\"
        }
      }
    }
  ]"

echo ""
echo "=== Step 6: Create ECS Services ==="

# Backend service
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name flask-backend-service \
  --task-definition flask-backend-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1_ID,$SUBNET2_ID],securityGroups=[$BACKEND_SG],assignPublicIp=ENABLED}" \
  --region $AWS_REGION

# Frontend service
aws ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name express-frontend-service \
  --task-definition express-frontend-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1_ID,$SUBNET2_ID],securityGroups=[$FRONTEND_SG],assignPublicIp=ENABLED}" \
  --region $AWS_REGION

echo ""
echo "=== ECS Deployment Complete ==="
echo "Cluster  : $CLUSTER_NAME"
echo "VPC      : $VPC_ID"
echo "Check task public IPs in AWS Console > ECS > Clusters > $CLUSTER_NAME > Tasks"
echo ""
echo "Save these values for cleanup:"
echo "VPC_ID=$VPC_ID"
echo "SUBNET1_ID=$SUBNET1_ID"
echo "SUBNET2_ID=$SUBNET2_ID"
echo "BACKEND_SG=$BACKEND_SG"
echo "FRONTEND_SG=$FRONTEND_SG"
echo "IGW_ID=$IGW_ID"
