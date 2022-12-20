---
title: 2편.컨테이너 인터널(2)
version: v1.2
description: 1편에 이어 chroot의 탈옥문제를 해결하는 pivot_root를 다루고 남은 문제들을 해결하는 컨테이너의 발전과정을 살펴봅니다. 컨테이너가 신기술, 유행 같은 것이라고 생각했었는데, 나름 역사와 사연이 많은 친구네요. chroot로 시작하여 지금의 컨테이너로 성장하기까지 어떤 문제들이 있었고 그러한 문제들을 어떻게 해결하여 왔는지를 다뤄봅니다.
date: 2021-04-27 12:39:00 +09:00
label: 도커 없이 컨테이너 만들기
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-2.png
histories:
- date: 2021-05-03 21:35:00 +09:00
  description: 실습 안내페이지 업데이트
---
<div class="responsive-wrap">
    <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vQ8Umma-Erc8I2_5CGfAVnzUYLzj0Aheq8XZoeLlJI5ox3pGdIwJHFP8FrObmKV1K2BbT9zgdZKTNUO/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1ROUHDBp1l7oP6wcCO-kfj9tQHHjDQg5gFm1FXr5IB1I/edit#){:target="_blank"}

사내 블로그(카카오 엔터프라이즈)에 기고한 [컨테이너 톺아보기](https://tech.kakaoenterprise.com/154) 문서도 함께 참고해 주세요. 발표 장표를 보충할 설명들을 자세하게 기술해 두었습니다.

### references

- [컨테이너 요약/실습 : http://tailhook.github.io/containers-tutorial/#/step-27](http://tailhook.github.io/containers-tutorial/#/step-27){:target="_blank"}