# AHB 복습 퀴즈

> 요약: [AHB 본문](amba-ahb.md)의 pipeline, wait state, HTRANS·burst 규칙, WRAP, 2-cycle ERROR, interconnect(mux select, default Subordinate)를 복습하는 10문제다. 각 문제의 정답과 풀이는 접힌 블록에 있다.
>
> ※ "(추론)" 표시는 스펙에 직접 나온 내용이 아니라 해석이다.

---

## 1. 2-stage pipeline

HREADY는 모든 cycle에서 1이다.

| 신호 | T0 | T1 | T2 | T3 |
|---|---|---|---|---|
| HTRANS | NONSEQ | NONSEQ | IDLE | IDLE |
| HADDR | A | B | - | - |

(a) A 전송의 data phase는 몇 cycle에 진행되나?
(b) T1에서 버스에 동시에 진행되고 있는 일 두 가지는?

??? success "정답과 풀이"
    **정답:** (a) T1 (b) A의 data phase와 B의 address phase

    - T0 끝에서 A의 address가 잡히고, A의 data phase는 T1이다.
    - T1에서는 A의 data phase와 B의 address phase가 동시에 진행된다. 이렇게 겹치는 게 AHB pipeline이다.

---

## 2. Wait state

| 신호 | T0 | T1 | T2 | T3 | T4 |
|---|---|---|---|---|---|
| HTRANS | NONSEQ | NONSEQ | NONSEQ | NONSEQ | IDLE |
| HADDR | A | B | B | B | - |
| HREADYOUT (A의 Subordinate) | 1 | 0 | 0 | 1 | 1 |

(a) A의 data phase는 몇 cycle 동안 이어지나? 끝나는 cycle은?
(b) B의 address phase가 T1~T3 동안 버스에 남아 있는 이유는?

??? success "정답과 풀이"
    **정답:** (a) 3 cycle (T1~T3), T3 끝 edge에서 끝남 (b) A의 Subordinate가 T1, T2에 HREADYOUT=0을 내기 때문

    - A의 data phase는 T1, T2, T3 세 cycle이고, HREADY=1인 T3의 끝 edge에서 끝난다.
    - HREADYOUT=0이 interconnect를 거쳐 HREADY=0으로 퍼진다. 그래서 B의 address가 잡히지 못하고, Manager는 B를 그대로 유지해야 한다.

---

## 3. HTRANS 순서

아래 중 규칙 위반을 모두 고르고 이유를 말하라.

```text
① SINGLE : NONSEQ → BUSY → IDLE
② INCR4  : NONSEQ → BUSY → SEQ → SEQ → SEQ → IDLE
③ INCR4  : NONSEQ → SEQ → IDLE → SEQ → SEQ
④ INCR   : NONSEQ → SEQ → BUSY → IDLE
```

??? success "정답과 풀이"
    **정답:** ①, ③ 위반

    - ① BUSY는 "burst 중간에 잠깐 쉰다"는 뜻이다. SINGLE은 beat가 하나라 이어갈 beat가 없어서 BUSY가 들어갈 자리가 없다.
    - ② BUSY가 burst 중간에 있어서 괜찮다.
    - ③ 위반이 두 번 생긴다. 고정 길이 INCR4를 4 beat 전에 IDLE로 끊었고, IDLE 뒤에는 이어갈 burst가 없는데 SEQ가 왔다.
    - ④ 길이가 정해지지 않은 INCR은 BUSY로 끝나도 된다.

    ```text
    NONSEQ → SEQ → IDLE → SEQ → SEQ
                   ↑       ↑
            고정 길이 중단  이어갈 burst가 없는데 SEQ
    ```

    - INCR4의 4번째 beat 뒤에는 BUSY가 올 수 없다. INCR4는 4번째 SEQ로 burst가 끝나서 이어갈 beat가 없으므로, 그 뒤에는 IDLE이나 새 NONSEQ가 와야 한다. BUSY로 끝날 수 있는 건 길이 미정인 INCR뿐이다.

    ```text
    INCR4: NONSEQ → SEQ → SEQ → SEQ → BUSY   ❌
    INCR4: NONSEQ → SEQ → SEQ → SEQ → IDLE   ✅
    ```

    !!! tip "IDLE의 정확한 뜻"
        IDLE은 "지금 이 cycle엔 전송이 필요 없다"는 뜻이다. "더 이상 보낼 게 없다"와는 다르다. IDLE 다음에도 언제든 NONSEQ로 새 전송을 시작할 수 있다.

    BUSY와 IDLE의 차이, SINGLE–BUSY–SINGLE이 안 되는 이유는 [3.4](amba-ahb.md#34-busy-vs-idle-single-busy)에 있다.

---

## 4. Wait 중 HTRANS 변경

HREADY=0인 동안 Manager가 아래처럼 HTRANS를 바꿨다. 허용되면 O, 위반이면 X.

```text
① IDLE → NONSEQ           (wait 중)
② INCR4의 BUSY → IDLE     (wait 중)
③ INCR의 BUSY → NONSEQ    (wait 중)
④ NONSEQ → IDLE           (wait 중)
```

??? success "정답과 풀이"
    **정답:** ① O ② X ③ O ④ X (스펙 p40–42 wait 중 HTRANS 변경 규칙)

    - ① O: IDLE에서 NONSEQ로 바꾸는 건 허용된다. 바꾼 뒤에는 HREADY=1이 될 때까지 유지해야 한다.
    - ② X: INCR4는 고정 길이라 BUSY에서 SEQ로만 바꿀 수 있다.
    - ③ O: 길이 미정인 INCR은 BUSY에서 아무 타입으로나 바꿀 수 있다. SEQ면 burst를 이어가고, IDLE이나 NONSEQ면 burst가 끝난다.
    - ④ X: NONSEQ는 이미 실제 전송이라 HREADY=1이 될 때까지 바꿀 수 없다.

---

## 5. WRAP 주소 계산

WRAP4, HSIZE = Word(4 byte), 시작 주소 0x38.

(a) wrap 경계(주소 범위)는?
(b) 4 beat 주소를 순서대로 써라.

??? success "정답과 풀이"
    **정답:** (a) 0x30~0x3F (b) 0x38 → 0x3C → 0x30 → 0x34

    1. 경계 크기는 4 beat × 4 byte = 16 byte(0x10)다.
    2. 0x38을 16 byte 단위로 내리면 시작이 0x30이라 범위는 **0x30~0x3F**다.
    3. 0x38 → 0x3C 다음 0x40은 범위 밖이라 0x30으로 돌아간다. 그래서 0x38 → 0x3C → 0x30 → 0x34다.

    !!! tip "범위 표기"
        0x40은 다음 블록의 시작이라 범위에 들어가지 않는다. "0x30~0x40"이 아니라 "0x30 이상, 0x40 미만"(= 0x30~0x3F)이다.

---

## 6. HRESP ERROR

| 신호 | T0 | T1 | T2 | T3 |
|---|---|---|---|---|
| HTRANS | NONSEQ | NONSEQ | NONSEQ | ? |
| HADDR | A | B | B | ? |
| HREADY | 1 | 0 | 1 | 1 |
| HRESP | OKAY | ERROR | ERROR | OKAY |

A의 data phase가 T1~T2에서 ERROR를 받았다.

(a) T1에서 HREADY가 0이어야 하는 이유는?
(b) Manager가 B를 취소하고 싶다면 T2의 HTRANS를 무엇으로 바꿔야 하나?

??? success "정답과 풀이"
    **정답:** (a) HREADY=1이면 B의 address가 그 edge에 이미 잡혀, Manager가 ERROR를 보고 B를 취소할 수 없다. (b) IDLE

    - T1에서 HREADY=0이라 B의 address가 아직 잡히지 않았다.
    - 그래서 Manager가 ERROR를 보고 T2에서 B를 IDLE로 바꿔 취소할 수 있다.
    - ERROR 응답이 2 cycle인 이유가 이것이다. 첫 cycle(HREADY=0)은 Manager에게 판단할 시간을 주고, 둘째 cycle(HREADY=1)에서 전송이 끝난다.

---

## 7. Interconnect의 mux select

Subordinate가 S0과 S1 두 개다.

| 신호 | T0 | T1 | T2 |
|---|---|---|---|
| HADDR | A(S0) | B(S1) | - |
| HSEL | S0 | S1 | - |
| HREADY | 1 | 1 | 1 |

(a) T1에서 mux는 S0과 S1 중 누구의 HRDATA/HREADYOUT을 Manager에게 보내나?
(b) mux select를 HSEL 그대로 쓰면 안 되고 한 cycle 늦춰야 하는 이유는?

??? success "정답과 풀이"
    **정답:** (a) **S0** (b) HSEL은 address phase 기준이고 mux는 data phase 기준이라 pipeline 때문에 한 cycle 어긋난다.

    **T1에 버스에서 일어나는 일**

    | 신호 | T0 | T1 | T2 |
    |---|---|---|---|
    | address | A(S0) | B(S1) | - |
    | data phase | - | A(S0) | B(S1) |
    | HSEL | S0 | S1 | - |
    | mux_sel (HSEL을 한 cycle 늦춘 값) | - | S0 | S1 |

    - T1에서 HSEL=S1인 건 B의 **address phase** 얘기다. 같은 T1에 data phase를 진행하는 건 A이고, A의 Subordinate는 S0이다. Manager가 지금 받아야 할 HRDATA와 HREADYOUT은 A 것이라 mux는 S0을 골라야 한다.

    **HSEL을 그대로 쓰면**

    - mux_sel = HSEL이면 T1에 S1을 고른다. 그러면 A의 데이터 대신 아직 아무것도 안 한 S1의 HRDATA와 HREADYOUT이 Manager에게 간다.

    **그래서 HREADY로 한 cycle 늦춘다**

    ```systemverilog
    if (HREADY) mux_sel <= HSEL;
    ```

    - address가 잡히는 순간(HREADY=1)에 HSEL을 저장하면, 다음 cycle의 data phase 동안 그 Subordinate를 계속 고른다.
    - wait 중(HREADY=0)에는 mux_sel이 안 바뀌어서 data phase가 길어져도 같은 Subordinate를 유지한다.

    !!! tip "한 줄 정리"
        HSEL은 "지금 address를 받을 Subordinate", mux_sel은 "지금 data를 주고받는 Subordinate"다.

---

## 8. Subordinate가 전송을 받아들이는 조건

Subordinate가 "나한테 온 유효한 전송"이라고 보고 address/control을 잡는 조건을 HSEL, HREADY, HTRANS로 쓰고, HREADY가 들어가야 하는 이유를 말하라.

??? success "정답과 풀이"
    **정답:** `if (HSEL && HREADY && (HTRANS == NONSEQ || HTRANS == SEQ))`. Subordinate는 HREADY 없이는 address phase를 받아도 되는지 판단할 기준이 없다. HREADY=1이어야 진행 중인 data phase가 끝나고 새 address를 받을 수 있다.

    - 조건식은 `HSEL && HREADY && HTRANS[1]`과 같다. NONSEQ(2'b10)와 SEQ(2'b11)는 HTRANS[1]이 1이다.
    - IDLE(2'b00)과 BUSY(2'b01)는 HTRANS[1]=0이라 실제 전송으로 잡지 않는다.

    !!! tip "HREADY=0의 뜻"
        HREADY=0은 "지금 진행 중인 data phase가 아직 안 끝났다"는 뜻이다. 그 data phase는 다른 Subordinate 것일 수도, 자기 자신 것일 수도 있다. 어느 쪽이든 끝나기 전에는 새 address를 잡으면 안 된다.

---

## 9. Default Subordinate

메모리 맵에 아무 Subordinate도 없는 빈 주소가 있다.

(a) Manager가 그 주소로 NONSEQ를 보내면 Default Subordinate는 어떻게 응답하나?
(b) 같은 주소로 IDLE을 보내면?
(c) Default Subordinate가 없으면 어떤 문제가 생기나?

??? success "정답과 풀이"
    **정답:** (a) HRESP ERROR (2-cycle) (b) 0-wait OKAY (c) 버스 hang

    - (a) NONSEQ/SEQ에는 ERROR로 응답한다. ERROR는 꼭 2 cycle이다. 첫 cycle은 HREADY=0, 두 번째 cycle은 HREADY=1이다.
    - (b) IDLE/BUSY는 실제 전송이 아니라서 0-wait OKAY다.
    - (c) 아무도 HREADYOUT을 내주지 않으면 HREADY가 정해지지 않아서 버스가 멈출 수 있다.
    - (추론) AXI로 비유하면 DECERR를 내주는 역할이다.

---

## 10. 종합

| 신호 | T0 | T1 | T2 | T3 | T4 |
|---|---|---|---|---|---|
| HTRANS | NONSEQ | NONSEQ | NONSEQ | NONSEQ | IDLE |
| HADDR | A(S0) | B(S1) | B(S1) | B(S1) | - |
| S0 HREADYOUT | - | 0 | 0 | 1 | - |
| S1 HREADYOUT | 1 | 1 | 1 | 1 | 1 |

(a) T1과 T2에 S1의 HREADYOUT은 1인데, S1이 이 cycle에 B의 address를 잡아도 되나? 이유는?
(b) T1~T3 동안 mux는 누구의 HREADYOUT을 HREADY로 보내나?
(c) B의 address가 실제로 잡히는 건 몇 cycle 끝 edge인가?

??? success "정답과 풀이"
    **정답:** (a) 안 된다. A의 data phase가 안 끝났는데 새 address를 받으면 프로토콜 위반이다. (b) S0 (c) T3

    (b)는 address 줄을 한 칸 오른쪽으로 밀어 data phase 줄을 만들면 바로 읽힌다.

    | 신호 | T0 | T1 | T2 | T3 | T4 |
    |---|---|---|---|---|---|
    | HADDR | A(S0) | B(S1) | B(S1) | B(S1) | - |
    | data phase (HADDR를 한 칸 민 것) | - | A(S0) | A(S0) | A(S0) | B(S1) |
    | mux_sel | - | S0 | S0 | S0 | S1 |

    1. T0 끝에서 HREADY=1이라 A의 address가 잡힌다. 그래서 T1부터 A(S0)의 data phase가 시작된다.
    2. T1과 T2는 S0이 HREADYOUT=0이라 A가 안 끝나고, mux_sel도 S0으로 유지된다. 이때 HREADY=0이라 S1의 HREADYOUT=1은 상관없고, S1은 B를 잡으면 안 된다.
    3. T3 끝에서 S0이 HREADYOUT=1을 내서 A가 끝난다. 동시에 B의 address가 잡히고, T4부터 mux_sel이 S1로 바뀐다.

    !!! tip "파형 읽는 팁"
        mux가 누구를 고르는지는 HSEL이 아니라 "data phase 줄"을 보고 판단한다. 그림에 없으면 address 줄을 한 칸 밀어서 만들어 보면 된다.

---

## 문제별 주제

| 문제 | 주제 | 관련 절 |
|---|---|---|
| 1 | 2-stage pipeline | [2.3](amba-ahb.md#23-transfer-pipeline) |
| 2 | Wait state | [2.5](amba-ahb.md#25-pipeline) |
| 3 | HTRANS 순서 (BUSY/IDLE) | [3.4](amba-ahb.md#34-busy-vs-idle-single-busy), [5.4](amba-ahb.md#54) |
| 4 | Wait 중 HTRANS 변경 | [6.1](amba-ahb.md#61-htrans) |
| 5 | WRAP 주소 계산 | [5.2](amba-ahb.md#52) |
| 6 | HRESP ERROR 2-cycle | [7.2](amba-ahb.md#72-2-cycle-error-incr4) |
| 7 | mux select (HSEL vs mux_sel) | [11.2](amba-ahb.md#112-mux_sel-data-phase-retime-hsel) |
| 8 | Subordinate 전송 수락 조건 | [11.4](amba-ahb.md#114-hready-subordinate) |
| 9 | Default Subordinate | [8.2](amba-ahb.md#82-default-subordinate) |
| 10 | 종합 (wait + mux select) | [11.2](amba-ahb.md#112-mux_sel-data-phase-retime-hsel) |
