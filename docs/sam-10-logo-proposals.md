## SAM-10 로고 시안 제안서

작성일: 2026-03-13
대상: netpple.github.io 로고 리디자인

## 기준
- 기존 사이트 톤(차분한 블루 계열)을 유지하면서 소형 아이콘 가독성 우선
- 헤더 로고/파비콘/핀드 탭으로 확장 가능한 단순 기하 형태 채택

## 시안 A: Network Ring
- 파일: `assets/img/branding/logo-concept-a-network.svg`
- 의도
  - 연결성/네트워크 메타포를 노드와 링크로 직관화
- 평가
  - 가독성: 중간 (16px 축소 시 노드 디테일 손실 가능)
  - 확장성: 높음 (다이어그램/배지 변형 용이)

## 시안 B: Beacon Monogram (선택안)
- 파일: `assets/img/branding/logo-concept-b-beacon.svg`
- 의도
  - 라운드 스퀘어 + N 모노그램으로 앱 아이콘과 헤더 동시 대응
  - 상단 포인트로 "지식 신호" 이미지 강화
- 평가
  - 가독성: 높음 (16px에서도 형태 유지)
  - 확장성: 높음 (favicon/OG/배너 재사용 용이)

## 시안 C: Hex Wave
- 파일: `assets/img/branding/logo-concept-c-hexwave.svg`
- 의도
  - 육각 프레임과 파형으로 플랫폼/엔지니어링 성격 강조
- 평가
  - 가독성: 중상 (내부 파형 두께 보정 필요)
  - 확장성: 중상 (섹션 배지/엠블럼 전개에 강점)

## 선택 결과
- 선택안: **시안 B (Beacon Monogram)**
- 선택 근거
  - 소형 파비콘 환경에서 식별성이 가장 안정적
  - 현재 사이트 컬러 톤과의 조화가 가장 좋음
  - 헤더/파비콘/핀드탭까지 단일 모티프로 일관 적용 가능

## 반영 파일
- `_includes/logo.svg`
- `_includes/head.html`
- `assets/favicons/*`
