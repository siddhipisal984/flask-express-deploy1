#!/bin/bash
# =============================================================
# Deploy Flask + Express on local Minikube Kubernetes cluster
# Prerequisites: minikube, kubectl, docker installed
# =============================================================

set -e

echo ">>> Starting Minikube..."
minikube start

echo ">>> Pointing Docker to Minikube's Docker daemon..."
eval $(minikube docker-env)

echo ">>> Building Flask backend image inside Minikube..."
docker build -t flask-backend:latest ../../backend/

echo ">>> Building Express frontend image inside Minikube..."
docker build -t express-frontend:latest ../../frontend/

echo ">>> Applying Kubernetes manifests..."
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml

echo ">>> Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask-backend --timeout=60s
kubectl wait --for=condition=ready pod -l app=express-frontend --timeout=60s

echo ""
echo "=== Deployment Status ==="
kubectl get deployments
echo ""
kubectl get pods
echo ""
kubectl get services
echo ""

echo ">>> Getting frontend URL..."
minikube service express-frontend --url
