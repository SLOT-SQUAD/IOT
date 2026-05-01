curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=192.168.56.110 --node-ip=192.168.56.110 --flannel-iface=eth1 --write-kubeconfig-mode 644" sh - && echo "k3s server installed successfully......"

echo "Attente de la génération du token..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 2
done

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/server_token.txt
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/confs/k3s.yaml

mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

sudo apt install -y net-tools > /dev/null

echo "Installation du Master terminée et kubectl est prêt !"