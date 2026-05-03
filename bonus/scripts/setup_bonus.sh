#!/bin/bash
set -e
echo "⚡ FAST DEFENSE SETUP (MINIMAL GITOPS)"

CLUSTER="iot-cluster"
GITLAB_NS="gitlab"
ARGO_NS="argocd"
DEV_NS="dev"

# =====================================================
# 1. TOOLS CHECK
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
# 2. CLUSTER
# =====================================================
echo "📦 Checking cluster..."
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "🚀 Creating cluster..."
  k3d cluster delete $CLUSTER || true
  k3d cluster create $CLUSTER
  kubectl config use-context k3d-$CLUSTER
fi

# =====================================================
# 2.5 PRELOAD IMAGES
# =====================================================
echo "📦 Preloading GitLab required images..."
docker pull bitnamilegacy/postgresql:16.6.0 || true
docker pull bitnamilegacy/postgres-exporter:0.15.0-debian-11-r7 || true
docker pull bitnamilegacy/redis:7.2.4-debian-12-r9 || true
docker pull bitnamilegacy/redis-exporter:1.58.0-debian-12-r4 || true
k3d image import bitnamilegacy/postgresql:16.6.0 -c $CLUSTER || true
k3d image import bitnamilegacy/postgres-exporter:0.15.0-debian-11-r7 -c $CLUSTER || true
k3d image import bitnamilegacy/redis:7.2.4-debian-12-r9 -c $CLUSTER || true
k3d image import bitnamilegacy/redis-exporter:1.58.0-debian-12-r4 -c $CLUSTER || true
echo "✅ GitLab images preloaded"

# =====================================================
# 3. NAMESPACES
# =====================================================
kubectl create namespace $GITLAB_NS --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $ARGO_NS --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $DEV_NS --dry-run=client -o yaml | kubectl apply -f -

# =====================================================
# 4. GITLAB
# =====================================================
echo "🚀 Installing GitLab..."
helm repo add gitlab https://charts.gitlab.io >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  --set global.hosts.domain=localhost \
  --set global.hosts.https=false \
  --set global.ingress.configureCertmanager=false \
  --set prometheus.install=false \
  --set grafana.enabled=false \
  --set gitlab-runner.install=false \
  --set global.registry.enabled=false \
  --set gitlab.kas.enabled=false \
  --set gitlab.sidekiq.enabled=false \
  --set gitlab.toolbox.enabled=false \
  --set global.pages.enabled=false \
  --set postgresql.install=true \
  --set redis.install=true \
  --timeout 900s

# =====================================================
# 5. ARGO CD
# =====================================================
echo "🚀 Installing Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1
helm upgrade --install argocd argo/argo-cd \
  -n $ARGO_NS \
  --timeout 600s

echo ""
echo "🎉 SETUP DONE"
echo ""
echo "👉 Wait for pods then run: ./deploy.sh"
echo "👉 Check pods: kubectl get pods -n gitlab -w"
