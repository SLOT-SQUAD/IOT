#!/bin/bash
set -e

echo "🚀 GitLab BONUS SETUP (FINAL CLEAN VERSION)"

NAMESPACE="gitlab"
RELEASE="gitlab"

# ---------------------------
# 1. CLEAN ENVIRONMENT SAFELY
# ---------------------------
echo "🧹 Cleaning previous installation..."

helm uninstall $RELEASE -n $NAMESPACE || true
kubectl delete namespace $NAMESPACE --ignore-not-found=true || true

# wait for full deletion
while kubectl get namespace $NAMESPACE >/dev/null 2>&1; do
  echo "⏳ waiting for namespace deletion..."
  sleep 3
done

# ---------------------------
# 2. CREATE NAMESPACE
# ---------------------------
kubectl create namespace $NAMESPACE

# ---------------------------
# 3. HELM REPO (SAFE ADD)
# ---------------------------
echo "📦 Preparing Helm repository..."

if helm repo list | grep -q "^gitlab"; then
  echo "✔ GitLab repo already exists"
else
  helm repo add gitlab https://charts.gitlab.io
fi

helm repo update

# ---------------------------
# 4. MINIMAL VALUES (NO DEPRECATED FIELDS)
# ---------------------------
cat > values.yaml <<EOF
global:
  hosts:
    domain: localhost
    https: false
  ingress:
    enabled: false

nginx-ingress:
  enabled: false

prometheus:
  install: false

gitlab-runner:
  install: false

gitlab:
  webservice:
    ingress:
      enabled: false
  kas:
    ingress:
      enabled: false
  registry:
    ingress:
      enabled: false
  minio:
    ingress:
      enabled: false
EOF

# ---------------------------
# 5. INSTALL GITLAB
# ---------------------------
echo "📦 Installing GitLab (this may take a few minutes)..."

helm upgrade --install gitlab gitlab/gitlab \
  -n $NAMESPACE \
  -f values.yaml \
  --set certmanager-issuer.email=admin@localhost \
  --timeout 1200s

# ---------------------------
# 6. WAIT FOR CORE SERVICE
# ---------------------------
echo "⏳ Waiting for GitLab webservice..."

kubectl wait --for=condition=Ready pod \
  -l app=webservice \
  -n $NAMESPACE \
  --timeout=1200s || true

# ---------------------------
# 7. GET ROOT PASSWORD
# ---------------------------
echo "🔑 Fetching root password..."

PASS=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n $NAMESPACE \
  -o jsonpath="{.data.password}" | base64 -d)

echo "======================================"
echo "🎉 GitLab is READY"
echo "--------------------------------------"
echo "URL: http://localhost:8082"
echo "User: root"
echo "Password: $PASS"
echo "======================================"

# ---------------------------
# 8. ACCESS INSTRUCTIONS
# ---------------------------
echo "👉 Run this command in another terminal:"
echo "kubectl port-forward svc/gitlab-webservice-default -n gitlab 8082:8181"

echo ""
echo "Then open: http://localhost:8082"

# ---------------------------
# DONE
# ---------------------------
echo "✅ BONUS SETUP COMPLETE"