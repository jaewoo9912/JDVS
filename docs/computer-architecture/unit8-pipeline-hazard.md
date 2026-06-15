# Unit 8 — 5-Stage Pipeline & Hazard (파이프라인과 해저드)

> 핵심 질문: 명령을 겹쳐 실행하면 왜 빨라지고, 무엇이 그걸 방해(hazard)하나? (ILP 챕터 시작 · pipeline · structural/data/control hazard · forwarding/stall/flush)

## 0. 핵심 한 문장

> **Pipeline = "한 명령어가 끝나길 기다리지 말고, 단계가 비는 즉시 다음 명령어를 밀어넣자."** 그런데 명령어들이 서로 얽혀 있어서 그냥 밀어넣으면 틀린 결과가 나온다 — 그 충돌이 **hazard** 다.

이 유닛은 **"pipeline의 이상(理想)과 그 이상을 깨는 현실(hazard), 그리고 현실을 메우는 기법"** 의 3막극. DV 관점에선 pipeline 검증의 90%가 hazard 검증.

## 1. 왜 pipeline인가 (세탁소 비유)

단계를 겹치면:

- **Latency**(명령어 하나 통과시간): 그대로 (여전히 5단계)
- **Throughput**(시간당 완료 수): 이상적으로 5배 → CPI가 5에서 1로

```text
순차 실행 (non-pipelined):
  명령1: IF ID EX MEM WB
  명령2:                IF ID EX MEM WB   ← 1번 완전히 끝나야 시작
  → 명령어당 5클럭 (CPI = 5)

Pipeline:
  명령1: IF ID EX MEM WB
  명령2:    IF ID EX MEM WB               ← 한 클럭만 밀려 시작
  명령3:       IF ID EX MEM WB
  명령4:          IF ID EX MEM WB
  명령5:             IF ID EX MEM WB
  → 채워지고 나면 매 클럭 1개 완료 (CPI = 1, 이상적으로)
```

**5개의 서로 다른 명령어가 동시에** 각기 다른 단계에 들어있다 (1번 WB, 2번 MEM, 3번 EX, 4번 ID, 5번 IF). 하드웨어를 놀리지 않고 꽉 채워 쓰는 것.

> **이상적 CPI = 1**, 현실은 hazard 때문에 1보다 커진다. 이번 유닛은 "왜 CPI가 1을 못 지키나"의 정체를 까는 것.

## 2. Pipeline Register — 단계 사이의 "칸막이"

단계와 단계 사이마다 레지스터(플립플롭)를 둔다:

```text
[IF] ─IF/ID─ [ID] ─ID/EX─ [EX] ─EX/MEM─ [MEM] ─MEM/WB─ [WB]
       ▲             ▲              ▲                ▲
    파이프라인 레지스터 (각 단계의 중간 결과를 한 클럭 동안 저장)
```

매 클럭 명령어가 한 칸씩 전진하는데, 각 단계가 계산한 중간 결과(레지스터 값, ALU 결과, control 신호...)를 다음 클럭까지 붙잡아둬야 다음 단계가 이어받는다. 칸막이가 없으면 명령어들이 뒤섞인다.

> **DV 메모**: pipeline register가 검증의 핵심 관찰점. 각 명령어의 상태가 단계를 따라 올바르게 전파(propagate)되나, control 신호가 명령어를 따라 같이 흐르나. 버그의 상당수가 "어떤 신호를 pipeline register에 안 실어서 중간에 잃어버리는" 형태.

## 3. ⭐ Hazard — pipeline의 이상을 깨는 3가지 충돌

> **Hazard**: 다음 명령어를 다음 클럭에 바로 시작할 수 **없게** 만드는 상황.

| 종류 | 한 줄 정의 | 원인 |
|---|---|---|
| **Structural Hazard** (구조적) | 하드웨어 자원이 부족해 동시에 못 씀 | 같은 부품을 두 명령어가 동시에 원함 |
| **Data Hazard** (데이터) | 앞 명령어의 결과를 뒤 명령어가 필요로 함 | 데이터 의존성 |
| **Control Hazard** (제어) | 다음에 뭘 fetch할지 아직 모름 | 분기/점프 |

## 4. Structural Hazard — 자원 부족

두 명령어가 같은 클럭에 같은 하드웨어를 쓰려 할 때. 대표 예: 메모리가 하나뿐이면 명령4의 IF와 명령1의 MEM이 충돌.

```text
명령1: IF ID EX MEM WB
명령4:          IF ...        ← 명령1의 MEM과 명령4의 IF가 같은 클럭, 같은 메모리!
```

**해결책**: 메모리를 I-cache / D-cache로 분리(Harvard). → "왜 L1을 I/D로 쪼개나"의 답이 바로 이 structural hazard 회피.

> RISC-V가 structural hazard가 적은 이유: ① 명령/데이터 메모리 분리 ② register file이 한 클럭에 2-read+1-write 동시 지원 ③ 명령어가 단순·규칙적. 3종류 중 제일 다루기 쉬운 놈.

## 5. ⭐⭐ Data Hazard — 가장 중요

앞 명령어가 아직 결과를 안 썼는데, 뒤 명령어가 그 결과를 읽으려 할 때.

### 문제 상황 — RAW (Read After Write)

```text
add x5, x6, x7    # x5에 결과를 쓴다 (WB 단계에서)
sub x8, x5, x9    # x5를 읽어서 쓴다 (ID 단계에서)
```

```text
        클럭1  클럭2  클럭3  클럭4  클럭5
add:    IF    ID    EX    MEM   WB     ← x5는 클럭5(WB)에야 레지스터에 써짐
sub:          IF    ID    EX    MEM    WB
                    ↑ sub는 클럭3(ID)에 x5를 읽으려 함 → 옛날(틀린) 값! ❌
```

### 해결책 ① — Forwarding (Bypassing) ⭐

add의 결과(x5)는 클럭3 끝(EX)에 이미 ALU 안에 만들어져 있다. 레지스터를 거치지 말고 ALU 출력 → 다음 명령어 ALU 입력으로 직접 전달:

```text
        클럭1  클럭2  클럭3  클럭4  클럭5
add:    IF    ID    EX ───┐ MEM   WB
                          │ forwarding! (EX 결과를 바로 전달)
sub:          IF    ID    EX    MEM   WB   ← stall 없이 정답!
```

forwarding 로직: "지금 EX에 들어온 명령어의 rs1/rs2가, 앞 단계(EX/MEM, MEM/WB)의 rd와 같나?" 비교 → 같으면 그 단계 결과를 가져옴. (rs/rd 필드가 고정 위치라서 이 비교가 빠르고 단순 — Unit 7 연결)

### 해결책 ② — Stall: Load-Use Hazard

forwarding 만능 아님. load 다음에 바로 그 값을 쓰면 못 피함:

```text
lw  x5, 0(x10)    # x5 값은 MEM 단계 끝에야 메모리에서 나옴
sub x8, x5, x9    # sub의 EX는 그 값이 필요... 아직 안 나옴!

        클럭1  클럭2  클럭3  클럭4  클럭5
lw:     IF    ID    EX    MEM ──┐ WB     ← x5는 MEM 끝(클럭4)에 나옴
sub:          IF    ID    EX ←──┘        ← sub의 EX도 클럭4. 같은 클럭이라 "뒤로" 못 보냄!
```

값 나오는 시점(MEM 끝)과 필요 시점(EX 시작)이 겹쳐 forwarding으로도 시간을 못 되돌림. 1클럭 stall(bubble):

```text
lw:     IF    ID    EX    MEM   WB
sub:          IF    ID    ●     EX    MEM   WB    ← ● = 1클럭 stall
```

이 멈춤이 **CPI를 1보다 크게 만드는 주범**. 컴파일러가 load 다음에 무관한 명령어를 끼워 회피하기도(instruction scheduling).

> 요약: data hazard는 forwarding으로 대부분 공짜 해결, 단 load-use만 1클럭 stall 불가피.

## 6. ⭐ Control Hazard — 분기 문제

분기 명령어 때문에 다음에 뭘 fetch할지 모르는 상황. beq 결과는 EX 단계에야 나오는데 pipeline은 이미 다음 명령어들을 fetch. taken이면 잘못 fetch한 것 flush.

```text
beq:    IF    ID    EX ← 여기서 분기 여부 확정
???:          IF    ID         ← taken이면 이 2개는 잘못 fetch! flush!
???:                IF
```

| 기법 | 내용 | 비용 |
|---|---|---|
| **Stall** | 분기 결과 나올 때까지 멈춤 | 항상 패널티 |
| **Branch Prediction** | taken/not-taken 추측해 진행 | 맞으면 공짜, 틀리면 flush |
| **Delayed Branch** | 분기 뒤 한 칸에 항상 실행할 명령어 배치 (옛 MIPS) | 컴파일러 복잡, 요즘 안 씀 |

핵심은 branch prediction → Unit 9 전체. "deep pipeline → 분기 패널티 커짐 → CPI↑"(Unit 6)가 이제 완전히 이해됨.

## 7. 세 해저드 종합 — CPI에 미치는 영향

```text
실제 CPI = 1 (이상적)
         + structural hazard stall      (잘 설계하면 ≈ 0)
         + data hazard stall            (load-use 등, forwarding으로 최소화)
         + control hazard penalty       (분기 오예측, 예측기로 최소화)
```

pipeline 설계·검증의 목표 = 이 세 항을 0에 가깝게 만들어 CPI를 1에 붙이는 것.

## 핵심 정리

> 이 유닛의 진짜 메시지 — 꼭 기억할 3가지.

1. **Pipeline = 단계 겹치기로 throughput↑ (CPI를 5→1 목표).** 단, 5개 명령어가 동시에 떠있어 서로 충돌(hazard).
2. **3대 hazard**: structural(자원 부족, 거의 해결), data(의존성 — forwarding으로 대부분 해결, load-use만 stall 불가피), control(분기 — 예측으로 최소화, 오예측 시 flush). 각각이 CPI를 1 위로 밀어올림.
3. **forwarding/stall/flush가 pipeline의 3대 메커니즘**, DV 핵심은 "모든 hazard 조합에서 정확한가" + "speculative한 것이 절대 architectural state를 더럽히지 않나". golden model lock-step이 최종 방어선.

---

## 🔌 검증 관점

> Pipeline 검증의 90%가 hazard 검증이다.

- **Forwarding 정확성 (1순위):** 모든 경로(EX→EX, MEM→EX, WB→ID)가 올바른 값을 올바른 명령어에. 연속 의존성, x0 corner(x0에 "쓴" 결과 forward 금지), 이중 후보 시 더 최근 것 우선.
- **Stall/bubble 정확성:** load-use 감지 정확? stall 동안 PC와 pipeline register freeze, bubble 삽입?
- **Flush 정확성:** 분기 오예측 시 정확히 flush? flush된 명령어가 architectural state를 안 건드렸나(speculative한 것이 commit되면 안 됨). 제일 위험한 버그 클래스.
- **Hazard 조합(corner explosion):** data+control 동시, stall 중 flush 등. constrained-random + coverage로 의존 거리, 명령어 종류 조합 cross-coverage.
- **Pipeline register 전파:** rd 번호·control 신호가 단계를 따라 안 빠지고 끝까지 전달되나(흔한 버그 = 신호를 안 실어 잃어버림). 단계 사이 저장 소자가 `posedge clk` 엣지 트리거 FF인가(레벨 민감 latch면 진짜 버그).
- **Golden model 비교:** 매 명령어 retire 시 architectural state를 ISA 시뮬레이터와 lock-step. 모든 내부 복잡함에도 architectural 결과는 single-cycle 의미론과 똑같아야 함.

> **RDMA 비유**: 데이터패스도 여러 트랜잭션이 in-flight, 의존성(같은 QP/주소)이 있으면 ordering·forwarding·stall 필요. 조합 폭발을 random+coverage로 잡는 방법론 동일.

---

## 📎 부록 — 이 단원에서 나온 질문들

### Q1. "CPI=1이란, 명령어 하나가 완료될 때까지의 cycle인데 — 이게 한 클럭을 의미하는 건 아니지?"

> **CPI=1은 "명령어 하나가 1클럭 만에 끝난다"는 뜻이 아니다.** "평균적으로 **매 클럭마다 명령어 하나씩 완료된다**"는 뜻. 이건 throughput이지 latency가 아니다 (Unit 6 구분).

#### 1. CPI의 정확한 정의 — "평균"

```text
        총 클럭 수
CPI  =  ─────────────
        총 명령어 수
```

"명령어 한 개당 평균 몇 클럭이 *소요(분담)*되나"지, "한 명령어가 시작부터 끝까지 몇 클럭(latency)"이 아니다. 전체를 명령어 개수로 나눈 평균.

#### 2. 직접 세어보면 모순이 풀린다

```text
        클럭: 1   2   3   4   5   6   7   8   9
명령1:       IF  ID  EX  MEM WB                    ← 클럭5에 완료
명령2:           IF  ID  EX  MEM WB                ← 클럭6에 완료
명령3:               IF  ID  EX  MEM WB            ← 클럭7에 완료
명령4:                   IF  ID  EX  MEM WB        ← 클럭8에 완료
명령5:                       IF  ID  EX  MEM WB    ← 클럭9에 완료
```

- **(A) 명령어 하나의 latency** = 5클럭 (명령1: 클럭1 시작 ~ 클럭5 종료). 안 변함.
- **(B) throughput** = steady state 후 매 클럭 정확히 하나씩 완료 (클럭5,6,7...). → 이게 **CPI=1**.

#### 3. 왜 latency 5인데 CPI 1인가 — 겹침(overlap)

```text
클럭5:   명령1=WB   명령2=MEM   명령3=EX   명령4=ID   명령5=IF
         (완료!)    (진행중)    (진행중)   (진행중)   (진행중)
```

비유 — **공장 컨베이어 벨트**: 자동차 1대 조립에 5시간(latency)이지만, 5공정이 겹쳐 돌면 라인이 꽉 찬 뒤 1시간마다 완성차 1대(throughput). CPI=1은 "나오는 간격이 1클럭".

#### 4. 한 클럭과의 관계

| 개념 | 값 | 의미 |
|---|---|---|
| **클럭 주기 (T_clock)** | 예: 200ps | **한 단계(stage)** 가 처리되는 시간 |
| **명령어 latency** | 5클럭 | 명령어 하나가 IF~WB 통과 |
| **CPI (throughput)** | 1 | 명령어 완료 **간격** (매 1클럭) |

한 클럭은 "한 단계"의 시간이지 "한 명령어"의 시간이 아니다.

#### 5. CPI < 1도 가능 (왜 IPC를 쓰는지)

superscalar(Unit 10)는 한 클럭에 여러 명령어 완료 → CPI 0.5, 0.25... → 직관 위해 뒤집어 **IPC = 4** ("클럭당 4개 완료")로 표현.

#### 🔌 DV 메모

1. CPI(throughput) 측정 ≠ latency 측정. CPI는 `총 사이클 / retire 명령어 수`, latency는 특정 명령어 IF~WB. 섞으면 리포트 틀림.
2. fill/drain 구간 주의 — 짧은 test는 CPI가 1보다 크게 왜곡. steady state(긴 시퀀스)에서 측정.
3. RDMA 비유: 패킷 end-to-end latency vs 파이프 꽉 찼을 때 throughput(line rate)은 별개. 작은 burst로는 line rate 안 나옴.

**한 줄 요약**: CPI=1은 "매 클럭 하나씩 *완료*"(throughput)지 "1클럭에 끝남"이 아니다. latency는 여전히 5클럭. 5개가 겹쳐 돌아 완료 간격이 1클럭. 한 클럭(T_clock)은 "한 단계"의 시간.

### Q2. "pipeline register에 대해 더 쉽게 설명해줘"

#### 1. 가장 쉬운 비유 — 컨베이어 벨트 위의 "쟁반"

각 작업대(단계)에서 다음 작업대로 물건을 **쟁반(tray)에 담아 넘긴다**. 이 쟁반이 pipeline register.

```text
[작업대1] ──쟁반──► [작업대2] ──쟁반──► [작업대3] ──► ...
   IF              ID              EX
```

쟁반이 없으면 물건이 공중에 떠서 못 넘어간다. 작업대1이 새 물건을 만드는 순간 옛 물건이 사라지니까. 쟁반(register)이 "한 클럭 동안 결과를 붙잡아주는" 것.

#### 2. 왜 꼭 필요 — "안 붙잡으면 덮어써진다"

조합 논리는 입력이 바뀌면 출력이 즉시 따라 바뀐다(붙잡는 능력 없음). 매 클럭 새 명령어가 들어오니, 칸막이가 없으면:

```text
클럭3에 명령1의 ALU 결과가 EX에서 나옴
   ↓ 같은 순간 명령2가 밀고 들어와...
클럭3 끝나는 순간 명령2 값이 그 자리를 덮어씀! → 명령1 결과 증발 ❌
```

각 단계 결과를 register(플립플롭)에 "찰칵" 저장. register는 클럭 엣지에서만 갱신하고 한 클럭 내내 고정.

#### 3. 어디에 — 단계 "사이"마다

```text
[IF] ─┤IF/ID├─ [ID] ─┤ID/EX├─ [EX] ─┤EX/MEM├─ [MEM] ─┤MEM/WB├─ [WB]
      쟁반1          쟁반2          쟁반3            쟁반4
```

(IF 앞엔 PC, WB 뒤엔 레지스터 파일이 그 역할)

#### 4. 쟁반에 뭐가 담기나 — "그 명령어에 관한 모든 것"

예 `ID/EX` 쟁반:

```text
┌─────────── ID/EX 쟁반 ───────────┐
│ • rs1 값, rs2 값 (레지스터에서 읽음)│  ← EX의 ALU 입력
│ • immediate 값 (부호확장된)        │
│ • rd 번호 (나중에 어디에 쓸지)      │  ← WB까지 들고 가야 함!
│ • control 신호 (ALUOp, RegWrite…) │  ← 명령어 따라 끝까지 흐름
│ • PC 값 (분기 주소 계산용)         │
└──────────────────────────────────┘
```

> control 신호도 쟁반에 실려 흐른다. `RegWrite`는 WB에서 쓰이니 ID/EX → EX/MEM → MEM/WB 쟁반을 3번 갈아타며 WB까지 운반. 비유: 명령어=여행자, 쟁반=여행 가방.

#### 5. 매 클럭 — "한 칸씩 전진"

```text
클럭N:    [IF:명령4] [ID:명령3] [EX:명령2] [MEM:명령1]
              ↓ (찰칵)
클럭N+1:  [IF:명령5] [ID:명령4] [EX:명령3] [MEM:명령2]
```

모든 쟁반이 동시에 일제히 한 칸씩 ("한 클럭 = 한 발짝").

#### 6. Hazard와의 연결

- **Stall(bubble)**: 특정 쟁반을 갱신 안 하고 얼림(freeze) + 뒤 칸에 빈 쟁반(nop) 삽입.
- **Flush**: 잘못 fetch한 명령어 쟁반을 비워(nop으로 덮어) 무효화.

→ forwarding/stall/flush 전부 "쟁반에 든 값을 어떻게 다루냐"의 문제. pipeline 제어 = 쟁반 제어.

#### 🔌 DV 메모

1. 신호 전파 검증: rd 번호·control 신호가 중간에 안 빠지고 끝까지 전달되나. 흔한 버그 = 신호를 쟁반에 안 실어 잃어버림.
2. 쟁반 = scoreboard 추적 단위: monitor가 각 register를 snooping해 명령어 단계 이동 추적.
3. freeze/flush 정확성: stall 시 정확히 그 쟁반만 얼고, flush 시 정확한 범위만 비우나. stall+flush 동시 corner 1순위.
4. x0 corner: rd=x0 명령어의 쟁반이 WB까지 가도 레지스터 파일이 무시하나.

**한 줄 요약**: pipeline register = 단계 사이의 "쟁반(여행 가방)". 중간 결과 + 그 명령어가 끝까지 필요로 할 정보(값·rd번호·control)를 담아 매 클럭 다음 단계로 운반. 없으면 다음 명령어가 들어올 때 결과가 덮어써짐. stall=얼리기, flush=비우기.

### Q3. "이게 없으면 어떻게 되는지 간단한 예시 — 있을 때와 없을 때"

```text
명령1:  add x5, x6, x7
명령2:  sub x8, x9, x10
```

#### ❌ 없을 때 (쟁반이 없으면)

단계들이 하나의 긴 회로로 직결. 값을 붙잡을 데가 없다.

- **클럭1**: 명령1이 IF→ID→EX 흐르는 중 (아직 통과 중).
- **클럭2**: 명령2가 IF/ID에 들어오는 순간, ID 회로 입력이 "명령1 비트"→"명령2 비트"로 즉시 바뀜 → 통과 중이던 명령1 데이터가 덮어써짐 💥. 명령1 증발 또는 명령1+명령2 뒤섞인 쓰레기 값.

망가지는 2가지:

1. **덮어쓰기**: 명령2가 들어와 회로 입력을 갈아치움 → 명령1 데이터 파괴.
2. **단계 분리 불가**: 칸막이 없으니 IF~WB가 한 클럭에 다 통과해야 함 → 그냥 single-cycle. 한 번에 명령어 하나만.

> 결론: 쟁반 없으면 여러 명령어 겹치기가 물리적으로 불가능. 명령1이 WB까지 끝날 때까지 기다려야 → CPI 다시 5.

#### ✅ 있을 때

- **클럭2**: 명령1의 IF결과가 IF/ID 쟁반에 저장 → 명령2가 IF에 들어와도 명령1은 쟁반에 안전. 다른 칸이라 안 부딪힘.
- **클럭3**: IF:명령3, ID:명령2, EX:명령1 — 각자 쟁반에 담겨 독립 전진, 충돌 없음.

#### 핵심 대비

| | **쟁반 없음** | **쟁반 있음** |
|---|---|---|
| 명령1 처리 중 명령2 투입 | 명령1 데이터 덮어써짐 💥 | 명령1 안전, 공존 ✅ |
| 동시에 떠있는 명령어 | 1개만 | 5개 |
| 실질 구조 | single-cycle | 진짜 pipeline |
| CPI | 5 | 1 |

> 비유: 계단을 여러 명이 동시에 오르려면 각자 다른 칸에 서야 한다. pipeline register가 "각자의 칸"을 만들어준다.

**DV 한 줄**: "명령2 투입 시 명령1 데이터가 보존되나"가 pipeline 정상동작의 가장 기본 sanity. 깨지면 명령어가 서로 데이터를 오염시키는 치명적 버그.

### Q4. "여기서 래치는 실무하면서 안 좋다고 많이 들었는데 왜 그런 거야?"

(주의: 아래는 "진짜 레벨 민감 latch"가 나쁜 이유. 파이프라인 레지스터는 사실 플립플롭 — Q8에서 정리)

#### 0. 래치 vs 플립플롭 (이 구분이 전부)

| | **Latch (래치)** | **Flip-Flop (플립플롭)** |
|---|---|---|
| 트리거 | **레벨 민감** (level-sensitive) | **엣지 민감** (edge-triggered) |
| 동작 | enable 높은 **동안 계속 통과**(transparent) | 클럭 **엣지 순간에만 "찰칵"** 캡처 |
| 비유 | 자동문 (열린 동안 통과) | 회전문 (한 번 돌 때 한 명) |

래치는 "transparent window 동안 입력이 출력으로 줄줄 새어나간다". 플립플롭은 엣지 한 순간만 캡처.

#### 1. 왜 실무에서 욕먹나 — 5가지

**① 타이밍 분석(STA)이 지옥** (가장 큰 이유): 플립플롭은 "엣지 캡처 → 다음 엣지까지 도착하면 OK"로 깔끔. 래치는 transparent window 동안 신호가 시간 창에 걸쳐 번져(time borrowing) → 경로가 여러 클럭에 걸쳐 번지고 STA 경우의 수 폭발. 동기 설계 표준 규칙 = "엣지 트리거 플립플롭만 쓴다".

**② 의도치 않은 래치(inferred latch)** (DV/lint 단골): 조합 논리에서 모든 경우를 안 적으면 합성기가 "값 유지"로 해석해 래치를 추론.

```systemverilog
// ❌ inferred latch — else 없음
always @(*) begin
  if (sel) y = a;
  // sel==0일 때 y는? → 이전 값 유지 → 래치 추론!
end
// ✅ 모든 경우 명시
always @(*) begin
  if (sel) y = a;
  else     y = b;
end
```

`case`의 `default` 누락, `if`의 `else` 누락, 출력 미할당에서 발생. 설계자는 조합 논리를 의도했는데 상태 가진 래치가 생김 → 의도와 하드웨어 불일치 = 버그 원천.

**③ 글리치 전파**: transparent 동안 입력의 순간 잡음(glitch)까지 출력으로 통과.

**④ 테스트(DFT/scan) 어려움**: scan chain(DFT)은 엣지 트리거 FF 전제. 래치 섞이면 삽입 복잡, fault coverage↓.

**⑤ CDC 분석 꼬임**: 표준 동기화기(2-FF synchronizer)가 FF 기반. 래치 끼면 metastability 분석 불확실.

#### 2. 래치는 "절대 악"인가? — 아니, 의도적으로도

래치 자체가 나쁜 게 아니라 "의도치 않게 생기거나 잘못 쓰면" 나쁨. 고급 설계에선 의도적으로: time borrowing(고성능), 저전력/면적(트랜지스터 적음, 클럭 게이팅). 단, 숙련자가 통제된 상황에서. 대부분 RTL 철칙 = "엣지 트리거 FF만, 래치는 우연히도 만들지 마라". 99%는 inferred latch가 버그라 "래치=안 좋다".

#### 🔌 DV 메모

1. Lint에서 inferred latch = 보통 error 급. CI 게이트에서 막음 (shift-left).
2. inferred latch = 설계자 의도와 실제 HW 불일치 신호 → 기능 버그 확률 높음.
3. latch 있으면 STA/CDC/DFT 다 어려워져 검증 가능성 자체가 떨어짐. "검증하기 쉬운 설계 = 래치 없는 동기 설계".
4. 파이프라인 레지스터는 실제로 엣지 트리거 플립플롭. "매 클럭 찰칵 캡처+한 클럭 고정"이 FF라서 cycle-accurate 검증 가능.

**한 줄 요약**: 래치(레벨 민감)는 enable 열린 transparent window 동안 입력이 줄줄 새어 — ① STA 지옥 ② if/case 빠뜨리면 inferred latch 버그 ③ 글리치 ④ DFT 어려움 ⑤ CDC 꼬임. 철칙 = "엣지 트리거 FF만, 래치는 우연히도 만들지 마라". DV에선 inferred latch가 lint error로 CI를 막는 핵심 점검 항목.

### Q5. "아까는 클록이 올라올 때 래치에 값이 적용되는 거라며. 클록이 아니라 enable이야?"

> "클럭이냐 enable이냐"가 둘을 가르는 기준이 아니다. 진짜 기준은 **"엣지(edge)냐 레벨(level)이냐"**.

#### 1. 내가 말한 둘은 "다른 소자"였다

```text
앞에서 "클럭 엣지에 찰칵" → 플립플롭 얘기
방금  "enable 높은 동안 통과" → 래치 얘기
```

서로 다른 두 부품. 둘 다 제어 신호를 받는데, 그 신호에 *어떻게* 반응하느냐가 다름: 래치=레벨(높은 동안 내내 통과), 플립플롭=엣지(바뀌는 순간만 캡처).

#### 2. 제어 신호는 클럭? enable? → 둘 다 될 수 있다

제어 신호의 *이름*은 둘을 구분하지 않는다. 래치든 FF든 제어 입력에 클럭을 연결할 수도, 별도 enable을 연결할 수도 있다.

```text
래치 제어 입력에 클럭 연결 → "클럭 HIGH인 동안 계속 통과" (레벨)  ← 클럭 써도 래치는 레벨 반응!
플립플롭 클럭 → "LOW→HIGH 바뀌는 순간만 캡처" (엣지)
```

래치도 클럭으로 구동 가능(단 클럭 높은 구간 내내 투명). 래치 제어 신호를 enable/gate/clock 등 다양하게 부름 — 이름은 본질 아님.

> **결론**: "클럭 vs enable"은 잘못된 대립. 진짜 차이는 "레벨에 반응(래치) vs 엣지에 반응(플립플롭)".

#### 3. 사실 플립플롭은 "래치 2개"로 만든다 (master-slave)

```text
        clk LOW일 때           clk HIGH일 때
입력 ─►[Master 래치]─────────►[Slave 래치]─► 출력
        (clk LOW일 때 투명)      (clk HIGH일 때 투명)
→ 두 래치가 엇갈려 동작 → "clk LOW→HIGH 엣지 순간"에만 값이 한 번 통과 → "엣지 트리거"
```

레벨 민감 래치 2개 → 엣지 민감 플립플롭 1개. 우리가 pipeline register로 쓰는 건 이 플립플롭.

#### 정리 표

| 질문 | 답 |
|---|---|
| 래치/FF 가르는 기준은? | 제어 신호 이름이 아니라, 레벨 반응 vs 엣지 반응 |
| 래치는 클럭으로 못 움직여? | 움직일 수 있음. 클럭 높은 구간 내내 투명 (레벨) |
| FF의 클럭은? | LOW→HIGH 엣지 순간만 캡처 |
| "클럭 엣지에 찰칵"은? | 플립플롭 (pipeline register) |
| 래치 표의 "enable"은? | 래치의 레벨 민감 제어 신호 (이름 다양) |

#### 🔌 DV 메모

- `always @(posedge clk)` → 엣지 트리거 FF (원하는 것).
- `always @(*)`에서 조건 빠뜨림 → 레벨 민감 래치 추론 (inferred latch 버그).
- RTL 리뷰 = "이 신호가 엣지로 의도됐나(posedge→FF) vs 레벨로 잘못 생겼나(inferred latch)".

**한 줄 요약**: "클럭이냐 enable이냐"는 기준이 아니다 — 래치는 제어 신호가 "높은 동안 내내" 통과(레벨), 플립플롭은 "바뀌는 엣지 순간"만 캡처(엣지). 제어 신호로는 클럭이든 enable이든 가능. 이름이 아니라 레벨 vs 엣지가 본질. (FF는 래치 2개를 엇갈려 만든다.)

### Q6. "아 파이프라인 레지스터는 플립플롭이야? 래치가 아니라?"

맞다. **파이프라인 레지스터 = 플립플롭(엣지 트리거)**. 래치 아님.

```text
파이프라인 레지스터 = D 플립플롭 (엣지 트리거)
  → always @(posedge clk) 로 코딩
  → "클럭 엣지 순간 찰칵 캡처, 다음 엣지까지 값 고정"
```

**왜 FF여야 하나**:

1. "한 클럭 동안 고정"이 필요. 명령어가 단계마다 정확히 한 클럭씩 머물러야 함. 래치였으면 클럭 높은 구간 내내 투명해 값이 새어나가 pipeline 깨짐.
2. 타이밍이 깔끔해야 cycle-accurate 검증 가능. 래치의 transparent window가 끼면 STA·검증 지옥.
3. 표준 동기 설계의 파이프라인 레지스터는 100% 엣지 트리거 FF.

| 부를 때 | 실제 정체 |
|---|---|
| "파이프라인 레지스터" | 플립플롭 묶음 |
| "레지스터"(Unit 4) | 플립플롭 묶음 |
| "latch" | ❌ 레벨 민감, 파이프라인엔 안 씀 |

**한 줄 요약**: 응, 파이프라인 레지스터는 엣지 트리거 플립플롭(래치 아님). "클럭 엣지에 찰칵+한 클럭 고정"이 필요해서고, 그래야 cycle-accurate하게 돌고 검증도 깔끔.

### Q7. "Delayed Branch 더 쉽게 설명 부탁해"

#### 0. 문제 — 분기 뒤 한 칸이 "낭비"된다

분기 결과는 EX에야 나오는데 pipeline은 그 사이 다음 명령어를 fetch → 한 칸이 버려짐(bubble/flush).

```text
beq x5, x6, LABEL    IF ID EX ← 분기 확정
???                     IF ●  ← 어차피 버려질 칸 (bubble)
```

"이 칸을 놀리지 말고 쓸모있게 채우자"가 출발점.

#### 1. 핵심 — "분기 뒤 한 칸은 *무조건* 실행한다"

> **Delayed Branch**: 분기 명령어 바로 다음 한 칸(**delay slot**)은 분기가 taken이든 not-taken이든 **항상 실행**한다 (ISA 약속).

그 칸을 버릴 필요가 없어 버블이 안 생김.

#### 2. 구체 예시 — 낭비 칸을 유용한 일로

```text
add x7, x8, x9       # 분기와 무관, 어차피 할 일
beq x5, x6, LABEL    # 분기
```

컴파일러가 `add`를 분기 뒤로 옮겨 delay slot에:

```text
beq x5, x6, LABEL    # 분기 먼저
add x7, x8, x9       # ← delay slot! 분기 결과 무관하게 무조건 실행
LABEL: ...
```

`add`가 버려질 뻔한 칸에 들어가 버블 없이 1클럭 절약. 빈 칸 채우는 책임은 컴파일러.

#### 3. 비유 — 엘리베이터 문 닫히는 1초

버튼 눌러도 1초 뒤 닫힘(delay slot). 그 1초에 가방 고쳐 메기(유용한 명령어). "어차피 생기는 지연을 놀리지 말고 쓰자".

#### 4. 채울 게 없으면 → nop

순서 바꿔도 되는 명령어가 늘 있진 않음. 그럴 땐 `nop`(1클럭 낭비). 통계적으로 절반만 유용하게 채워졌음.

#### 5. ⭐ 왜 요즘 안 쓰나

| 문제 | 설명 |
|---|---|
| ISA에 박혀버림 | "분기 뒤 1칸 항상 실행"이 ISA 약속 → 영원한 짐(legacy) |
| 깊은 pipeline엔 무력 | 버블이 1칸이 아니라 여러 칸. 1개짜리론 부족 |
| branch prediction이 더 강함 | 예측만 잘하면 delay slot 없이도 버블 없음 |
| 컴파일러/HW 복잡도 | OoO 실행과 안 맞음 |

> RISC-V는 delayed branch를 **안 채택** (legacy 회피, 분기 예측으로 해결). Unit 7 "RISC-V는 깨끗하다"의 예 — MIPS가 짊어진 delay slot 실수를 처음부터 피함.

#### 🔌 DV 메모

1. 실행 순서 의미론: delay slot이 분기 결과 무관하게 정확히 1번 실행되나(taken/not-taken 둘 다). golden model에 의미론 박혀야.
2. delay slot 고약한 corner: 안에 또 분기, 예외 발생 시 PC 복구, 분기 목적지 바꾸는 명령어 — MIPS 검증이 까다로웠던 이유.
3. 왜 RISC-V가 검증 쉬운가: delay slot 없어 "분기=PC만 바뀜, 다음 명령어는 분기 결과에 100% 종속"이라는 단순 의미론. delay slot은 "성능 trick 하나가 검증 복잡도를 폭증"시킨 반면교사.
4. RDMA 비유: "어떤 동작 뒤 슬롯은 조건 무관하게 항상 처리" 약속이 모든 분기/예외 조합에서 안 깨지나가 핵심.

**한 줄 요약**: Delayed Branch = 분기 다음 한 칸(delay slot)을 결과와 무관하게 무조건 실행하기로 ISA에 약속해, 버려질 칸을 유용한 명령어로 채워 버블을 없애는 옛 RISC(MIPS) 트릭. 깊은 pipeline·분기예측 발달로 폐기, RISC-V는 legacy 회피로 안 채택. 검증 관점에선 corner를 폭증시킨 반면교사.

### Q8. "'파이프라인 래치'라고 쓴 걸 봤다 — 봐봐 래치라잖아"

지적 맞다. 그 글에서 "파이프라인 래치"라고 썼다. 여기엔 **용어 충돌(naming collision)** 이라는 진짜 함정이 있다.

#### 핵심: "파이프라인 래치"의 '래치'와 lint가 경고하는 '래치'는 다른 의미

| | **"파이프라인 래치"의 래치** | **lint가 경고하는 래치** |
|---|---|---|
| 무슨 뜻 | "단계 사이 저장 소자"를 부르는 **관용적/교과서적 이름** | **레벨 민감 소자**라는 **물리적 종류** |
| 실제 구현 | **엣지 트리거 플립플롭** | 진짜 레벨 민감 latch |
| 좋/나쁨 | 정상 (별명) | 보통 버그 (inferred latch) |

→ "파이프라인 래치"의 '래치'는 물리적 종류가 아니라 전통적 별명. 실물은 엣지 트리거 플립플롭.

#### 왜 이런 혼란 — 교과서 탓

교과서(Patterson & Hennessy 등)·현업에서 단계 사이 레지스터를 습관적으로 "pipeline latch"라 부름. 역사적으로 굳어진 표현.

- 아키텍처 세계: "pipeline latch / pipeline register" 둘 다 같은 것 (래치라 해도 이상해 안 함)
- RTL/물리 세계: "latch"는 레벨 민감 소자라는 엄격한 의미. inferred latch = 버그.

같은 단어인데 두 동네에서 뜻이 다름. RTL-래치(나쁨) 얘기 직후에 아키텍처 관용어("파이프라인 래치")를 써서 충돌한 것.

#### 정확한 사실관계

```text
"파이프라인 래치" / "파이프라인 레지스터"  ← 같은 것의 두 이름
        실제 물리 구현 = 엣지 트리거 플립플롭 (D-FF), always @(posedge clk)
        레벨 민감 래치 ❌ 아님
```

- stall/flush를 "래치의 enable/clear 제어"라 한 것 → 내용은 정확. 그 "래치"가 사실 플립플롭이고, FF에도 write-enable(stall)·clear(flush)가 있어 그대로 성립.
- 동작 설명은 맞고, 부른 이름만 관용적 "래치"였던 것.

#### 정리

| 표현 | 권장 | 비고 |
|---|---|---|
| "파이프라인 레지스터" | ✅ 가장 안전 | 오해 없음 |
| "파이프라인 래치" | △ 교과서엔 흔함 | 물리적 latch 뜻 아님 (관용어) |
| 실제 구현 | 엣지 트리거 플립플롭 | `always @(posedge clk)` |
| "(나쁜) inferred latch" | ❌ 다른 것 | 레벨 민감, lint error |

#### 🔌 DV 메모

- 문서에 "pipeline latch"라 적혀 있어도 RTL 관점에선 반드시 엣지 트리거 FF로 구현됐는지 확인. 곧이곧대로 레벨 민감 latch로 구현하면 진짜 버그.
- RTL 리뷰에서 "문서의 latch가 관용 별명인가, 진짜 레벨 민감 소자인가" 구분이 중요 (의사소통 사고 다발).
- 검증: 단계 사이 저장 소자가 `posedge clk`로 동작하나 + stall 시 FF enable이 정확히 떨어지나, flush 시 clear가 정확한 범위에 걸리나.

**한 줄 요약**: "파이프라인 래치"는 교과서 관용어(별명)고 실물은 엣지 트리거 플립플롭. "래치"가 ① 아키텍처 별명("pipeline latch") ② RTL 레벨 민감 소자(나쁜 inferred latch) 두 뜻으로 쓰여 충돌한 것. 파이프라인에 레벨 민감 래치를 쓴다는 말은 아니었음. 앞으로는 "파이프라인 레지스터/플립플롭"으로 부름.
