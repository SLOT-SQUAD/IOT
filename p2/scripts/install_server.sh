#!/bin/bash

set -e

echo "[SERVER] Updating packages..."
sudo apt-get update -y

echo "[SERVER] Installing dependencies..."
sudo apt-get install -y curl net-tools

echo "[SERVER] Detecting private network interface..."
PRIVATE_IFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.56\.110\/24/ {print $2}')

if [ -z "$PRIVATE_IFACE" ]; then
  echo "[ERROR] Could not detect interface for 192.168.56.110"
  ip a
  exit 1
fi

echo "[SERVER] Private interface detected: $PRIVATE_IFACE"

echo "[SERVER] Installing K3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --bind-address=192.168.56.110 \
  --advertise-address=192.168.56.110 \
  --node-ip=192.168.56.110 \
  --flannel-iface=$PRIVATE_IFACE \
  --write-kubeconfig-mode=644" sh -

echo "[SERVER] Waiting for k3s systemd service..."
until sudo systemctl is-active --quiet k3s; do
  sudo systemctl status k3s --no-pager || true
  sleep 5
done

echo "[SERVER] Waiting for port 6443..."
until sudo ss -lnt | grep -q ':6443'; do
  sleep 5
done

echo "[SERVER] Waiting for Kubernetes API /readyz..."
until sudo kubectl get --raw='/readyz' >/dev/null 2>&1; do
  sleep 5
done

echo "[SERVER] Waiting for node to be Ready..."
NODE_NAME=$(hostname | tr '[:upper:]' '[:lower:]')

until sudo kubectl get node "$NODE_NAME" 2>/dev/null | grep -q " Ready "; do
  sudo kubectl get nodes || true
  sleep 5
done

echo "[SERVER] Preparing kubeconfig for vagrant user..."
mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
sudo chmod 600 /home/vagrant/.kube/config

grep -qxF 'export KUBECONFIG=/home/vagrant/.kube/config' /home/vagrant/.bashrc || \
  echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> /home/vagrant/.bashrc

echo "[SERVER] K3s server installed successfully and node is Ready."