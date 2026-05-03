#!/bin/bash
echo "🚀 START SCRIPT"
set -e
echo "🛠️ SAFE TOOLCHAIN INSTALLER (DOCKER + K3D + KUBECTL + HELM)"

K3D_VERSION="v5.8.3"
HELM_VERSION="v3.14.4"
KUBECTL_VERSION="v1.29.0"

# =====================================================
# 1. CHECK ROOT TOOLS
# =====================================================
echo "🔍 Checking system for curl and sudo..."
sudo apt-get update -y > /dev/null
sudo apt-get install -y curl ca-certificates gnupg > /dev/null

# =====================================================
# 2. INSTALL/CHECK DOCKER (Debian Corrected)
# =====================================================
if ! command -v docker >/dev/null 2>&1; then
    echo "📦 Docker not found. Installing Docker Engine for Debian..."
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources using 'debian' and the current codename
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker $USER
    echo "✅ Docker installed."
else
    echo "✅ Docker already installed"
fi

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "⚙️ Starting Docker service..."
    sudo systemctl start docker
fi

# =====================================================
# 3. INSTALL K3D
# =====================================================
if ! command -v k3d >/dev/null 2>&1; then
    echo "📦 Installing k3d $K3D_VERSION ..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | \
      TAG=$K3D_VERSION bash
else
    echo "✅ k3d already installed"
fi

# =====================================================
# 4. INSTALL KUBECTL
# =====================================================
if ! command -v kubectl >/dev/null 2>&1; then
    echo "📦 Installing kubectl $KUBECTL_VERSION ..."
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "✅ kubectl already installed"
fi

# =====================================================
# 5. INSTALL HELM
# =====================================================
if ! command -v helm >/dev/null 2>&1; then
    echo "📦 Installing Helm $HELM_VERSION ..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | \
      bash -s -- --version $HELM_VERSION
else
    echo "✅ helm already installed"
fi

# =====================================================
# 6. VERIFY ALL TOOLS
# =====================================================
echo ""
echo "🔎 Final verification..."
for tool in docker k3d kubectl helm; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✅ $tool: version unknown or installed"
    else
        echo "❌ Missing: $tool"
        exit 1
    fi
done

echo ""
echo "🎉 ALL TOOLS INSTALLED SUCCESSFULLY"
