#!/bin/bash

set -e

TOKEN="iot-cluster-token"

echo "[SERVER] Updating packages..."
apt-get update -y

echo "[SERVER] Installing curl..."
apt-get install -y curl

echo "[SERVER] Installing K3s server..."
curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="server --node-ip=192.168.56.110 --advertise-address=192.168.56.110" sh -

echo "[SERVER] Preparing kubeconfig for vagrant user..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 600 /home/vagrant/.kube/config

echo "[SERVER] K3s server installation completed."