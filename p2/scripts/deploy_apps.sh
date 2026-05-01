#!/bin/bash

set -e

echo "[APPS] Waiting for K3s API..."
until kubectl get nodes; do
  sleep 2
done

echo "[APPS] Deploying applications..."
kubectl apply -f /vagrant/confs/app1.yaml
kubectl apply -f /vagrant/confs/app2.yaml
kubectl apply -f /vagrant/confs/app3.yaml

echo "[APPS] Deploying ingress..."
kubectl apply -f /vagrant/confs/ingress.yaml

echo "[APPS] Waiting for deployments..."
kubectl rollout status deployment/app1
kubectl rollout status deployment/app2
kubectl rollout status deployment/app3

echo "[APPS] Applications deployed successfully."
kubectl get pods
kubectl get svc
kubectl get ingress