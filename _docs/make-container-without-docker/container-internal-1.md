---
title: 1편.컨테이너 인터널(1)
version: v1.2
date: 2021-04-23 08:25:00 +09:00
description: 컨테이너란 무엇일까요? 마법 상자를 열어 보도록 하겠습니다.제가 처음 도커를 접했을 때는 "vmware, virtualbox 와 뭐가 다르지?" vmware처럼 OS이미지도 있었고 터미널 환경에서 동작하는 모습 역시 똑같아 보였거든요.그렇게 시작하게 되었습니다. 도커는 무엇이고 컨테이너는 무엇인지 실체가 궁금하더라구요 컨테이너의 개념을 설명하고 컨테이너의 시작이라 할 수 있는 chroot에 대해 다룹니다.
label: 도커 없이 컨테이너 만들기
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-1.png
badges:
- type: info
  tag: updated
histories:
- date: 2021-05-04 22:45:00 +09:00
  description: reference 업데이트
- date: 2021-05-03 21:35:00 +09:00
  description: 실습 안내페이지 업데이트
rightpanel: false
---
<div class="responsive-wrap">
    <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vSu05m9Z8rpMxhl1AyF5PC-7iAtekYXuCkmCTPKEKc-jGh_ui9MN9AfxAMJ3tdxPa6UUrM6Cv_PYYRd/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1Z9RcxEy0I5Xq6yd6JHQ8hBTgsfjcwHJ2NoHkl_KL3TY/edit#){:target="_blank"}

### references
- [container internal (detail) : https://leezhenghui.github.io/microservices/2018/10/20/build-a-scalable-system-runtime-challenges.html](https://leezhenghui.github.io/microservices/2018/10/20/build-a-scalable-system-runtime-challenges.html){:target="_blank"} 
- [container internal (detail) : https://itnext.io/breaking-down-containers-part-0-system-architecture-37afe0e51770](https://itnext.io/breaking-down-containers-part-0-system-architecture-37afe0e51770){:target="_blank"}
- [chroot/namespaces : https://medium.com/@saschagrunert/demystifying-containers-part-i-kernel-space-2c53d6979504](https://medium.com/@saschagrunert/demystifying-containers-part-i-kernel-space-2c53d6979504]){:target="_blank"}
- [chroot (detail) : https://blog.selectel.com/containerization-mechanisms-namespaces/](https://blog.selectel.com/containerization-mechanisms-namespaces/){:target="_blank"}
- [namespace/process : https://ssup2.github.io/onebyone_container/3.4.Namespace_with_Process/](https://ssup2.github.io/onebyone_container/3.4.Namespace_with_Process/){:target="_blank"}
- [Mount namespace: https://milhouse93.tistory.com/85](https://milhouse93.tistory.com/85){:target="_blank"}
- [Capabilities : https://man7.org/linux/man-pages/man7/capabilities.7.html](https://man7.org/linux/man-pages/man7/capabilities.7.html]){:target="_blank"}