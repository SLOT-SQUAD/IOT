#!/bin/bash

set -e

echo "🚀 CLEAN FULL BONUS SETUP (AUTO-BOOTSTRAP)"

CLUSTER="iot-cluster"
NAMESPACE_ARGO="argocd"
NAMESPACE_DEV="dev"

# =====================================================
# 0. INSTALL MISSING TOOLS
# =====================================================
echo "🔍 Checking / installing tools..."

install_k3d() {
  echo "📦 Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_kubectl() {
  echo "📦 Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
}

install_helm() {
  echo "📦 Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

# --- Docker (required, not auto-installed)
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker not found."
  echo "👉 Install Docker manually first: https://docs.docker.com/get-docker/"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker not running. Start Docker first."
  exit 1
fi

# --- k3d
if ! command -v k3d >/dev/null 2>&1; then
  install_k3d
fi

# --- kubectl
if ! command -v kubectl >/dev/null 2>&1; then
  install_kubectl
fi

# --- helm
if ! command -v helm >/dev/null 2>&1; then
  install_helm
fi

echo "✅ All tools ready"