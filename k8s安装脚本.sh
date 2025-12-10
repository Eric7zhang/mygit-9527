#!/bin/bash

2、把主机规划清单写入/etc/fstab：
cat > /etc/hosts << EOF
127.0.0.1 localhost
192.168.126.99 client.lab.example.com client
192.168.126.100 k8s-master.lab.example.com k8s-master
192.168.126.101 k8s-node1.lab.example.com k8s-node1
192.168.126.102 k8s-node2.lab.example.com k8s-node2
192.168.126.103 k8s-node3.lab.example.com k8s-node3
192.168.126.55 registry.lab.example.com registry
EOF


3、设置内核参数：
root@k8s:~# cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness = 0
EOF
root@k8s:~# echo br_netfilter >> /etc/modules && modprobe br_netfilter
root@k8s:~# sysctl --system


4、关闭交换内存：
root@k8s:~# swapoff -a
root@k8s:~# sed -ir 's/.*swap/#&/g' /etc/fstab
root@k8s:~# rm -Rf /swap.img
root@k8s:~# free -m

安装配置 Docker runtime： （相关文档：https://docs.docker.com/engine/install/ubuntu/
https://kubernetes.io/docs/setup/production-environment/container-runtimes/）
(1) 配置 docker apt 仓库
root@k8s:~# apt-get remove docker docker-engine docker.io containerd runc -y
root@k8s:~# apt-get install ca-certificates curl gnupg lsb-release -y
root@k8s:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
root@k8s:~# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
root@k8s:~# apt-get update

apt-cache madison docker-ce

apt-get install docker-ce -y 

cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["registry.lab.example.com","192.168.126.55","registry"],"registry-mirrors": ["https://3ca84f1l.mirror.aliyuncs.com"]
}
EOF

sed -i 's/^GRUB_CMDLINE_LINUX=".*/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub


root@k8s:~# systemctl enable docker
root@k8s:~# systemctl restart docker
root@k8s:~# docker info


curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >>/etc/apt/sources.list.d/kubernetes.list
systemctl enable kubelet

echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


master操作
export CLIENTS="k8s-master k8s-node1 k8s-node2 client"
export NODES="k8s-master k8s-node1 k8s-node2"
export WORKERS="k8s-node1 k8s-node2"
ssh-keygen -N '' -f ~/.ssh/id_rsa
for client in $CLIENTS;do ssh-copy-id $client;done

source <(kubeadm completion bash)
sudo kubeadm init --kubernetes-version=v1.22.0 --apiserver-advertise-address=192.168.126.100 \
--image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12

sudo kubeadm init --kubernetes-version=v1.22.0 --apiserver-advertise-address=192.168.126.100 \
> --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12
[init] Using Kubernetes version: v1.22.0
[preflight] Running pre-flight checks
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 24.0.2. Latest validated version: 20.10
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-master.lab.example.com kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.126.100]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-master.lab.example.com localhost] and IPs [192.168.126.100 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-master.lab.example.com localhost] and IPs [192.168.126.100 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 8.504978 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.22" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-master.lab.example.com as control-plane by adding the labels: [node-role.kubernetes.io/master(deprecated) node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s-master.lab.example.com as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: 0pgu2w.xgvq1285wesno9xh
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.126.100:6443 --token 0pgu2w.xgvq1285wesno9xh \
        --discovery-token-ca-cert-hash sha256:9fd7b2f70a1ff5d6697c8991d8330d8bb25c4c5e135f26c1862830a82c3ebaf2 


#根据提示，在各个节点执行加入集群命令
for worker in $WORKERS;do ssh $worker sudo kubeadm join 192.168.126.100:6443 --token 0pgu2w.xgvq1285wesno9xh \
--discovery-token-ca-cert-hash sha256:9fd7b2f70a1ff5d6697c8991d8330d8bb25c4c5e135f26c1862830a82c3ebaf2;done


#master节点执行
sudo bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bash_profile"
sudo bash -c "echo 'source <(kubeadm completion bash)' >> /root/.bash_profile"
sudo bash -c "echo 'source <(kubectl completion bash)' >> /root/.bash_profile"

for client in $CLIENTS;do ssh $client mkdir ~/.kube;done
sudo cp /etc/kubernetes/admin.conf /home/student/.kube/config
sudo cp /etc/kubernetes/pki/ca.crt /home/student/.kube/
sudo chown student.student ~/.kube/*
for x in k8s-node1 k8s-node2 client;do scp ~/.kube/* $x:~/.kube/;done
for client in $CLIENTS;do ssh $client "echo 'source <(kubeadm completion bash)' >> ~/.bash_profile";done
for client in $CLIENTS;do ssh $client "echo 'source <(kubectl completion bash)' >> ~/.bash_profile";done
source ~/.bash_profile