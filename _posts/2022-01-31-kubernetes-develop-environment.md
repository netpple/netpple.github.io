---
title: k8s 빌드환경 셋업
version: v1.0
description: kubernetes 빌드환경 셋업 Vagrantfile
date: 2022-01-31 08:00 +09:00
categories: kubernetes
badges:
- type: info
  tag: 코드 
rightpanel: false
---
참고: [https://developer.ibm.com/articles/setup-guide-for-kubernetes-developers/](https://developer.ibm.com/articles/setup-guide-for-kubernetes-developers/)

Vagrant + VirtualBox (Ubuntu 1804)

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_IMAGE = "bento/ubuntu-18.04"
DOCKER_VERSION = "5:19.03.15~3-0~ubuntu-bionic"
K8S_GIT_TAG = "v1.19.16"
GO_VERSION = "1.17.6"

Vagrant.configure("2") do |config|
  config.vm.provision :shell, privileged: true, env: {"DOCKER_VERSION"=>DOCKER_VERSION, "GO_VERSION"=>GO_VERSION}, inline: $install_common_tools
  config.vm.provision :shell, privileged: false, env: {"K8S_GIT_TAG"=>K8S_GIT_TAG}, inline: $git_clone
  config.vm.define "kubelet-test" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "kubelet-test"
    subconfig.vm.network :private_network, ip: "192.168.102.2"
    config.vm.provider "virtualbox" do |v|
      v.memory = 8192
      v.cpus = 8
    end
  end

end

# privileged: true (root)
$install_common_tools = <<-SCRIPT
## disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab
## apt-get noninteractive
export DEBIAN_FRONTEND=noninteractive
## -qq : really quiet (except errors)
apt-get -qq update

##  pre-requisite - gcc make
apt-get -qq install gcc make

##  install Docker
apt-get -qq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common &&
curl --stderr /dev/null -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
apt-get -qq update &&
apt-get -qq install docker-ce=${DOCKER_VERSION} docker-ce-cli=${DOCKER_VERSION} containerd.io
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl restart docker
usermod -aG docker vagrant

## install Golang
curl --stderr /dev/null -O https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a /etc/profile
SCRIPT

# privileged: false (vagrant)
$git_clone = <<-SCRIPT
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout -b ${K8S_GIT_TAG}
## build
sudo make clean
sudo make all WHAT=cmd/kubelet GOFLAGS=-v
SCRIPT
```

make 옵션

- make all : 전체 빌드
    - 특정 컴포넌트 빌드 예) make all WHAT=cmd/kubelet
      컴포넌트: kubelet,kube-apiserver,kube-controller-manager,kube-scheduler,kube-proxy,kubectl,kubeadm,...
- make release : 빌드 + 이미지