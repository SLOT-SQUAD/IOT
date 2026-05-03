#!/bin/bash
# No 'set -e' here so it doesn't crash if already logged in
CLUSTER="iot-cluster"
GITLAB_NS="gitlab"
ARGO_NS="argocd"
DEV_NS="dev"
REPO_NAME="test-bonus"

# =====================================================
# 1. GET FRESH PASSWORDS
# =====================================================
echo "🔍 Fetching fresh secrets..."
GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n $GITLAB_NS \
  -o jsonpath='{.data.password}' | base64 -d)

ARGO_PASS=$(kubectl get secret argocd-initial-admin-secret \
  -n $ARGO_NS \
  -o jsonpath='{.data.password}' | base64 -d)

# =====================================================
# 2. LOGIN TO ARGOCD CLI
# =====================================================
echo "🔌 Authenticating ArgoCD CLI..."
# We use --insecure because of self-signed certs in local k3d
argocd login localhost:8080 \
  --username admin \
  --password "$ARGO_PASS" \
  --insecure --grpc-web

# =====================================================
# 3. CONNECT REPO (Internal Cluster DNS)
# =====================================================
echo "📦 Linking GitLab Repo to ArgoCD..."
# Note: Using the internal service name so the cluster can talk to itself
argocd repo add \
  "http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/$REPO_NAME.git" \
  --username root \
  --password "$GITLAB_PASS" \
  --insecure-skip-server-verification || echo "⚠️ Repo might already be added, continuing..."

# =====================================================
# 4. CREATE / UPDATE APPLICATION
# =====================================================
echo "🚀 Applying ArgoCD Application Manifest..."
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: playground
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/$REPO_NAME.git
    targetRevision: main
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo "✅ Deployment triggered! Check https://localhost:8080"
