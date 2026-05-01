#!/bin/bash
set -e

echo "🚀 PART 3 — FULL ARGO CD AUTO SETUP"

CLUSTER="iot-cluster"
ARGO_NS="argocd"
DEV_NS="dev"

REPO_URL="https://github.com/SLOT-SQUAD/IOT.git"
APP_PATH="part3/deployApp"

# =====================================================
# 1. CLEAN CLUSTER
# =====================================================
echo "🧹 Reset cluster..."
k3d cluster delete $CLUSTER || true

echo "🚀 Creating cluster..."
k3d cluster create $CLUSTER
kubectl config use-context k3d-$CLUSTER

# =====================================================
# 2. NAMESPACE
# =====================================================
kubectl create namespace $ARGO_NS
kubectl create namespace $DEV_NS

# =====================================================
# 3. INSTALL ARGO CD
# =====================================================
echo "🚀 Installing ArgoCD..."

kubectl apply -n $ARGO_NS -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.11.3/manifests/install.yaml

# =====================================================
# 4. WAIT FOR ARGO (REAL FIX — NO SLEEP)
# =====================================================
echo "⏳ Waiting for ArgoCD to be ready..."

kubectl wait --for=condition=available deployment argocd-server -n $ARGO_NS --timeout=300s
kubectl wait --for=condition=available deployment argocd-repo-server -n $ARGO_NS --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-application-controller -n $ARGO_NS --timeout=300s

echo "✅ ArgoCD is ready"
# =====================================================
# 5. GET PASSWORD
# =====================================================
ARGO_PWD=$(kubectl -n $ARGO_NS get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "🔐 ArgoCD password: $ARGO_PWD"

# =====================================================
# 6. PORT FORWARD (BACKGROUND)
# =====================================================
echo "🌐 Starting port-forward..."

kubectl port-forward svc/argocd-server -n $ARGO_NS 8080:443 >/dev/null 2>&1 &

sleep 5

# =====================================================
# 7. CREATE ARGO APP (FROM YOUR REPO)
# =====================================================
echo "🚀 Creating ArgoCD Application..."

kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
  namespace: $ARGO_NS
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: HEAD
    path: $APP_PATH
  destination:
    server: https://kubernetes.default.svc
    namespace: $DEV_NS
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# =====================================================
# 8. FORCE SYNC (IMPORTANT FOR DEFENSE)
# =====================================================
echo "🔄 Syncing app..."

kubectl patch application demo-app -n $ARGO_NS \
  --type merge \
  -p '{"operation":{"sync":{}}}'

# =====================================================
# 9. WAIT FOR APP
# =====================================================
echo "⏳ Waiting for app deployment..."

kubectl wait --for=condition=available deployment nginx -n $DEV_NS --timeout=120s

echo "✅ App deployed"

# =====================================================
# 10. TEST
# =====================================================
echo ""
echo "🎉 READY FOR TEST"
echo ""
echo "👉 Open ArgoCD UI:"
echo "https://localhost:8080"
echo "Username: admin"
echo "Password: $ARGO_PWD"
echo ""
echo "👉 Check pods:"
echo "kubectl get pods -n dev"
echo ""
echo "👉 Access nginx:"
echo "kubectl port-forward svc/nginx -n dev 8081:80"
echo "http://localhost:8081"
