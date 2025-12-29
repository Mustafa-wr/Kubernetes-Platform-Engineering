#!/bin/bash
sudo apt-get update
sudo apt-get install -y curl

K3S_TOKEN="/vagrant/confs/server_token.txt"

curl -L https://get.k3s.io | K3S_URL="https://192.168.56.110:6443" K3S_TOKEN_FILE=${K3S_TOKEN}  INSTALL_K3S_EXEC="--flannel-iface=eth1" sh -
sudo rm -rf /vagrant/confs/*
sudo apt install -y net-tools
export PATH=$PATH:/sbin:/usr/sbin
