#!/bin/bash

# Configuration #
# ############# #

USER="ilix"
MANAGER_NODE=""

# Support functions #
# ####### ######### #

LATEST_MANAGER_RESULT=""

# Run a command on all nodes.
function all {
  manager "$1"
  compute "$1"
}

# Run a command on compute node(s).
function compute {
  # TODO: Allow dynamic number of compute nodes.
  single zc-compute-1 "$1"
  single zc-compute-2 "$1"
  single zc-compute-3 "$1"
}

# Run a command on manager node(s).
function manager {
  # TODO: Allow dynamic number of manager nodes.
  LATEST_MANAGER_RESULT=`single zc-manager "$1"`
  echo -e $"$LATEST_MANAGER_RESULT"
}

# Run a command on a single node.
function single {
  echo "~# ssh $1" "$2"
  ssh $1 "$2"
}

# User setup #
# #### ##### #

all "useradd $USER"
all "mkdir /home/$USER/.ssh"
all "cp /root/.ssh/authorized_keys /home/$USER/.ssh/authorized_keys"
all "chown -R $USER:$USER /home/$USER/.ssh"

all "groupadd docker"
all "gpasswd -a $USER wheel"
all "gpasswd -a $USER docker"

# Repo + packages setup #
# #### # ######## ##### #

all "setenforce 0"
all "sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
all "echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.conf"
all "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf"

all "echo '[kubernetes]' > /etc/yum.repos.d/kubernetes.repo"
all "echo 'name=Kubernetes' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'enabled=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'gpgcheck=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'repo_gpgcheck=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg' >> /etc/yum.repos.d/kubernetes.repo"
all "echo '       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' >> /etc/yum.repos.d/kubernetes.repo"

all "yum update -y"
all "yum install -y kubeadm docker vim sudo curl"

# Docker + Kubernetes setup #
# ###### # ########## ##### #

all "systemctl enable docker && systemctl enable kubelet"
all "systemctl start docker && systemctl start kubelet"

# Manager setup #
# ####### ##### #

# Init cluster
manager "kubeadm init --pod-network-cidr=10.244.0.0/16"

# Copy admin.conf for root
manager "mkdir -p /root/.kube"
manager "cp /etc/kubernetes/admin.conf /root/.kube/config"

# Copy admin.conf for $USER
manager "mkdir -p /home/$USER/.kube"
manager "cp /etc/kubernetes/admin.conf /home/$USER/.kube/config"
manager "chown $USER:$USER /home/$USER/.kube/config"

# Join compute nodes to cluster
manager "kubeadm token create --print-join-command"
compute "$LATEST_MANAGER_RESULT"

# Enable Flannel network
manager "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml"

# Copy kube config to local machine
mkdir -p ~/.kube
KUBE_CONFIG=`ssh zc-manager cat /root/.kube/config`
echo -e $"$KUBE_CONFIG" > ~/.kube/config

# List nodes to see that everything is working
sleep 20
kubectl get nodes
