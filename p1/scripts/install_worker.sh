#!/bin/bash
SERVER_URL="https://192.168.56.110:6443"
K3S_TOKEN_FILE="/vagrant/confs/server_token.txt"

curl -sfL https://get.k3s.io | K3S_URL=${SERVER_URL} K3S_TOKEN_FILE=${K3S_TOKEN_FILE}  INSTALL_K3S_EXEC="--flannel-iface=eth1" sh - && echo "K3s Agent is Running ......."
# sudo rm -rf /vagrant/.confs
sudo apt install -y net-tools > /dev/null
echo "Worker installé et connecté au Master."