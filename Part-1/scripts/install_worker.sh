#!/bin/bash

set -e

TOKEN="iot-cluster-token"

echo "[WORKER] Updating packages..."
apt-get update -y

echo "[WORKER] Installing curl..."
apt-get install -y curl

echo "[WORKER] Waiting for K3s server API..."
until curl -k https://192.168.56.110:6443/ping; do
  sleep 2
done

echo "[WORKER] Installing K3s agent..."
curl -sfL https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" sh -

echo "[WORKER] K3s agent installation completed."