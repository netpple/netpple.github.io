---
title: 5편.마운트 네임스페이스와 overlayFS  
description: 1,2편에서 다룬 chroot와 pivot_root를 통해서 root filesystem을 isolation하였습니다. 마운트 네임스페이스는 파일시스템 마운트를 isolation 하는 것으로 이미 pivot_root에서도 사용하였지만, mount 처리를 격리함으로써 컨테이너 내부의 파일시스템 구조를 독립적으로 유지합니다. 실제 도커 컨테이너의 이미지 tarball을 이용하여 pivot_root와 mount namespace까지 적용하여 실제 도커 방식과 유사하게 컨테이너를 기동하여 봅니다. 그리고, 컨테이너 이미지 용량/중복을 해결하기 위한 overlayFS 에 대하여 다룹니다.       
date: 2021-05-09 23:15:00 +09:00
label: 도커 없이 컨테이너 만들기
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-5.png
histories:
- date: 2021-05-09 23:15:00 +09:00
  description: 최초 게시
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vRBV22GjJhwirgAGcAmEu7qH0Fi9VUUwHz1vaLmWYWmS8gFfp7-g3ArVQ3w1YxgYP3B56f2noQDN7Kf/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1rQQzmg83m_lU6mcIy2eZSXDlLqKmJB748GfPeHDWTeI/edit#){:target="_blank"}