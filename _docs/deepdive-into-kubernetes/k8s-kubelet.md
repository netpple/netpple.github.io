---
title: 7편. kubelet
version: v1.0
label: 쿠버네티스 딥다이브
description: 쿠버네티스의 노드 담당자 kubelet에 대해 얘기합니다. kubelet이 어떤 일을 하고 어떻게 동작하는지 kubelet의 구조를 같이 살펴보면서 이해하는 시간을 갖도록 하겠습니다.     
date: 2022-05-10 10:00:00 +09:00
comments: true
image: https://netpple.github.io/docs/assets/img/deepdive-into-kubernetes-7-kubelet.png
histories:
- date: 2022-05-10 10:00:00 +09:00
  description: 최초 등록
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRc6oMsAYrOevqIb-zGH5ANcarxW-TTpkuv986CiRWJL64eWHHDYiW2MPOBWgQW56pp4TJUy2z42dIS/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1fVYobLDfPWq77jIH536ST0a425f4QjVkr3dFitTIkyI/edit#){:target="_blank"}

### references
- [Kubelet create pod workflow](https://blog.hdls.me/15961134056881.html){:target="_blank"}
- [Kubelet API](https://www.deepnetwork.com/blog/2020/01/13/kubelet-api.html){:target="_blank"}
- [Kubernetes - Beyond a Black Box](https://www.slideshare.net/harryzhang735/kubernetes-beyond-a-black-box-part-1){:target="_blank"}
- [Kubernetes Design Proposals PLEG](https://github.com/kubernetes/design-proposals-archive/blob/main/node/pod-lifecycle-event-generator.md){:target="_blank"}

