#!/bin/bash
echo "🧹 CLEANING UP EVERYTHING"

# =====================================================
# 1. KILL PORT FORWARDS
# =====================================================
echo "🔌 Killing port-forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true

# =====================================================
# 2. DELETE ARGOCD APP
# =====================================================
echo "🗑️ Deleting ArgoCD app..."
kubectl delete application playground -n argocd --ignore-not-found=true 2>/dev/null || true

# =====================================================
# 3. FORCE DELETE PODS
# =====================================================
echo "🗑️ Deleting pods..."
kubectl delete pods --all -n gitlab --force --grace-period=0 2>/dev/null || true
kubectl delete pods --all -n argocd --force --grace-period=0 2>/dev/null || true
kubectl delete pods --all -n dev --force --grace-period=0 2>/dev/null || true

# =====================================================
# 4. REMOVE STUCK PVC FINALIZERS
# =====================================================
echo "🗑️ Removing stuck PVCs..."
for pvc in $(kubectl get pvc -n gitlab -o name 2>/dev/null); do
  kubectl patch $pvc -n gitlab \
    -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
done

# =====================================================
# 5. DELETE NAMESPACES
# =====================================================
echo "🗑️ Deleting namespaces..."
kubectl delete namespace gitlab --force --grace-period=0 2>/dev/null || true
kubectl delete namespace argocd --force --grace-period=0 2>/dev/null || true
kubectl delete namespace dev --force --grace-period=0 2>/dev/null || true

# =====================================================
# 6. DELETE K3D CLUSTER
# =====================================================
echo "🗑️ Deleting k3d cluster..."
k3d cluster delete iot-cluster 2>/dev/null || true
k3d cluster delete --all 2>/dev/null || true

# =====================================================
# 7. STOP AND REMOVE ALL CONTAINERS
# =====================================================
echo "🗑️ Removing all containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm -f $(docker ps -aq) 2>/dev/null || true

# =====================================================
# 8. REMOVE ALL DOCKER IMAGES
# =====================================================
echo "🗑️ Removing all Docker images..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

# =====================================================
# 9. REMOVE ALL VOLUMES + NETWORKS
# =====================================================
echo "🗑️ Removing volumes and networks..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true
docker network rm $(docker network ls -q) 2>/dev/null || true

# =====================================================
# 10. FINAL DOCKER PRUNE (CATCH EVERYTHING)
# =====================================================
echo "🧹 Final Docker prune..."
docker system prune -af --volumes 2>/dev/null || true
docker builder prune -af 2>/dev/null || true

# =====================================================
# 11. CLEAN HELM CACHE
# =====================================================
echo "🧹 Cleaning Helm cache..."
rm -rf ~/.cache/helm 2>/dev/null || true
rm -rf ~/.config/helm 2>/dev/null || true

# =====================================================
# 12. CLEAN K3D CACHE
# =====================================================
echo "🧹 Cleaning k3d cache..."
rm -rf ~/.k3d 2>/dev/null || true

# =====================================================
# 13. FINAL SPACE CHECK
# =====================================================
echo ""
echo "💾 Disk space after cleanup:"
df -h /goinfre 2>/dev/null || df -h /
echo ""
echo "🐳 Docker status after cleanup:"
docker system df
echo ""
echo "✅ CLEANUP DONE — totally clean like fresh install"
