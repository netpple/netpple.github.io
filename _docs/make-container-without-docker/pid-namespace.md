---
title: 8편.PID 네임스페이스  
description: pid namespace는 컨테이너 안에서 독자적인 "process tree" / "process id 체계"를 제공합니다. 어떻게 가능한 것일까요? 이를 이해하기 위하여 proc filesystem과 pid 쳬계에 대해서 얘기합니다. 그리고 프로세스 트리의 최상위인 특별한 프로세스 pid1 에 대하여도 다룹니다 
date: 2021-05-25 09:00:00 +09:00  
label: 도커 없이 컨테이너 만들기  
comments: true  
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-8.png  
badges:
- type: light  
  tag: new  
histories:  
- date: 2021-05-25 09:00:00 +09:00  
  description: 최초 게시  
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vSU7CRFtNv8nFEUPwfow0HfbrMqPNmYJ7I95z_GHf8_fonz-wvsVdL4vrfNdFkfNbYhxh9hAg4tQbuS/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1CY3lXDpWSsNbp8mhUsQAsp474jY7THt7CpCf5dWdLEc/edit?usp=sharing#){:target="_blank"}