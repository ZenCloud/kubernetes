#!/bin/bash

node="$1"
user="$2"

function command {
  USERANDHOST="$user@$node"
  echo $USERANDHOST
  echo "~# ssh $USERANDHOST" "$1"
  ssh -oStrictHostKeyChecking=no $"$USERANDHOST" "$1"
}

# Init cluster
command "kubeadm init --pod-network-cidr=10.244.0.0/16"

# Copy admin.conf for root
command "mkdir -p /root/.kube"
command "cp /etc/kubernetes/admin.conf /root/.kube/config"

# Copy kube config to local machine
mkdir -p ~/.kube
KUBE_CONFIG=`ssh $user@$node cat /root/.kube/config`
echo -e $"$KUBE_CONFIG" > ~/.kube/config
