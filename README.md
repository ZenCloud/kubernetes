# kubernetes

## Pre-conditions

- You need four nodes setup with CentOS ~7.
- You need ssh access as root.
- Node ssh aliases are currently hard coded in the setup script.
- Read and understand each step in the script(s) here before you run them!

## Step 1

Add your node(s) to ~/.ssh config

```config
Host zc-manager
 Hostname 10.13.37.10
 IdentityFile ~/.ssh/id_rsa
 IdentitiesOnly yes

Host zc-compute-1
 Hostname 10.13.37.21
 IdentityFile ~/.ssh/id_rsa
 IdentitiesOnly yes

Host zc-compute-2
 Hostname 10.13.37.22
 IdentityFile ~/.ssh/id_rsa
 IdentitiesOnly yes

Host zc-compute-3
 Hostname 10.13.37.23
 IdentityFile ~/.ssh/id_rsa
 IdentitiesOnly yes

```

## Step 2

Edit `node.sh` and review the **Configuration** section.

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
