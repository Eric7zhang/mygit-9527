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
 :swapoff -a
 sed -ir 's/.*swap/#&/g' /etc/fstab
 rm -Rf /swap.img
 free -m

安装配置 Docker runtime： （相关文档：https://docs.docker.com/engine/install/ubuntu/
https://kubernetes.io/docs/setup/production-environment/container-runtimes/）
(1) 配置 docker apt 仓库
root@k8s:~# apt-get remove docker docker-engine docker.io containerd runc -y
root@k8s:~# apt-get install ca-certificates curl gnupg lsb-release -y
root@k8s:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
root@k8s:~# apt-get update


#选择docker版本并安装
apt-cache madison docker-ce
apt-get install docker-ce -y 


#创建并编辑dockr配置文件
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["registry.lab.example.com","192.168.126.55","registry"],"registry-mirrors": ["https://3ca84f1l.mirror.aliyuncs.com"]
}
EOF

#解决 Ubuntu 或 Debian 操作系统下 docker swap limit 提示：
sed -i 's/^GRUB_CMDLINE_LINUX=".*/GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub


root@k8s:~# systemctl enable docker
root@k8s:~# systemctl restart docker
root@k8s:~# docker info


#添加ubuntu阿里云kubernetes软件仓库
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >>/etc/apt/sources.list.d/kubernetes.list
apt-get update

#安装kubeadm、kubelet软件包
apt-cache madison kubelet
apt-get install kubelet=1.22.0-00 kubeadm=1.22.0-00 kubectl=1.22.0-00 -y
systemctl enable kubelet

#设置普通用户k8s无密码提权
echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#封装模版
history -c
init 0


#client节点操作
sudo hostnamectl set-hostname client.lab.example.com
sudo sed -i 's/66/99/' /etc/netplan/00-installer-config.yaml
sudo netplan apply
init 0

#master节点操作
sudo hostnamectl set-hostname k8s-master.lab.example.com
sudo sed -i 's/66/100/' /etc/netplan/00-installer-config.yaml
sudo netplan apply
init 0

#node1节点操作
sudo hostnamectl set-hostname k8s-node1.lab.example.com
sudo sed -i 's/66/101/' /etc/netplan/00-installer-config.yaml
sudo netplan apply

#node2节点操作
sudo hostnamectl set-hostname k8s-node2.lab.example.com
sudo sed -i 's/66/102/' /etc/netplan/00-installer-config.yaml
sudo netplan apply

#node3节点操作
sudo hostnamectl set-hostname k8s-node3.lab.example.com
sudo sed -i 's/66/103/' /etc/netplan/00-installer-config.yaml
sudo netplan apply


#master操作
export CLIENTS="k8s-master k8s-node1 k8s-node2 client"
export NODES="k8s-master k8s-node1 k8s-node2"
export WORKERS="k8s-node1 k8s-node2"
ssh-keygen -N '' -f ~/.ssh/id_rsa
for client in $CLIENTS;do ssh-copy-id $client;done

source <(kubeadm completion bash)

sudo kubeadm init --kubernetes-version=v1.22.0 --apiserver-advertise-address=192.168.126.100 \
 --image-repository=registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12
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

#kubeadm join 192.168.126.100:6443 --token kziqud.l4fzx42grebla4q4 \
#        --discovery-token-ca-cert-hash sha256:409d864200b068c45c64c2908061f2d82d36e0678990ceb00c595c74f45d19f5 




#根据提示，在各个节点执行加入集群命令
for worker in $WORKERS;do ssh $worker sudo kubeadm join 192.168.126.100:6443 --token kziqud.l4fzx42grebla4q4 \
--discovery-token-ca-cert-hash sha256:409d864200b068c45c64c2908061f2d82d36e0678990ceb00c595c74f45d19f5;done


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



#搭建完k8s后，nodes集群状态有可能是NotReady的状态
k8s@k8s-master:~$ kubectl get nodes
NAME                         STATUS     ROLES                  AGE     VERSION
k8s-master.lab.example.com   NotReady   control-plane,master   4d22h   v1.22.0
k8s-node1.lab.example.com    NotReady   <none>                 4d22h   v1.22.0
k8s-node2.lab.example.com    NotReady   <none>                 4d22h   v1.22.0
k8s@k8s-master:~$ kubectl get pods -A
NAMESPACE     NAME                                                 READY   STATUS                  RESTARTS        AGE
kube-system   calico-kube-controllers-68d86f8988-tq8jn             0/1     Pending                 0               4d22h
kube-system   calico-node-74b2c                                    0/1     Init:ImagePullBackOff   0               4d22h
kube-system   calico-node-75p4s                                    0/1     Init:ImagePullBackOff   0               4d22h
kube-system   calico-node-pnztc                                    0/1     Init:ImagePullBackOff   0               4d22h
kube-system   coredns-7f6cbbb7b8-s98zx                             0/1     Pending                 0               4d22h
kube-system   coredns-7f6cbbb7b8-shf5s                             0/1     Pending                 0               4d22h
kube-system   etcd-k8s-master.lab.example.com                      1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-apiserver-k8s-master.lab.example.com            1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-controller-manager-k8s-master.lab.example.com   1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-proxy-459rh                                     1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-proxy-dmmtx                                     1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-proxy-thtrc                                     1/1     Running                 1 (4d20h ago)   4d22h
kube-system   kube-scheduler-k8s-master.lab.example.com            1/1     Running                 1 (4d20h ago)   4d22h

#在master节点上执行。
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
kubectl apply -f calico.yaml
sudo vi /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
endpoint = [
"https://docker.m.daocloud.io",
"https://docker.1ms.run"
]
systemctl restart containerd
systemctl restart kubelet
kubectl delete pod -n kube-system --all

k8s@k8s-master:~$ kubectl get pods -A
NAMESPACE     NAME                                                 READY   STATUS    RESTARTS      AGE
kube-system   calico-kube-controllers-68d86f8988-7j2kb             1/1     Running   0             12m
kube-system   calico-node-6m7cg                                    1/1     Running   0             12m
kube-system   calico-node-hfl7x                                    1/1     Running   0             12m
kube-system   calico-node-jxrgz                                    1/1     Running   0             12m
kube-system   coredns-7f6cbbb7b8-9kf9s                             1/1     Running   0             12m
kube-system   coredns-7f6cbbb7b8-lzwpd                             1/1     Running   0             12m
kube-system   etcd-k8s-master.lab.example.com                      1/1     Running   2 (20m ago)   12m
kube-system   kube-apiserver-k8s-master.lab.example.com            1/1     Running   2 (20m ago)   12m
kube-system   kube-controller-manager-k8s-master.lab.example.com   1/1     Running   2 (20m ago)   12m
kube-system   kube-proxy-gzr8n                                     1/1     Running   0             12m
kube-system   kube-proxy-nzl8f                                     1/1     Running   0             12m
kube-system   kube-proxy-wlt2j                                     1/1     Running   0             12m
kube-system   kube-scheduler-k8s-master.lab.example.com            1/1     Running   2 (20m ago)   12m

k8s@k8s-master:~$ kubectl get nodes
NAME                         STATUS   ROLES                  AGE     VERSION
k8s-master.lab.example.com   Ready    control-plane,master   4d23h   v1.22.0
k8s-node1.lab.example.com    Ready    <none>                 4d23h   v1.22.0
k8s-node2.lab.example.com    Ready    <none>                 4d23h   v1.22.0


sudo kubeadm certs renew all #通过kubeadm工具来更新证书
[renew] Reading configuration from the cluster...
[renew] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate the apiserver uses to access etcd renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for liveness probes to healthcheck etcd renewed
certificate for etcd nodes to communicate with each other renewed
certificate for serving etcd renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler manager to use renewed

Done renewing certificates. You must restart the kube-apiserver, kube-controller-manager, kube-scheduler and etcd, so that they can use the new certificates.


sudo kubeadm certs check-expiration   #对于ca、etcd-ca、front-proxy-ca等根证书，sudo kubeadm certs renew-ca  来更新根证书
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Dec 11, 2026 08:35 UTC   364d                                    no      
apiserver                  Dec 11, 2026 08:35 UTC   364d            ca                      no      
apiserver-etcd-client      Dec 11, 2026 08:35 UTC   364d            etcd-ca                 no      
apiserver-kubelet-client   Dec 11, 2026 08:35 UTC   364d            ca                      no      
controller-manager.conf    Dec 11, 2026 08:35 UTC   364d                                    no      
etcd-healthcheck-client    Dec 11, 2026 08:35 UTC   364d            etcd-ca                 no      
etcd-peer                  Dec 11, 2026 08:35 UTC   364d            etcd-ca                 no      
etcd-server                Dec 11, 2026 08:35 UTC   364d            etcd-ca                 no      
front-proxy-client         Dec 11, 2026 08:35 UTC   364d            front-proxy-ca          no      
scheduler.conf             Dec 11, 2026 08:35 UTC   364d                                    no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Dec 08, 2035 03:06 UTC   9y              no      
etcd-ca                 Dec 08, 2035 03:06 UTC   9y              no      
front-proxy-ca          Dec 08, 2035 03:06 UTC   9y              no      

kubeadm config images list #查看当前kubeadm使用的镜像列表
W1211 09:05:36.225382   25467 version.go:103] could not fetch a Kubernetes version from the internet: unable to get URL "https://dl.k8s.io/release/stable-1.txt": Get "https://cdn.dl.k8s.io/release/stable-1.txt": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
W1211 09:05:36.225516   25467 version.go:104] falling back to the local client version: v1.22.0
k8s.gcr.io/kube-apiserver:v1.22.0
k8s.gcr.io/kube-controller-manager:v1.22.0
k8s.gcr.io/kube-scheduler:v1.22.0
k8s.gcr.io/kube-proxy:v1.22.0
k8s.gcr.io/pause:3.5
k8s.gcr.io/etcd:3.5.0-0
k8s.gcr.io/coredns/coredns:v1.8.4

#1,对现有的集群增加一个node3节点,在master节点上操作；
student@k8s-master:~$ sudo kubeadm token create --print-join-command --ttl 0
kubeadm join 192.168.126.100:6443 --token y9lqb9.ou7w9aa9rv8vayj9 --discovery-token-ca-cert-hash sha256:9fd7b2f70a1ff5d6697c8991d8330d8bb25c4c5e135f26c1862830a82c3ebaf2 
#在node3节点上操作
student@k8s-node3:~$ sudo kubeadm join 192.168.126.100:6443 --token y9lqb9.ou7w9aa9rv8vayj9 --discovery-token-ca-cert-hash sha256:9fd7b2f70a1ff5d6697c8991d8330
d8bb25c4c5e135f26c1862830a82c3ebaf2 
[preflight] Running pre-flight checks
        [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 24.0.2. Latest validated version: 20.10
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
####知识库###
#可能会出现node3节点长时间NotReady的情况；
student@k8s-master:~$ kubectl get nodes
NAME                         STATUS     ROLES                  AGE    VERSION
k8s-master.lab.example.com   Ready      control-plane,master   2d3h   v1.22.0
k8s-node1.lab.example.com    Ready      <none>                 2d3h   v1.22.0
k8s-node2.lab.example.com    Ready      <none>                 2d3h   v1.22.0
k8s-node3.lab.example.com    NotReady   <none>                 14s    v1.22.0
#检查目录/etc/cni/net.d是否存在；
sudo mkdir -p /etc/cni/net.d


#2,删除node3节点
student@k8s-master:~$ kubectl get nodes
NAME                         STATUS   ROLES                  AGE    VERSION
k8s-master.lab.example.com   Ready    control-plane,master   2d5h   v1.22.0
k8s-node1.lab.example.com    Ready    <none>                 2d5h   v1.22.0
k8s-node2.lab.example.com    Ready    <none>                 2d5h   v1.22.0
k8s-node3.lab.example.com    Ready    <none>                 121m   v1.22.0

student@k8s-master:~$ kubectl cordon k8s-node3.lab.example.com   #cordon就是打标签，告诉集群这个node不参加调度
node/k8s-node3.lab.example.com cordoned。  

student@k8s-master:~$ kubectl get nodes|grep node3
k8s-node3.lab.example.com    Ready,SchedulingDisabled   <none>                 138m   v1.22.0

student@k8s-master:~$ kubectl drain k8s-node3.lab.example.com   #drain就是把这个节点上的pod都驱逐掉
node/k8s-node3.lab.example.com already cordoned
DEPRECATED WARNING: Aborting the drain command in a list of nodes will be deprecated in v1.23.
The new behavior will make the drain command go through all nodes even if one or more nodes failed during the drain.
For now, users can try such experience via: --ignore-errors
error: unable to drain node "k8s-node3.lab.example.com", aborting command...

There are pending nodes to be drained:
 k8s-node3.lab.example.com
error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-system/calico-node-g97fc, kube-system/kube-proxy-chdm8

student@k8s-master:~$ kubectl drain k8s-node3.lab.example.com --ignore-daemonsets #忽略DaemonSet管理的Pod
node/k8s-node3.lab.example.com already cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/calico-node-g97fc, kube-system/kube-proxy-chdm8
node/k8s-node3.lab.example.com drained


student@k8s-node3:~$ sudo kubeadm reset -f 
[preflight] Running pre-flight checks
W1212 09:18:54.296076   84957 removeetcdmember.go:80] [reset] No kubeadm config, using etcd pod spec to get data directory
[reset] No etcd config found. Assuming external etcd
[reset] Please, manually reset etcd to prevent further issues
[reset] Stopping the kubelet service
[reset] Unmounting mounted directories in "/var/lib/kubelet"
[reset] Deleting contents of config directories: [/etc/kubernetes/manifests /etc/kubernetes/pki]
[reset] Deleting files: [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf]
[reset] Deleting contents of stateful directories: [/var/lib/kubelet /var/lib/dockershim /var/run/kubernetes /var/lib/cni]

The reset process does not clean CNI configuration. To do so, you must remove /etc/cni/net.d

The reset process does not reset or clean up iptables rules or IPVS tables.
If you wish to reset iptables, you must do so manually by using the "iptables" command.

If your cluster was setup to utilize IPVS, run ipvsadm --clear (or similar)
to reset your system's IPVS tables.

The reset process does not clean your kubeconfig files and you must remove them manually.
Please, check the contents of the $HOME/.kube/config file.


student@k8s-node3:~$ sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

student@k8s-master:~$ kubectl delete nodes k8s-node3.lab.example.com 
node "k8s-node3.lab.example.com" deleted




#3升级kubeadm集群
student@k8s-master:~$ sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.22.0
[upgrade/versions] kubeadm version: v1.22.0
I1216 07:56:55.624940  100002 version.go:255] remote version is much newer: v1.34.3; falling back to: stable-1.22
[upgrade/versions] Target version: v1.22.17
[upgrade/versions] Latest version in the v1.22 series: v1.22.17

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     3 x v1.22.0   v1.22.17

Upgrade to the latest version in the v1.22 series:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.22.0   v1.22.17
kube-controller-manager   v1.22.0   v1.22.17
kube-scheduler            v1.22.0   v1.22.17
kube-proxy                v1.22.0   v1.22.17
CoreDNS                   v1.8.4    v1.8.4
etcd                      3.5.0-0   3.5.0-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.22.17

Note: Before you can perform this upgrade, you have to update kubeadm to v1.22.17.

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________


#检查一下可以升级的版本
student@k8s-master:~$ apt-cache madison kubeadm
kubeadm | 1.22.17-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubeadm | 1.22.16-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubeadm | 1.22.15-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubeadm | 1.22.14-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages
   kubeadm | 1.22.13-00 | https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial/main amd64 Packages

#开始升级master 
sudo apt-get install kubeadm=1.22.17-00 kubelet=1.22.17-00 kubectl=1.22.17-00 -y
sudo systemctl restart kubelet
sudo kubeadm upgrade apply v1.22.17
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade/version] You have chosen to change the cluster version to "v1.22.17"
[upgrade/versions] Cluster version: v1.22.0
[upgrade/versions] kubeadm version: v1.22.17
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.22.17". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.

#升级node节点
k8s@k8s-master:~$ for i in {1..3};do ssh k8s-node${i} sudo apt-get install kubelet=1.22.17-00 -y;done
k8s@k8s-master:~$ for i in {1..3};do ssh k8s-node${i} sudo systemctl restart kubelet ;done
k8s@k8s-master:~$ kubectl get nodes
NAME                         STATUS   ROLES                  AGE   VERSION
k8s-master.lab.example.com   Ready    control-plane,master   5d    v1.22.17
k8s-node1.lab.example.com    Ready    <none>                 5d    v1.22.17
k8s-node2.lab.example.com    Ready    <none>                 5d    v1.22.17
k8s-node3.lab.example.com    Ready    <none>                 35m   v1.22.17

#k8s版本降级操作
#1,降级master节点
kubectl cordon k8s-master.lab.example.com
kubectl drain k8s-master.lab.example.com --ignore-daemonsets
sudo apt-get install kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00 -y --allow-downgrades
sudo kubeadm upgrade apply v1.22.0 -y
sudo systemctl restart kubelet
kubectl uncordon k8s-master.lab.example.com

#2,降级node节点
for i in {1..3};do ssh k8s-node${i} sudo apt-get install kubelet=1.22.0-00 -y;done
for i in {1..3};do ssh k8s-node${i} sudo systemctl restart kubelet ;done



