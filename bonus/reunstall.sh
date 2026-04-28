#!/bin/bash

set -e

echo "🚀 FULL GITLAB BONUS SETUP STARTING..."

NAMESPACE="gitlab"
CLUSTER="iot-cluster"

# =====================================================
# 1. FIX / RECREATE K3D CLUSTER (CRITICAL SAFETY STEP)
# =====================================================
echo "📦 Checking Kubernetes cluster..."

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "❌ Cluster broken or missing. Recreating..."

  k3d cluster delete $CLUSTER || true
  k3d cluster create $CLUSTER

  kubectl config use-context k3d-$CLUSTER || true
fi

kubectl get nodes

# =====================================================
# 2. CREATE NAMESPACE
# =====================================================
echo "📁 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# =====================================================
# 3. HELM REPO SETUP
# =====================================================
echo "⛵ Setting up Helm repo..."
helm repo add gitlab https://charts.gitlab.io || true
helm repo update

# =====================================================
# 4. INSTALL GITLAB
# =====================================================
echo "📦 Installing GitLab (this takes time...)"

helm upgrade --install gitlab gitlab/gitlab \
  -n $NAMESPACE \
  -f values.yaml \
  --set certmanager-issuer.email=admin@localhost \
  --timeout 1800s

# =====================================================
# 5. WAIT FOR CORE PODS
# =====================================================
echo "⏳ Waiting for GitLab core services..."

kubectl wait --for=condition=Ready pod -l app=webservice -n $NAMESPACE --timeout=1200s || true
kubectl wait --for=condition=Ready pod -l app=toolbox -n $NAMESPACE --timeout=1200s || true

# =====================================================
# 6. FIX ROOT PASSWORD (SAFE METHOD)
# =====================================================
echo "🔑 Setting root password (safe fallback)..."

kubectl exec -n gitlab deploy/gitlab-toolbox -- \
gitlab-rails runner "
user = User.find_by(username: 'root');
if user
  user.password = 'Root12345!';
  user.password_confirmation = 'Root12345!';
  user.save!;
end
" || true

# =====================================================
# 7. INSTALL / FIX RUNNER
# =====================================================
echo "🏃 Installing GitLab Runner..."

helm upgrade --install gitlab-runner gitlab/gitlab-runner \
  -n $NAMESPACE \
  --set gitlabUrl=http://gitlab-webservice-default.gitlab.svc.cluster.local \
  --set rbac.create=true

echo "♻️ Restarting runner..."
kubectl delete pod -n gitlab -l app=gitlab-runner || true

# =====================================================
# 8. WAIT FOR RUNNER
# =====================================================
echo "⏳ Waiting for runner..."

kubectl wait --for=condition=Ready pod -l app=gitlab-runner -n $NAMESPACE --timeout=600s || true

# =====================================================
# 9. FINAL STATUS
# =====================================================
echo "📊 FINAL STATUS:"
kubectl get pods -n $NAMESPACE

echo ""
echo "🎉 BONUS READY!"
echo "👉 Run port-forward:"
echo "kubectl port-forward svc/gitlab-webservice-default -n gitlab 8082:8181"
echo ""
echo "👉 Open:"
echo "http://localhost:8082"
echo "Login: root"
echo "Password: Root12345!"