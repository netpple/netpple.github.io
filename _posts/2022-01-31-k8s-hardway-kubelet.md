---
title: k8s hardway (1) kubelet
version: v1.0
description: kubelet standalone :static pod
date: 2022-01-31 09:00 +09:00
categories: kubernetes
badges:
- type: info
  tag: 실습
  rightpanel: false
---
<!--more-->
참고: [https://kamalmarhubi.com/blog/2015/08/27/what-even-is-a-kubelet/](https://kamalmarhubi.com/blog/2015/08/27/what-even-is-a-kubelet/) 

- kubelet 구버전이랑 옵션이 달라서 약간 수정함

## 개요

kubelet을 standalone으로 직접 기동하여 봅니다. pod 명세를 특정 경로(manifests)에 파일로 저장하면 static-pods를 띄우도록 구성해 봅니다.

![/assets/img/k8s-hardway-kubelet-manifests.png](/assets/img/k8s-hardway-kubelet-manifests.png)


## 실습 환경
Vagrant/VirtualBox (macOS BigSur 11.5)
```ruby
# vi Vagrantfile

BOX_IMAGE = "bento/ubuntu-18.04"
HOST_NAME = "ubuntu1804"

$pre_install = <<-SCRIPT
  echo ">>>> disable swap <<<<"
  sudo swapoff -a
  sudo sed -i '/swap/d' /etc/fstab
  
  ## apt-get noninteractive
  export DEBIAN_FRONTEND=noninteractive
  
  echo ">>>> pre-install <<<<<<"
  sudo apt-get -qq update &&
  sudo apt-get -qq install jq tree

  echo ">>>>> install docker <<<<<<"
  sudo apt-get -qq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common &&
  sudo curl --stderr /dev/null -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
  sudo apt-get -qq update &&
  sudo apt-get -qq install docker-ce docker-ce-cli containerd.io
SCRIPT

Vagrant.configure("2") do |config|

 config.vm.define HOST_NAME do |subconfig|
   subconfig.vm.box = BOX_IMAGE
   subconfig.vm.hostname = HOST_NAME
   subconfig.vm.network :private_network, ip: "192.168.104.2"
   subconfig.vm.provider "virtualbox" do |v|
     v.memory = 1536
     v.cpus = 2
   end
   subconfig.vm.provision :shell, inline: $pre_install
 end

end
```

## kubelet 기동

다운로드 (.. or 직접빌드:[/2022/kubernetes-develop-environment/](/2022/kubernetes-develop-environment/))

```bash
sudo wget https://storage.googleapis.com/kubernetes-release/release/v1.19.5/bin/linux/amd64/kubelet
sudo chmod +x kubelet
```

기동

```bash
mkdir manifests
# sudo docker info | grep 'Cgroup Driver'
sudo ./kubelet --pod-manifest-path=$PWD/manifests --cgroup-driver cgroupfs 
```

kubelet (1.19.5) 기동 로그

```bash
I0122 01:17:10.801432   29898 server.go:411] Version: v1.19.5
..

I0122 01:17:10.877171   29898 client.go:77] Connecting to docker on unix:///var/run/docker.sock
..
```

kubelet(1.21.1) 기동 로그

```bash
..
I0122 01:27:07.789917     676 server.go:440] "Kubelet version" kubeletVersion="v1.21.1"
..
I0122 01:27:07.867805     676 client.go:78] "Connecting to docker on the dockerEndpoint" endpoint="unix:///var/run/docker.sock"
..
```

## pod 명세 추가

```yaml
# vi manifests/nginx.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /var/log/nginx
      name: nginx-logs
  - name: log-truncator
    image: busybox
    command:
    - /bin/sh
    args: [-c, 'while true; do cat /dev/null > /logdir/access.log; sleep 10; done']
    volumeMounts:
    - mountPath: /logdir
      name: nginx-logs
  volumes:
  - name: nginx-logs
    emptyDir: {}
```

## 확인

### Pod 기동 로그

```bash
..
W0122 01:17:43.372866   29898 docker_sandbox.go:402] failed to read pod IP from plugin/docker: Couldn't find network status for default/nginx-ubuntu1804 through plugin: invalid network status for
..

```

### 도커

```yaml
sudo docker ps
```

![/assets/img/k8s-hardway-kubelet-docker-ps.png](/assets/img/k8s-hardway-kubelet-docker-ps.png)

### kubelet api

```bash
curl http://localhost:10255/healthz
curl --stderr /dev/null http://localhost:10255/pods | jq .
```

![/assets/img/k8s-hardway-kubelet-pstree.png](/assets/img/k8s-hardway-kubelet-pstree.png)