#!/bin/bash

node="$1"
user="$2"

function command {
  USERANDHOST="$user@$node"
  echo $USERANDHOST
  echo "~# ssh $USERANDHOST" "$1"
  ssh -oStrictHostKeyChecking=no $"$USERANDHOST" "$1"
}

# Remove $node entry from known_hosts
# I reinstalled the hosts several times while developing this
sed -i "/$node/d" ~/.ssh/known_hosts

command "setenforce 0"
command "sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
command "echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.conf"
command "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf"

command "echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' > /etc/yum.repos.d/kubernetes.repo"

# Update and install packages
command "yum update -y && yum install -y kubeadm docker vim sudo curl"

# Enable and start kubelet and docker services
command "systemctl enable docker && systemctl enable kubelet"
command "systemctl start docker && systemctl start kubelet"
