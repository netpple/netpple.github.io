---
title: 6편. kube-scheduler  
description: 쿠버네티스의 공인중개사 스케줄러를 소개합니다. 스케줄러가 파드가 원하는 노드를 골라내는 방법을 설명하고 스케줄러의 구조와 확장에 대해서 얘기합니다.
date: 2022-04-15 10:00:00 +09:00
label: 쿠버네티스 딥다이브
comments: true
image: https://netpple.github.io/docs/assets/img/deepdive-into-kubernetes-6-kube-scheduler-deepdive.png
histories:
- date: 2022-04-15 10:00:00 +09:00
  description: 최초 게시
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRvsEaVbT3zV94Ro2fMvzm2Q1WCgNGOfjP7Myn3q-xJhBebQOzPGzMYv9xch-M_3bCJHA6Xi0sXyVK4/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1vTNfO-Vi4WAgaDO8dF7Pv6HB_F3zVUZZI8rIHaQSrxM/edit#){:target="_blank"}

### references
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/){:target="_blank"}
- [Scheduler Algorithm in Kubernetes](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-scheduling/scheduler_algorithm.md){:target="_blank"}
- [Kubernetes Scheduler](https://www.bookstack.cn/read/kubernetes-1.16-zh/9439d7205ea09efd.md#Default%20policies){:target="_blank"}
- [Kubernetes Deep Dive: kube-scheduler](https://aws.plainenglish.io/kubernetes-deep-dive-kube-scheduler-9e6328a72a2){:target="_blank"}
- [Scheduler Profiles](https://kubernetes.io/docs/reference/scheduling/config/#profiles){:target="_blank"}
- [Scheduler Benchmarking](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-scheduling/scheduler_benchmarking.md){:target="_blank"}