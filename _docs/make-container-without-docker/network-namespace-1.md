---
title: 3편.네트워크 네임스페이스(1)
version: v1.3
label: 도커 없이 컨테이너 만들기
description: 서비스 운영 중에 네트웍 장애를 만나면 곤란하곤 하는데요. 컨테이너는 가상 네트웍을 기반으로 하고 있고 이 위에서 컨테이너 간의 통신이 어떻게 이루어지는지를 잘 이해하고 있으면 개발과 운영에 많은 도움이 됩니다. 네트워크 네임스페이스를 이해하기 위한 네트워크 기초 개념들을 다루고 네트워크 네임스페이 실습과 함께 컨테이너 환경에서의 가상 네트워크 구축이 어떻게 이루어지는지를 학습합니다.
date: 2021-04-29 11:41:00 +09:00
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-3.png
badges:
- type: info
  tag: updated
histories:
- date: 2021-05-03 21:35:00 +09:00
  description: 실습 안내페이지 업데이트
---
<div class="responsive-wrap">
    <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vTOsEXasBt7H7qHJNNNOn4RQKzgWnsXQriK0hh2UEAP2AyKr4gnFqlEPF0nOe8no55mByBhzrqdZR7U/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/1NhzhNDiWTCIKCViWPW8Wvza8GrT56xugymX5TV-WLbc/edit#){:target="_blank"}

### references
- [Ethernet and IP Networking 101](https://iximiuz.com/en/posts/computer-networking-101/){:target="_blank"}
- [Container Networking Is Simple](https://iximiuz.com/en/posts/container-networking-is-simple/?fbclid=IwAR0-ohNRdnoQgcCCQSAyhGtPNsJ8tBL_Fd1YUSOscXFsSrr_eXIRu6PKO28){:target="_blank"}
- [Introduction to Linux interfaces for virtual networking](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/){:target="_blank"}
- [네트워크 IP와 해저케이블](https://givmemoney.tistory.com/entry/%EB%AC%B8%EA%B3%BC%EB%8F%84-%EC%9D%B4%ED%95%B4%EA%B0%80%EB%8A%A5%ED%95%9C-%EC%BB%B4%EA%B3%B5-%ED%95%84%EC%88%98%EC%A7%80%EC%8B%9D-%E2%91%A0%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC-IP%EC%99%80-%ED%95%B4%EC%A0%80%EC%BC%80%EC%9D%B4%EB%B8%94?fbclid=IwAR0s1WjF10jtC6gw3A7G15pM5uzlMRT-q3yewX61RESfcwDsimOTy_QEXPA){:target="_blank"}
- [OSI 7계층과 TCP/IP 4계층(심화)](http://blog.naver.com/PostView.nhn?blogId=demonicws&logNo=40117378644&fbclid=IwAR04l6c8pmeq08QVKLwENS8jg-0ZbbW_OGxmOduojUr5EFX_EKSsoGpvImw){:target="_blank"}
- [OSI 7Layer Data Capsulation]( https://www.computernetworkingnotes.com/ccna-study-guide/data-encapsulation-and-de-encapsulation-explained.html?fbclid=IwAR3OQKhMcnbhhBhby9H4yVtDmli8dy3m7M28ZWPnPWLjvZEiNEJQw8dOv68){:target="_blank"}
- [Understanding TCP/IP Network Stack & Writing Network Apps](https://www.cubrid.org/blog/3826497){:target="_blank"}
- [계층별 네트워크 장비](https://handreamnet.tistory.com/308){:target="_blank"}
- [이더넷 프레임](https://mintnlatte.tistory.com/356){:target="_blank"}
- [Linux bridge](https://wiki.linuxfoundation.org/networking/bridge){:target="_blank"}
- [Linux Firewalls Using iptables](http://borg.uu3.net/iptables/iptables-intro.html?fbclid=IwAR390DFt4RIfSoPITCv7YS2n7J43W3lRgtLF_2T_nvj-W4bE9boJ9fZPX9c){:target="_blank"}
- [A Deep Dive into Iptables and Netfilter Architecture](https://www.digitalocean.com/community/tutorials/a-deep-dive-into-iptables-and-netfilter-architecture){:target="_blank"}
