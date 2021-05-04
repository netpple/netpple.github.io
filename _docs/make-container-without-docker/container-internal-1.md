---
title: 1편.컨테이너 인터널(1)
description: 컨테이너의 개념을 설명하고 컨테이너의 시작이라 할 수 있는 chroot에 대해 다룹니다.
date: 2021-04-23 08:25:00 +09:00
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-1.png
rightpanel: false
---
<div class="responsive-wrap">
    <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vSu05m9Z8rpMxhl1AyF5PC-7iAtekYXuCkmCTPKEKc-jGh_ui9MN9AfxAMJ3tdxPa6UUrM6Cv_PYYRd/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1Z9RcxEy0I5Xq6yd6JHQ8hBTgsfjcwHJ2NoHkl_KL3TY/edit#){:target="_blank"}

### references
- [container internal (detail) : https://leezhenghui.github.io/microservices/2018/10/20/build-a-scalable-system-runtime-challenges.html](https://leezhenghui.github.io/microservices/2018/10/20/build-a-scalable-system-runtime-challenges.html) 
- [container internal (detail) : https://itnext.io/breaking-down-containers-part-0-system-architecture-37afe0e51770](https://itnext.io/breaking-down-containers-part-0-system-architecture-37afe0e51770)
- [chroot/namespaces : https://medium.com/@saschagrunert/demystifying-containers-part-i-kernel-space-2c53d6979504](https://medium.com/@saschagrunert/demystifying-containers-part-i-kernel-space-2c53d6979504])
- [chroot (detail) : https://blog.selectel.com/containerization-mechanisms-namespaces/](https://blog.selectel.com/containerization-mechanisms-namespaces/)
- [namespace/process : https://ssup2.github.io/onebyone_container/3.4.Namespace_with_Process/](https://ssup2.github.io/onebyone_container/3.4.Namespace_with_Process/)
- [Mount namespace: https://milhouse93.tistory.com/85](https://milhouse93.tistory.com/85)
- [Capabilities : https://man7.org/linux/man-pages/man7/capabilities.7.html](https://man7.org/linux/man-pages/man7/capabilities.7.html])