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

echo "[SERVER] Waiting for K3s to be ready..."
until sudo kubectl get nodes; do
  sleep 2
done

echo "[SERVER] Preparing kubeconfig for vagrant user..."
mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
sudo chmod 600 /home/vagrant/.kube/config

grep -qxF 'export KUBECONFIG=/home/vagrant/.kube/config' /home/vagrant/.bashrc || \
  echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> /home/vagrant/.bashrc

echo "[SERVER] K3s server installed successfully."