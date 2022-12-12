---
title: "KeepLearningK8s"
author: "Jijun Dai"
date: 2022-12-10T20:12:56-05:00
draft: true
tags:
- k8s
- kubernetes
- metallb
- Ingress-nginx
- nfs
- flux
---

## Deploy & use MetalLB in bare metal Kubernetes
### layer 2 configuration

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool

```

## Ingress-nginx

```bash
$ helm show values ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx > ingress-nginx-values.yaml

```

```bash
$ diff ingress-nginx.yaml ingress-nginx-values.yaml
26,28c26,28
<     tag: "v1.3.0"
<     digest: sha256:d1707ca76d3b044ab8a28277a2466a02100ee9f58a86af1535a3edf9323ea1b5
<     digestChroot: sha256:0fcb91216a22aae43b374fc2e6a03b8afe9e8c78cbf07a09d75636dc4ea3c191
---
>     tag: "v1.3.1"
>     digest: sha256:54f7fe2c6c5a9db9a0ebf1131797109bb7a4d91f56b9b362bde2abd237dd1974
>     digestChroot: sha256:a8466b19c621bd550b1645e27a004a5cc85009c858a9ab19490216735ac432b1
66c66
<   dnsPolicy: ClusterFirstWithHostNet
---
>   dnsPolicy: ClusterFirst
89c89
<   hostNetwork: true
---
>   hostNetwork: false
95c95   # hostPort
<     enabled: true     
---
>     enabled: false
113c113 # ingressClassResource
<     default: true
---
>     default: false

```

```bash
$ helm install ingress-nginx ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx \
--namespace ingress-nginx --create-namespace --values ./ingress-nginx-values.yaml

NAME: ingress-nginx
LAST DEPLOYED: Wed Sep 28 04:52:55 2022
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls

```

### nfs-subdir-external-provisioner
```bash
$ sudo apt update
$ sudo apt install nfs-kernel-server
```

```shell
$ sudo apt update
$ sudo apt install nfs-common
```

```
```

```bash
sudo mkdir /var/nfs/kubedata -p
sudo chown nobody:nogroup /var/nfs/kubedata
sudo vim /etc/exports

/var/nfs/kubedata       *(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure)host

sudo systemctl status nfs-server.service
sudo exportfs -arv
sudo showmount --exports localhost

k apply -f rbac.yaml -f class.yaml -f deployment.yaml

```

```
### Deploy apps

- check the networks - db IP, Redis IP and connnectivity
- config map for apps, initial container
- deployment config
- imagepull security, secret config
- check and monitor the deployment
- TLS, cert manage

---
```shell
k run testnet -l app=testnet --image busybox -- sleep 9999999
```

---
### Flux
https://fluxcd.io/flux/get-started/
#### Install
```bash
➜ flux bootstrap github \
➜ --owner=$GITHUB_USER \
➜ --repository=fleet-infra \
➜ --branch=main \
➜ --path=./clusters/my-cluster \
➜ --personal
► connecting to github.com
✔ repository "https://github.com/JijunDai/fleet-infra" created
► cloning branch "main" from Git repository "https://github.com/JijunDai/fleet-infra.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed sync manifests to "main" ("db9fb1cba3ae9ce58c931592e1fef781c09cca1a")
► pushing component manifests to "https://github.com/JijunDai/fleet-infra.git"
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
✔ public key: ecdsa-sha2-nistp384 AAAAE2VjZHNhLXNoYTItbmlzdHAzODQAAAAIbmlzdHAzODQAAABhBKsd2QRpZiA9R00gKLA9uWaw+FFs9lyXFTtBT2LS1GF4bVTw7C24hzsOehOE+0Gtjlm4K+biLysmwNwa7LsBLS9RoM85ZmwVjLtiR75f48loacWAJRxJCg39yus0w8MYbQ==
✔ configured deploy key "flux-system-main-flux-system-./clusters/my-cluster" for "https://github.com/JijunDai/fleet-infra"
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("ada8b31f1389405333e1371fc91ddb4310b9ede8")
► pushing sync manifests to "https://github.com/JijunDai/fleet-infra.git"
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
✔ Kustomization reconciled successfully
► confirming components are healthy
✔ helm-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy

```
