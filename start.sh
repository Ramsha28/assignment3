#!/bin/bash

# ==============================
# Assignment 3 Startup Script
# ==============================

cd ~/assignment3 || exit

echo "Starting Minikube..."
minikube start --driver=docker --memory=2048 --cpus=2

echo "Waiting for Minikube to be ready..."
kubectl wait --for=condition=Ready node/minikube --timeout=120s

echo "Applying core Kubernetes resources..."

# 1. Namespace first
kubectl apply -f k8s/namespace.yml
sleep 2

# 2. Secrets & ConfigMaps (must exist before pods)
kubectl apply -f k8s/secrets/mysql-secret.yml
kubectl apply -f k8s/config/flask-configmap.yml

# 3. Storage (PV → PVC order is important)
kubectl apply -f k8s/mysql-pv.yml
kubectl apply -f k8s/mysql-pvc.yml

# 4. Database first (Flask depends on it)
kubectl apply -f k8s/deployments/mysql-deployment.yml
kubectl apply -f k8s/services/mysql-service.yml

echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=Ready pod -l app=mysql -n assignment3 --timeout=180s

# 5. Backend API
kubectl apply -f k8s/deployments/flask-deployment.yml
kubectl apply -f k8s/services/flask-service.yml

# 6. Frontend proxy (Nginx)
kubectl apply -f k8s/config/nginx-configmap.yml
kubectl apply -f k8s/deployments/nginx-deployment.yml
kubectl apply -f k8s/services/nginx-service.yml

echo "Waiting for all pods..."
kubectl wait --for=condition=Ready pod --all -n assignment3 --timeout=240s

echo ""
echo "============================="
echo "Deployment Status"
echo "============================="
kubectl get all -n assignment3

echo ""
echo "============================="
echo "Application URL"
echo "============================="
minikube service nginx -n assignment3 --url
