#!/bin/bash

# Configuration #
# ############# #

NORMAL_USER="ilix"
MANAGER_NODE="mngr-1.k8s.zencloud.se"
COMPUTE_NODES=( "cmpt-1.k8s.zencloud.se" "cmpt-2.k8s.zencloud.se" "cmpt-3.k8s.zencloud.se" )
ALL_NODES=( "cmpt-1.k8s.zencloud.se" "cmpt-2.k8s.zencloud.se" "cmpt-3.k8s.zencloud.se" "$MANAGER_NODE" )

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
  for node in "${COMPUTE_NODES[@]}"
  do
    single "$node" "$1"
  done
}

# Run a command on manager node(s).
function manager {
  # TODO: Allow dynamic number of manager nodes.
  LATEST_MANAGER_RESULT=`single "$MANAGER_NODE" "$1"`
  echo -e $"$LATEST_MANAGER_RESULT"
}

# Run a command on a single node.
function single {
  echo "~# ssh root@$1" "$2"
  ssh -oStrictHostKeyChecking=no "root@$1" "$2"
}

# Node setup #
# #### ##### #

single "$MANAGER_NODE" "echo '$MANAGER_NODE' > /etc/hostname"
for node in "${COMPUTE_NODES[@]}"
do
  single "$node" "echo '$node' > /etc/hostname"
done

# User setup #
# #### ##### #

all "useradd $NORMAL_USER"
all "mkdir /home/$NORMAL_USER/.ssh"
all "cp /root/.ssh/authorized_keys /home/$NORMAL_USER/.ssh/authorized_keys"
all "chown -R $NORMAL_USER:$NORMAL_USER /home/$NORMAL_USER/.ssh"

all "groupadd docker"
all "gpasswd -a $NORMAL_USER wheel"
all "gpasswd -a $NORMAL_USER docker"

# Repo + packages setup #
# #### # ######## ##### #

all "setenforce 0"
all "sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
all "echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.conf"
all "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf"

all "echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' > /etc/yum.repos.d/kubernetes.repo"

all "yum update -y && yum install -y kubeadm docker vim sudo curl"

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

# Copy admin.conf for $NORMAL_USER
manager "mkdir -p /home/$NORMAL_USER/.kube"
manager "cp /etc/kubernetes/admin.conf /home/$NORMAL_USER/.kube/config"
manager "chown $NORMAL_USER:$NORMAL_USER /home/$NORMAL_USER/.kube/config"

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
