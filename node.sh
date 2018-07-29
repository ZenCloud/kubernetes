#!/bin/bash

# Configuration #
# ############# #

NORMAL_USER="ilix"
MANAGER_NODE="mngr-1.k8s.zencloud.se"
COMPUTE_NODES=( "cmpt-1.k8s.zencloud.se" "cmpt-2.k8s.zencloud.se" "cmpt-3.k8s.zencloud.se" )

ALL_NODES=("${COMPUTE_NODES[@]}")
ALL_NODES+=("$MANAGER_NODE")

# Support functions #
# ####### ######### #

# Run a command on a single node.
function command {
  echo "~# ssh root@$1" "$2"
  ssh -oStrictHostKeyChecking=no $"root@$1" "$2"
}

# Setup and prepare all nodes #
# ##### ### ####### ### ##### #

for node in "${ALL_NODES[@]}"
do
  echo
  echo "Setup and prepare $node"
  echo

  # Remove $node entry from known_hosts
  # I reinstalled the hosts several times while developing this
  sed -i "/$node/d" ~/.ssh/known_hosts

  # Hostname
  command "$node" "hostname $node"
  command "$node" "echo '$node' > /etc/hostname"

  # User setup
  command "$node" "useradd $NORMAL_USER"
  command "$node" "mkdir /home/$NORMAL_USER/.ssh"
  command "$node" "cp /root/.ssh/authorized_keys /home/$NORMAL_USER/.ssh/authorized_keys"
  command "$node" "chown -R $NORMAL_USER:$NORMAL_USER /home/$NORMAL_USER/.ssh"

  command "$node" "groupadd docker"
  command "$node" "gpasswd -a $NORMAL_USER wheel"
  command "$node" "gpasswd -a $NORMAL_USER docker"

  # Repo setup
  command "$node" "setenforce 0"
  command "$node" "sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
  command "$node" "echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.conf"
  command "$node" "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf"

  command "$node" "echo -e '[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' > /etc/yum.repos.d/kubernetes.repo"

  # Update and install packages
  command "$node" "yum update -y && yum install -y kubeadm docker vim sudo curl"

  # Enable and start kubelet and docker services
  command "$node" "systemctl enable docker && systemctl enable kubelet"
  command "$node" "systemctl start docker && systemctl start kubelet"
done

# Manager setup #
# ####### ##### #

# Init cluster
command "$MANAGER_NODE" "kubeadm init --pod-network-cidr=10.244.0.0/16"

# Copy admin.conf for root
command "$MANAGER_NODE" "mkdir -p /root/.kube"
command "$MANAGER_NODE" "cp /etc/kubernetes/admin.conf /root/.kube/config"

# Copy admin.conf for $NORMAL_USER
command "$MANAGER_NODE" "mkdir -p /home/$NORMAL_USER/.kube"
command "$MANAGER_NODE" "cp /etc/kubernetes/admin.conf /home/$NORMAL_USER/.kube/config"
command "$MANAGER_NODE" "chown $NORMAL_USER:$NORMAL_USER /home/$NORMAL_USER/.kube/config"

# Cluster setup #
# ####### ##### #

# Create join token and save join command in a local variable
JOIN_COMMAND=`ssh root@$MANAGER_NODE kubeadm token create --print-join-command`

# Join compute nodes to cluster
for node in "${COMPUTE_NODES[@]}"
do
  command "$node" $"$JOIN_COMMAND"
done

# Kube config #
# #### ###### #

# Copy kube config to local machine
mkdir -p ~/.kube
KUBE_CONFIG=`ssh root@$MANAGER_NODE cat /root/.kube/config`
echo -e $"$KUBE_CONFIG" > ~/.kube/config

# Enable Flannel network
echo && echo "Apply Flannel network"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml

# echo && echo "Apply Calico"
# kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
