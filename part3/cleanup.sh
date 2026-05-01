#!/bin/bash
set -e

echo "🧹 PART 3 — FULL CLEANUP SCRIPT"

CLUSTER="iot-cluster"
ARGO_NS="argocd"
DEV_NS="dev"
APP_NAME="demo-app"

# =====================================================
# 1. STOP PORT-FORWARD (IMPORTANT)
# =====================================================
echo "🛑 Killing port-forward processes..."
pkill -f "kubectl port-forward" || true

# =====================================================
# 2. DELETE ARGO CD APPLICATION
# =====================================================
echo "🗑️ Deleting ArgoCD application..."
kubectl delete application $APP_NAME -n $ARGO_NS --ignore-not-found

# =====================================================
# 3. DELETE NAMESPACES
# =====================================================
echo "🗑️ Deleting namespaces..."
kubectl delete namespace $ARGO_NS --ignore-not-found
kubectl delete namespace $DEV_NS --ignore-not-found

# =====================================================
# 4. DELETE CLUSTER (FULL RESET)
# =====================================================
echo "🧨 Deleting k3d cluster..."
k3d cluster delete $CLUSTER || true

# =====================================================
# 5. CLEAN KUBECTL CONTEXT (optional but clean)
# =====================================================
echo "🧽 Cleaning kubeconfig context..."
kubectl config delete-context k3d-$CLUSTER || true
kubectl config delete-cluster $CLUSTER || true

echo "✅ CLEANUP DONE — SYSTEM RESET"
