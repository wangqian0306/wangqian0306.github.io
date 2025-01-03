---
title: Kubernetes 安装
date: 2023-02-01 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: kubernetes
no_word_count: true
no_toc: false
categories: Kubernetes
---

## 简介

Kubernetes是一个可移植的，可扩展的开源平台，用于管理容器化的工作负载和服务，。

### 安装前的准备

#### 检查系统兼容性

Kubernetes 为基于 Debian 和 Red Hat 的通用 Linux 发行版提供了支持，对其他发行版提供了通用说明。

#### 检查硬件配置

- 2 CPU 及以上的处理器
- 2 GB 及以上内存

#### 检查网络配置

- 确保集群中的设备可以互通(公有'DNS'或私有‘host’皆可)
    - 使用 `ping` 命令检测
- 集群中每个设备都需要独立的 Hostname, MAC 地址 和 Product_uuid。
    - 使用 `ifconfig -a` 检测 Hostname, MAC 地址 是否冲突
    - 使用 `sudo cat /sys/class/dmi/id/product_uuid` 检测 Product_uuid 是否冲突
- 检测集群中的端口是否开放

控制节点 `Control-plane node(s)` 所需端口如下：


|协议类型|绑定方式|端口区域|作用|对应服务|
|:---:|:---:|:---:|:---:|:---:|
|TCP|Inbound|6443*|Kubernetes API server|All|
|TCP|Inbound|2379-2380|etcd server client API|kube-apiserver, etcd |
|TCP|Inbound|10250|kubelet API|Self, Control plane|
|TCP|Inbound|10251|kube-scheduler|Self|
|TCP|Inbound|10252|kube-controller-manager|Self|

工作节点 `Worker node(s)` 所需端口如下

|协议类型|绑定方式|端口区域|作用|对应服务|
|:---:|:---:|:---:|:---:|:---:|
|TCP|Inbound|10250|kubelet API|Self, Control plane|
|TCP|Inbound|30000-32767|NodePort Services†|All|

> 注：
> * 标记的端口是可以修改的，确保对应端口开放即可。
> † 标记的端口是 `NodePort` 服务的默认端口范围。

#### 关闭 `Swap`

使用如下命令单次禁用 `Swap`

```bash
sudo swapoff -a
```

取消 `Swap` 挂载

```bash
vim /etc/fstab
```

使用 `#` 号注释 Swap 所处行即可

### 配置 `iptables`

使用如下命令配置网络

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward                = 1
EOF
sudo sysctl --system
```

### 配置 Containerd 

> 注：参照 Containerd 文档。

### 安装 `kubeadm`,`kubelet`,`kubectl` 命令

使用如下命令进行安装

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
```

### 初始化控制节点

编写如下配置文件 `kubeadm-config.yaml`：

```text
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///run/containerd/containerd.sock"
localAPIEndpoint:
  advertiseAddress: "<hostOrIp>"
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "10.244.0.0/24"
  dnsDomain: "cluster.local"
kubernetesVersion: "<version>"
controlPlaneEndpoint: "<hostOrIp>:6443"
certificatesDir: "/etc/kubernetes/pki"
imageRepository: "registry.aliyuncs.com/google_containers"
clusterName: "demo-cluster"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
```

使用如下命令拉取镜像并启动服务：

```bash
kubeadm config images pull --config kubeadm-config.yaml
kubeadm init --config kubeadm-config.yaml -v 5
```

> 注：如果遇到问题，可以根据命令提示进行修复，并使用 `kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock` 移除之前的配置。

### 用户配置

root 用户配置

```bash
cat <<EOF | sudo tee /etc/profile.d/k8s.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
EOF
chmod a+x /etc/profile.d/k8s.sh
source /etc/profile.d/k8s.sh
```

普通用户配置

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### (可选) 在主机上运行除集群管理外的其他服务

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### 加入集群

- 如果原先 token 过期需要刷新 token，(默认一天)

```bash
kubeadm token create
```

- 如果没有 `discovery-token-ca-cert-hash` 可以使用如下命令生成

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```

> 注： `kubeadm init` 命令会在命令行中输出加入集群的命令具体结构如下：
> `kubeadm join <host>:<port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>`

- 运行 join 命令

### 部署网络插件

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### 检查集群

使用如下命令检查 Kubernetes 节点列表

```bash
kubectl get nodes --all-namespaces
```

使用如下命令检查 Kubernetes 集群中运行的所有的 Pod

```bash
kubectl get pods --all-namespaces
```

### 证书续期

集群的默认证书只有一年，可以通过如下命令配置延长：

```bash
kubeadm init --cert-dir /etc/kubernetes/pki --cert-expiration 8760h
```

使用如下命令检测过期时长：

```bash
kubeadm certs check-expiration
```

如果有 `RESIDUAL TIME` 项异常则可以使用此命令进行续期：

```bash
kubeadm certs renew <CERTIFICATE>
```

或者使用如下命令批量更新：

```bash
kubeadm certs renew all
```

在更新完成后需要重启服务，通过重启设备或者使用如下命令：

```bash
kubectl -n kube-system delete pod -l 'component=kube-apiserver'
kubectl -n kube-system delete pod -l 'component=kube-controller-manager'
kubectl -n kube-system delete pod -l 'component=kube-scheduler'
kubectl -n kube-system delete pod -l 'component=kube-etcd'
```

### 参考资料

[官方文档](https://kubernetes.io/)

[安装文档](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
