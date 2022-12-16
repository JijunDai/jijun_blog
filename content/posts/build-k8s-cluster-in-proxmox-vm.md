---
title: "Build K8s Cluster in Proxmox Vm"
date: 2022-12-15T14:27:26-05:00
draft: true
tags:
- k8s
- kubernetes
- ubuntu22.04
- proxmox
---
## Config Ubuntu instances on Proxmox using a template

### Enable QEMU Guest Agent
`sudo apt install qemu-guest-agent`

### Config network and hostname
`sudo vim /etc/netplan/00-XXX.ymal`

```yaml
network:
  version: 2
  ethernets:
    ens18:
      addresses: [192.168.2.10x/24]
      nameservers:
        addresses: [192.168.2.1]
      routes:
        - to: default
          via: 192.168.2.1
```
`sudo netplan try`
`sudo hostnamectl hostname XXX`
`sudo vim /etc/hosts`

### Installing container runtime(contanerd)
```shell
sudo apt install containerd
sudo systemctl status containerd
sudo kdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```
change "SystemdCgroup = true" under "[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]"

### Check swap and firewall
```shell
$ sudo systemctl stop ufw.service; systemctl disable ufw.service

$ free -m
$ swapoff

# edit /etc/sysctl.conf, add "vm.swappiness = 0"
$ systcl -p
```

### Modify system paramerter
`sudo vim /etc/sysctl.conf`
Enable: `net.ipv4.ip_forward=1'
Edit /etc/modules-load.d/k8s.conf like:
```shell
cat /etc/modules-load.d/k8s.conf

br_netfilter
```
`sudo reboot`

### Install Kubernetes repository and required packages
```shell
#Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

#Download the Google Cloud public signing key:
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

#Add the Kubernetes apt repository:
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Create a template for k8s nodes (optional)
```shell
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/instances

sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id

sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
```
After that, shutdown the vm, and convert it as a template.
We could clone a new VM from it with mode: Full Clone.

### Initializing the kubernetes cluster
On master node(control-plane)
```shell
sudo kubeadm init --control-plane-endpoint=192.168.2.104 --node-name cp0  --pod-network-cidr=10.244.0.0/16
#option
sudo kubeadm token create --print-join-command
```
To start using your cluster, you need to run the following as a regular user:
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Alternatively, if you are the root user, you can run:

`export KUBECONFIG=/etc/kubernetes/admin.conf`

Optionally, remove the taint on control-plane(master) node.

`kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-`

### Adding overlay network to the cluster
`curl https://projectcalico.docs.tigera.io/manifests/calico.yaml -O`
`kubectl apply -f calico.yaml`

### Adding nodes to the cluster
On other nodes
```shell
sudo kubeadm join 192.168.2.104:6443 --token lg1yi2.bfi7y73yd0mie4kn --discovery-token-ca-cert-hash sha256:6d964894cf16f1683fb742e2c8d975ef6533c02dcd8329c8ac5ceecf58a20239
```
