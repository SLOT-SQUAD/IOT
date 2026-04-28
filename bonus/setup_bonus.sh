#!/bin/bash

set -e

echo "⚡ FAST DEFENSE SETUP (MINIMAL GITOPS)"

CLUSTER="iot-cluster"
GITLAB_NS="gitlab"
ARGO_NS="argocd"
DEV_NS="dev"

# =====================================================
# 1. TOOLS CHECK (LIGHT)
# =====================================================
echo "🔍 Checking tools..."

for cmd in docker kubectl helm k3d; do
  command -v $cmd >/dev/null 2>&1 || {
    echo "❌ Missing $cmd"
    exit 1
  }
done

docker info >/dev/null 2>&1 || {
  echo "❌ Docker not running"
  exit 1
}

echo "✅ Tools OK"

# =====================================================
# 2. CLUSTER (FAST REUSE OR CREATE)
# =====================================================
echo "📦 Checking cluster..."

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "🚀 Creating cluster..."
  k3d cluster delete $CLUSTER || true
  k3d cluster create $CLUSTER
  kubectl config use-context k3d-$CLUSTER
fi

# =====================================================
# 3. NAMESPACES (ONLY WHAT MATTERS)
# =====================================================
kubectl create namespace $GITLAB_NS --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $ARGO_NS --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $DEV_NS --dry-run=client -o yaml | kubectl apply -f -

# =====================================================
# 4. GITLAB (MINIMAL CONFIG)
# =====================================================
echo "🚀 Installing GitLab..."

helm repo add gitlab https://charts.gitlab.io >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

helm upgrade --install gitlab gitlab/gitlab \
  -n $GITLAB_NS \
  --set global.hosts.domain=localhost \
  --set global.hosts.https=false \
  --set certmanager-issuer.email=admin@localhost \
  --timeout 1200s

# =====================================================
# 5. ARGO CD
# =====================================================
echo "🚀 Installing Argo CD..."

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

helm upgrade --install argocd argo/argo-cd \
  -n $ARGO_NS \
  --timeout 600s

# =====================================================
# 6. DONE — NO WAITING (IMPORTANT FOR SPEED)
# =====================================================
echo "⚡ NOT WAITING FOR PODS (FAST MODE)"

echo ""
echo "🎉 READY FOR DEFENSE"
echo ""
echo "👉 GitLab:"
echo "kubectl port-forward svc/gitlab-webservice-default -n gitlab 8082:8181"
echo ""
echo "👉 Argo CD:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "👉 Get GitLab password:"
echo "kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 -d"