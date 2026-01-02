#!/bin/bash

sudo apt-get update
sudo apt-get install -y curl
sudo touch /vagrant/confs/server_token.txt

# Set Flannel (network overlay for cross-node pod communication) to use eth1 in VM setup
curl -L https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=192.168.56.110 --flannel-iface=eth1" sh - 

sudo apt install -y vim

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/confs/server_token.txt
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/confs/ # Copy kubeconfig file to shared folder
sudo apt install -y net-tools # Install net-tools for ifconfig
export PATH=$PATH:/sbin:/usr/sbin
