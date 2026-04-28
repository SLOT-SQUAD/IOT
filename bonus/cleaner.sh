#!/bin/bash

echo "🧹 SAFE SYSTEM CLEANUP STARTING..."

# ---------------------------
# 1. CLEAN DOCKER (BIGGEST IMPACT)
# ---------------------------
echo "🐳 Cleaning Docker..."
docker system prune -a -f || true
docker volume prune -f || true

# ---------------------------
# 2. CLEAN KUBERNETES UNUSED RESOURCES
# ---------------------------
echo "☸️ Cleaning Kubernetes unused resources..."

kubectl delete pod --all --field-selector=status.phase=Succeeded -A || true
kubectl delete pod --all --field-selector=status.phase=Failed -A || true

# ---------------------------
# 3. CLEAN HELM CACHE
# ---------------------------
echo "⛵ Cleaning Helm cache..."
helm repo update
helm cache clean || true

# ---------------------------
# 4. CLEAN SYSTEM LOGS (SAFE)
# ---------------------------
echo "📜 Cleaning system logs..."
sudo journalctl --vacuum-time=1d || true

# ---------------------------
# 5. CLEAN TEMP FILES
# ---------------------------
echo "🗑️ Cleaning temp files..."
sudo rm -rf /tmp/* || true

echo "✅ CLEANUP DONE (SAFE MODE)"
