#!/bin/bash

set -e

echo "[APPS] Waiting for K3s node to be Ready..."
until kubectl get nodes 2>/dev/null | grep -q " Ready "; do
  sleep 5
done

echo "[APPS] Waiting for CoreDNS..."
until kubectl -n kube-system get pods 2>/dev/null | grep coredns | grep -q Running; do
  sleep 5
done

echo "[APPS] Waiting for Traefik deployment..."
until kubectl -n kube-system get deployment traefik >/dev/null 2>&1; do
  sleep 5
done

kubectl -n kube-system rollout status deployment/traefik --timeout=300s

echo "[APPS] Waiting for Traefik LoadBalancer IP..."
until kubectl -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null | grep -q "192.168.56.110"; do
  kubectl -n kube-system get svc traefik || true
  sleep 5
done

echo "[APPS] Deploying applications..."
kubectl apply -f /vagrant/confs/app1.yaml
kubectl apply -f /vagrant/confs/app2.yaml
kubectl apply -f /vagrant/confs/app3.yaml

echo "[APPS] Waiting for application deployments..."
kubectl rollout status deployment/app1 --timeout=300s
kubectl rollout status deployment/app2 --timeout=300s
kubectl rollout status deployment/app3 --timeout=300s

echo "[APPS] Deploying ingress..."
kubectl apply -f /vagrant/confs/ingress.yaml

echo "[APPS] Waiting for ingress address..."
until kubectl get ingress apps-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null | grep -q "192.168.56.110"; do
  kubectl get ingress apps-ingress || true
  sleep 5
done

echo "[APPS] Applications deployed successfully."
kubectl get pods
kubectl get svc
kubectl get ingress