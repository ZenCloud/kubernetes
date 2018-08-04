# kubernetes

Minimal steps to setup a working kubernetes cluster.

## Pre-conditions

- Two or more nodes setup with CentOS 7.x.
- SSH access as root to these nodes.
- Having read and understood each step in the included script(s) here before you run them.

## Step 1

Setup a DNS name pointing to each node. It could be something like manager.zencloud.se and compute.zencloud.se if you have two nodes.

To keep things simple you could start by simply editing your local /etc/hosts and then copying these settings to each node in the cluster.

## Step 2

Edit `cluster-setup.sh` and review the **Configuration** section.

```bash
vim node.sh
```

Run `node.sh` to setup the kubernetes cluster.

```bash
sh node.sh
```

Once the script is finished you will se the output of `kubectl get nodes`.

Example:

```bash
~# ssh zc-manager kubectl get nodes
NAME                  STATUS    ROLES     AGE       VERSION
containership-zc-01   Ready     master    37s       v1.11.1
containership-zc-02   Ready     <none>    23s       v1.11.1
containership-zc-03   Ready     <none>    19s       v1.11.1
containership-zc-04   Ready     <none>    15s       v1.11.1
```

## Step 3

Deploy Traefik.

```bash
kubectl apply -f traefik-rbac.yml
kubectl apply -f traefik-ds.yml
kubectl apply -f traefik-ui.yml
```

## Step 4

Deploy other stuff.

```bash
kubectl apply -f nginx-test.yml
```
