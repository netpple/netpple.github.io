---
title: 7. 트랜잭션  
description: 야생의 분산환경에서 시스템간의 여러가지 연산을 어떻게 잘 처리할 수 있을까요? 트랜잭션에 대해 알아봅니다.        
date: 2022-12-09 8:00:00 +09:00
label: 데이터중심 애플리케이션
comments: true
histories:
- date: 2022-12-09 8:00:00 +09:00
  description: 최초 게시
---
# 7.트랜잭션

### 용어

- 트랜잭션
  - [사전,어원] trans(이동)+act(행동)+ion[명사], **거래**. 쌍방이 존재하고 오고가는(처리하는) 대상이 존재.
- **Atomicity** ~ 하나로 처리되는 연산 묶음. **All-or-nothing** (부분성공없음), Abortability (완벽한 되돌리기)
- Consistency ~ 애플리케이션의 몫. (알아서 잘 넣고 빼고 잘 판단 ~)
- **Isolation** ~ 격리. **동시성** 문제. 트랜잭션 간 간섭(race condition, conflict)이 없어야 함. 커밋되지 않은 정보가 다른 트랜잭션에 보여선 안됨.(dirty read) ⇒ **이 챕터의 대부분을 할애**
- Durability ~ 지속성, Persistence, Safety. “완벽한 지속성은 없다” ⇒ 백업/복구. 복제와 다른 점은 중단을 허용. (복제는 HA)
- Serializable - 직렬성. 한번에 하나씩 순서대로 처리되는 것과 같은 결과를 보장.

### 트랜잭션이란? 왜 필요 ?

- 시스템 환경은 야생이고 언제든 **다양한 이유(문제)로 실패**할 수 있음
- 이러한 문제들에 대한 내결함성을 갖춘 신뢰성 있는 시스템이 되려면?
- 할 일이 많다 .. (켁)
- 트랜잭션은 ****이런 **“문제” 를 단순화 하는 메커니즘**으로 채택되옴 (수십년 동안)
- 트랜잭션이란 몇 개의 읽기와 쓰기를 **“하나”로 묶는 방법**.
- 트랜잭션이 복잡한 문제를 먹어줌 ⇒ 애플리케이션의 구현이 심플해짐

### 완화된 격리수준

“**성능**"을 위해서 “**Lock**”을 안쓰고 해보려고 안간 힘. ⇒ “동시성” 문제를 다룸

### Read-Committed (2VCC, )

- 널리 쓰임 (오라클11g, postgreSql, SQL SERVER 2012, MemSQL 등)
- Dirty-read (그림.7-4) ~ 2VCC ⇒ **커밋된 버전만 노출. *Read는 Lock 안씀 (트랜잭션 간에 읽기를 차단하지 않음)**
- Dirty-write (그림.7-5 쇼핑몰) ~ Row Lock. 쓰기 접근을 막음
- (p.236-237 요약 굿)“**커밋 후 읽기** 격리를 피상적으로 보면 트랜잭션이 해야 하는 모든 일을 해 주는 것으로 생각하는 것도 무리가 아니다. abort를 허용하고 (원자성에 필요) 트랜잭션의 미완료된 결과를 읽는 것(dirty read)을 방지하며 동시에 실행되는 쓰기가 섞이는 것(dirty write)을 막아준다.”

### Snapshot (MVCC, 그림.7-7 계좌잔고)

- 스냅숏 ⇒ “버전”
- **Read-Skew** (**timing**anomaly, 그림.7-6 계좌잔고) **일시적** inconsistency ⇒ **Read-Committed로 못막음**
  - 문제 사례 : (원본DB가 지속적으로 변경되는 상황에서) 대용량 백업, 대용량 스캔 ⇒ **“시점”상 불일치**를 포함할 가능성이 높음
- “**시점"을 고정** ⇒ “**스냅숏**". 일관성(consistency) 확보
- 널리 쓰임 (postgreSQL, *[InnoDB](https://www.notion.so/DB-Storage-Engine-InnoDB-vs-MyISAM-a17b2d50318f41e385a1e466324ef316)* 엔진 (mysql, oracle, sql server))
- Dirty-write ~ Lock 사용 (쓰기 중인 객체에 대한 다른 트랜잭션의 접근 차단)
- **Read는 Lock 안씀 ~ 트랜잭션 간에 읽기를 차단하지 않음**
- **MVCC** ~ Read-Committed 일반화
  - 쓰기마다 “**트랜잭션ID**”(txid) 기록 (postgreSQL 예시)
- 가시성 규칙 ~ 일관된 스냅숏 제공. “**트랜잭션ID**”로 결정. “3**무시**”
  - 무시1. 진행 중인 트랜잭션
  - 무시2. 어보트된 트랜잭션
  - **무시3. 더 큰 txid 트랜잭션**
- 색인 동작 (전략)
  - 볼 수 없는 버전 걸르기
  - append-only/CoW 전략
  - 추가전용 B-트리 ⇒ Compaction, GC 필요

### Lost-Update 문제 (그림.7-1 동시카운터)

- 2VCC, MVCC ⇒ **Read는 Lock 안씀**  ⇒ Lost-Update 문제 발생
- 2VCC, MVCC ⇒ “읽기"시점과 “저장"시점 사이에 다른 트랜잭션으로 부터 객체에 변경이 발생한 경우에 현재 트랜잭션에서 알 수가 없음 (Lost-Update)
- Lost-Update 사례
  - 동시 카운터 (카운터를 **읽고** 변경 후 - 저장)
  - json, yaml 갱신 (yaml을 **읽고**(파싱) - 변경 후 - 저장)
  - 좌석 예약 (빈 좌석여부를 **읽고** - 변경(예약) 후 - 저장)
  - 위키 문서의 공동 편집 (동일 페이지를 **읽고** - 변경 후 - 저장)
- 해결 전략
  - 전략1. 원자적 쓰기 ~ DB에서 “**Lock**" 제공. DB 자체적으로 연산(read-modify-write)을 묶어서 제공
  - 전략2. 명시적 잠금 ~ 애플리케이션에서 “**Lock**" 사용 (SELECT ~ FOR UPDATE 등)
  - 전략3. Lost-Update **감지** (자동) ⇒ **abort & retry** (p.244) Q) SSI 가 이거 아닌가? Y (p.261)
    - DB에서 원자적 **CAS** (Compare-And-Set) 제공 필요
  - 한계점: “복제” 상황
    - Lock과 CAS의 가정 ~ “**복사본이 하나**"

### Write-Skew 문제(그림.7-8 닥터 온콜)

- Lost-Update 의 **일반화**
  - Lost-Update ~ 두 트랜잭션이 “동일" 객체 다룰 때 발생 가능
  - Write-Skew ~ 두 트랜잭션이 **“여러" 객체 다룰 때** 발생 가능
- Skew (timing-anomaly) ~ read(**질의**) - modify - write(**커밋**) : 질의~커밋 사이(timing)에 다른 트랜잭션에 의한 변경이 발생
- 해결 전략 ~ Lost-Update 보다 어렵다
  - “여러 객체” ~ 단일 객체에 대한 원자적 연산은 도움이 되지 않음
  - Lost-Update 자동감지도 도움이 되지 않음 ⇒ 진짜 “직렬성 격리” 필요
  - “여러 객체”에 대한 제약 조건 설정 ⇒ 트리거, materialized(구체화) 뷰
  - SELECT ~ FOR UPDATE (lock 사용)
- Write-Skew 사례
  - 닥터 온콜 대기 ⇒ 두 명이 “온콜 취소"를 동시 **업데이트** ⇒ 온콜 룰 위반 (1명 이상 대기 X)
  - 회의실 예약 ⇒ 동일 시간에 “회의실 예약" 동시 **삽입** ⇒ 중복 예약
  - 멀티플레이어 게임 ⇒ 동일 위치에 “물건"의 동시 **삽입** ⇒ 게임 오류 ~ 위치 당 물건 1개 위반
  - “아이디” 획득 ⇒ 동일한 이름으로 “아이디"의 동시 **삽입** ⇒ 중복 아이디 (unique 위반)
  - 이중 지불 방지 ⇒ “지불항목"의 동시 **삽입** ⇒ 잔고 오류 (budget or points 초과)
  - 나머지 4개 사례와 닥터 온콜 사례의 차이: “락" 잡을 데이터가 없음. 삽입(Insert) 상황에서의 경쟁임
- Phantoms
  - 질의 ⇒ 판단(CAS) ⇒ “**Phantom**” 커밋 후에 “질의" 결과에 영향 ⇒ Write-Skew 유발  
    ![https://lh5.googleusercontent.com/pc4A0V00Xq4EfaGaau98YZKtUwx4BtlXlnAPReCCDIMJtwKT-9V6OkY0ydRVSJDUvRgcmk43fHGTDduxmSyO6AHE62XQBBzG5Dy__GnR6K0KT7KcZLC6-3QqaaBrdvCo0-wulP8br13VZ-rKsJYkn_92X19gLI-i1PA8gbPM7XslnR2psz2kXnc7v0hefA](https://lh5.googleusercontent.com/pc4A0V00Xq4EfaGaau98YZKtUwx4BtlXlnAPReCCDIMJtwKT-9V6OkY0ydRVSJDUvRgcmk43fHGTDduxmSyO6AHE62XQBBzG5Dy__GnR6K0KT7KcZLC6-3QqaaBrdvCo0-wulP8br13VZ-rKsJYkn_92X19gLI-i1PA8gbPM7XslnR2psz2kXnc7v0hefA)

  - Materializing conflicts
    - 닥터 온콜 취소 ⇒ “Lock”, SELECT~FOR UPDATE
    - 그런데, “Lock 대상”이 없는 경우는? (Lock을 못잡아) ⇒ Materializing conflicts
    - “Lock 전용 테이블” 생성 (저장용이 아님 ⇒ Lock용)
    - “최후의 수단” ~ *Materializing conflicts* 는 되도록 쓰지마라
      - 어렵다, 오류잘남, 보기안좋다 ⇒ 차라리 직렬성 격리 (Strong Isolation) 써라

### 요약

dirty-read/write 문제 **⇒  해법 Read-Committed** → read skew 문제 ⇒ **해법** **Snapshot**  → lost update 문제 (“동일 객체” 트랜잭션) ⇒  해법 DB 원자적 쓰기 제공, 앱 단에서 락(SELECT~FOR UPDATE 사용 등) or  CAS를 이용한 abort/retry 해법 → (“여러 객체” 트랜잭션) phantom으로 인한 write skew 문제 → “읽기" 락, materializing-conflict ⇒ “**직렬성**" (강렼~)

### 직렬성

- 직렬 ⇐⇒ 동시성 (병렬)
- 동시적(병렬)으로 실행하더라도 “직렬로 실행한 결과와 같음"을 보장 ⇒ 병렬 실행 상황에서 모든 race condition을 차단할 수 있음
- 성능, 확장성 측면에서 손해 감수해야 …

### (Actual) Serial Execution

- 진짜로 직렬로 실행

### 2 Phase Lock

- Lock이 두개? “NoNoNo”
- 2 **Phase** ~ (lock의) “획득"과 “해제”
- 넘나.. 당연한 거 아닌가 ??? (잠그면 해제해야지.. 원래 락이 그렇자나)
- shared lock 과 exclusive lock
- 읽으려면 **shared lock** 필요. 객체에 e~lock이 잡혀있으면 락이 해제될 때 까지 기다려야함
  - Q) s~lock은 안기다려도 됨? Y. s~lock 끼리는 안기다림.
- 쓰려면 **exclusive lock** 필요. 객체에 s~lock or e~lock이 잡혀있으면 락이 해제될 때 까지 기다려야함
- 교착상태 ~ 트랜잭션 서로가 서로의 락 해제를 기다리는 상황. 교착상태를 DB가 잘 감지해서 둘 중 하나를 어보트 해준다
- **predicate lock** : 조건에 해당하는 검색결과셋에 락을 잡음. 쓰기스큐, 팬텀도 방지할 수 있어 **모든 경쟁조건을 막을 수 있음**. 직렬성 확보. 정교하나 **오버헤드 큼** ⇒ 조건 바운더리에 해당하는 객체들 (조건검색의 부분집합)에 락이 잡혀 있으면 기다려야 함
- **range lock** : 대표적으로 index range lockpredicate lock만큼 정교하진 않지만 좀 더 제너럴하게 (범위 등) 정의하고 오버헤드를 낮추는 방법. 회의실 룸번호, 예약시간 등 인덱스를 정의하고 읽기나 쓰기 시 **인덱스에 락**을 잡는 방법. 다른 트랜잭션에서 접근 시 인덱스 락을 감지하고 기다리게 됨 (Index range lock) . 그 외 Table lock 도 있음
- 2PL 성능 ~ 최악

직렬성 얻는 대신 **“동시성” 포기** (이게 성능 하락의 가장 큰 요인)

읽기 락, range lock 이 존재하니 오버헤드 큼.70년대 이전에는 사용자 입력을 대기하는 케이스도 트랜잭션 범위에서 고려하다 보니 트랜잭션에 시간 제한도 없었음. ⇒ 쓰루풋 예측 안됨

### SSI (Optimistic Concurrency Control)

- Serializable Snapshot Isolation
- “성능"과 “신뢰" 두 마리 토끼를 잡고 싶다
- 닥터 온콜 예시) alice와 bob의 경쟁
- 경쟁? **누가 먼저 커밋**하냐
- 커밋 때 판단
  - 뭘 판단? 어보트 여부
- 왜 커밋 때 판단?
  - 읽기전용은 어보트 불필요
  - 누가 먼저 커밋될지 모름 (비결정적)
- Retry 가 빈번하면? 시스템 부담
  - “업데이트"가 잦은 시스템에 불리 ~ 기껏 다 처리 했는데 retry 해야 함 (아까비…)
  - “읽기” 위주의 시스템에 유리