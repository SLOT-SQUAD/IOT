#!/bin/bash
echo "🧹 CLEANING UP EVERYTHING"

# Free docker space FIRST
echo "🧹 Freeing Docker space..."
docker system prune -af --volumes 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

# Kill port-forwards
pkill -f "kubectl port-forward" 2>/dev/null || true

# Delete ArgoCD app
kubectl delete application playground -n argocd --ignore-not-found=true

# Force delete pods
kubectl delete pods --all -n gitlab --force --grace-period=0 2>/dev/null || true
kubectl delete pods --all -n argocd --force --grace-period=0 2>/dev/null || true
kubectl delete pods --all -n dev --force --grace-period=0 2>/dev/null || true

# Remove finalizers from stuck PVCs
for pvc in $(kubectl get pvc -n gitlab -o name 2>/dev/null); do
  kubectl patch $pvc -n gitlab \
    -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done

# Delete namespaces
kubectl delete namespace gitlab --force --grace-period=0 2>/dev/null || true
kubectl delete namespace argocd --force --grace-period=0 2>/dev/null || true
kubectl delete namespace dev --force --grace-period=0 2>/dev/null || true

# Delete k3d cluster
k3d cluster delete iot-cluster 2>/dev/null || true

# Final space check
echo ""
echo "💾 Disk space after cleanup:"
df -h /goinfre 2>/dev/null || df -h /
echo "✅ CLEANUP DONE — ready for fresh setup"
