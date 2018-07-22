#!/bin/bash

# Support functions #
# ####### ######### #

function all {
  compute "$1"
  manager "$1"
}

function compute {
  # TODO: Allow dynamic number of compute nodes.
  ssh zc-compute-1 $1
  ssh zc-compute-2 $1
  ssh zc-compute-3 $1
}

function manager {
  # TODO: Allow dynamic number of manager nodes.
  ssh zc-manager $1
}

function log {
  echo
  echo "> $1"
  echo
}

# User setup #
# #### ##### #

log "Create and setup user ssh access"

# TODO: Make user configurable.
all "if [ $(id -u ilix > /dev/null 2>&1; echo $?) -eq 1 ]; then useradd ilix; fi"
all "mkdir /home/ilix/.ssh"
all "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1syof3mPdm0ud5AdUF6+NYxAVmnZWCO7FN9XjRtkV5WayZJ1HfRoqBK3sdQZ14Q07Mb0eZ/1aWxBsvxkWGgGfXh5PTgsiy4dyNEn7PTf8IZ0qXaykxvqGaq8QzLozUJDEH88B3jJe5cMf+LjL6xN8g1wy926nwaRUzdbZpmPa/yKvJWedC2q4qpSS22wE8XN0XiXdLLSV/DQ6ifRRQ+hEU6AjQH3St+ChYpii93pgqLBp6Fuj4NH9Zmt3fL2TylO+/+go5gmZYPGjoh0oXfhjL+zLPNFK3RB/GFKVf/L3uT1tuS1uM5khXRDq3pW32tf5IQ1D6ct6kB6PjFrJNJZL ilix@undying' > /home/ilix/.ssh/authorized_keys"
all "chown -R ilix:ilix /home/ilix/.ssh"

log "Add user to docker and wheel groups"

all "groupadd docker"
all "gpasswd -a ilix wheel"
all "gpasswd -a ilix docker"

# Repo + packages setup #
# #### # ######## ##### #

log "Configure system for kubernetes"

all "setenforce 0"
all "sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux"
all "echo 'net.bridge.bridge-nf-call-ip6tables = 1' > /etc/sysctl.conf"
all "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf"

log "Add kubernetes repository"

all "echo '[kubernetes]' > /etc/yum.repos.d/kubernetes.repo"
all "echo 'name=Kubernetes' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'enabled=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'gpgcheck=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'repo_gpgcheck=1' >> /etc/yum.repos.d/kubernetes.repo"
all "echo 'gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg' >> /etc/yum.repos.d/kubernetes.repo"
all "echo '       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg' >> /etc/yum.repos.d/kubernetes.repo"

log "Install packages"

all "yum update -y"
all "yum install -y kubeadm docker git vim sudo wget"

# Docker + Kubernetes setup #
# ###### # ########## ##### #

log "Enable docker and kubelet services"

all "systemctl enable docker && systemctl enable kubelet"
all "systemctl start docker && systemctl start kubelet"

# Manager setup #
# ####### ##### #

log "Setup manager node"

manager "kubeadm reset"
manager "kubeadm init"
