---
title: 기술 블로그 만들기
description: 기술 블로그 제작과정을 정리합니다. 급조하다 보니 개념을 덜 짚고 우선 가져다 붙인 것도 많은데 차츰 보완하려고 합니다. 기술블로그 개설은 선택지가 많다보니 이유있는 선택은 하고 싶고 빨리는 만들고 싶고 선택 자체가 고충이었습니다. 여전히 끝나지 않는 선택의 연속입니다.
date: 2021-05-09 19:00 +09:00
categories: 노카테고리
badges:
- type: info
  tag: info-badge
rightpanel: true
---

# 만들게 된 동기

"나 혼자 알아먹고 끝나는 공부는 2%? 20% 부족하다" 스터디를 하고 발표를 하고, 교육을 진행해 보면서 
아는 것과 잘 전달하는 것을 고민하게 되고 잘 전달하기 위해서는 나 혼자 알아먹는 수준으로는 한참 부족한 것을 알게되었습니다.  

1) 공부하고..
2) 정리하고..
3) 나눈다

나누는 과정을 통해서 더 잘 알게 되기를 희망하며 기술블로그를 시작합니다. 

## 기술블로그 플랫폼 선택

예전에 사용했던 포털 블로그로 글을 올릴까 아주 잠깐 고민했었다가 ㅎㅎ 블로그 털렸었던 추억과 블로그 팔라고 날라오던 문자들을 떠올리며 제낍니다.
무엇보다 저는 깃헙 블로그를 동경하고 있더라고요. 깃헙을 통해 실습코드/스크립트 공유도 하고 그리고 코드도 이쁘게 올릴수 있을 것 같고 말이죠.
다만, 손이 많이 가고 러닝커브가 걱정이 되었습니다. 그래서 쉽게 평소 즐겨쓰는 에버노트나 비슷한? 노션으로 쉽게 해볼 수 있을까도 생각해 보았구요.
이런 저런 고민하느니 ... 깃헙으로 "바로 고 ~"  

## github.io 와 jekyll 

사실 react를 사내에서 스터디를 하고 있어서 react로 하고 싶긴 했는데요. github.io 기반 기술블로그는 jekyll을 사용하는 사례가
많이 검색이 되었고, jekyll "바로 고~" :-) 기술에 집중하기 위해서 빨리 가즈아~하는 마음이었습니다.  
나쁘지 않은 선택인 것 같아요. 이미 앞선 기술블로그 선배님들이 친절히, 너무나도 잘 설명을 남겨주신 덕분에 뚝딱~ 만들어지는 기쁨을 누립니다.
정말.. 글 잘쓰시는 분들 많으세요. (박수~)

# 제작과정

## jekyll 설치
- Jekyll 이란?
- Ruby Gem Jekyll
- 템플릿
- md (마크다운) --> html 변환

## jekyll 템플릿
- 종류가 어마어마하게 많음.
- docsy로 선택. UI가 그나마 간단했음.

## {username}.github.io 리포 생성하기
- repository명을 {username}.github.io 이렇게 생성해야 웹사이트로 사용가능합니다.
  - username은 변경 가능함
  - jekyll 템플릿 git repo를 fork 한 후에 rename 하는게 편해요
  
## 코멘트 달기 (utterance)
- utterances
  - 깃헙 issues를 스토리지로 사용
    - 댓글을 남기면 깃헙 issue로 등록함
    - 코멘트를 깃헙 issue로 등록할 때 본문 url, pathname, title, 기타 식별코드 .. 등을 지정할 수 있음
      - github search api를 사용하여 본문에 등록된 깃헙 issue 쓰레드가 있는지 찾아서 리스트를 출력함
      - 댓글 등록 시 github search가 실패하는 경우 최초 댓글로 판단하고 utterance bot이 새로운 issue를 생성해줌
  - 깃헙 계정을 가진 사용자들이 댓글(즉, 깃헙이슈)을 남길 수 있음
- disqus
  - 많이 사용들 하지만..
  - 댓글 남기려면 disqus 회원가입 필요함
  - 페북 공유 시 에러 있음

## 구글 analytics 달기 
- 구글 analytics 가입

## 소셜 공유를 위한 og meta 태그 설정 
- open graph meta 태그 설정 필요
  - og:url - url은 공유 url과 일치 해야함
  - og:image  - 공유 시 사용할 이미지
- 페북 공유 테스트 : https://developers.facebook.com/tools/debug/?q=https%3A%2F%2Fnetpple.github.io%2Fdocs%2Fmake-container-without-docker%2Fcontainer-internal-2
- jekyll의 page meta 설정 예시
```
---
title: 컨테이너 인터널 1편    --> og:title 등에 사용
description: 컨테이너의 개념을 설명하고 컨테이너의 시작이라 할 수 있는 chroot에 대해 다룹니다 --> og:description 등에 사용
comments: true  --> disqus 댓글 컴포넌트 활성 여부  (내가 추가)
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-1.png     --> og:image (페북 공유이미지로 사용) (내가 추가)
rightpanel: true  --> 우측날개 사용여부 (내가 추가)
```

## 반응형 웹UI 삽질기 

###  기기 화면비율에 따른 구글슬라이드 여백 이슈 처리
- media의 최대너비를 보고 높이 비율 차등 적용 (max-width: 768px 모바일로 가정)
- viewport : vw(너비), vh(높이)
  - 실제 기기의 화면 기준으로 길이 표현
```css
.responsive-wrap ifram{height: 38vw;}
@media ( max-width: 768px ) {
  .responsive-wrap iframe{height: 60vw;}
}
```

## jekyll 관련 알아두면 좋은 것
### date
- 날짜가 미래 날짜이면 "_site"폴더로 배포되지 않습니다. 글 쓸 때 유용한 것 같아요 :-)