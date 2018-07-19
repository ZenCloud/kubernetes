# kubernetes

## Step 1

Add your node(s) to ~/.ssh config

```
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
