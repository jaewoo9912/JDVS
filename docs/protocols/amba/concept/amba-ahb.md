# Unit 1-2 — AHB (파이프라인 버스)

> 요약: AHB는 **address phase와 data phase를 한 cycle 어긋나게 겹치는 2단 pipeline 버스**다. 이 페이지는 AHB의 기본 개념(pipeline 아이디어, AHB-Lite, HTRANS, WRAP과 critical word first)과 스펙(ARM IHI 0033C)의 세부 규칙(HTRANS·HSIZE·HBURST, **waited transfer**, **2-cycle ERROR**, interconnect의 HSEL / HREADY / HREADYOUT / default Subordinate)을 AXI와 비교하며 cycle 단위 파형으로 정리한다.
>
> ※ APB·AXI와의 비교(2-phase vs pipeline, Bridge, 셋을 다 쓰는 이유)는 [APB vs AHB vs AXI 비교](amba-bus-comparison.md), 세부 Q&A는 [AHB Q&A](amba-unit1-2-qa.md)에 있다.
>
> ※ 퀴즈 5문제는 맨 끝 [12절](#12-5)에 있다.
>
> ※ 출처: Unit 1-2 AHB 개념 학습 + 2026-11-23 Spec 마스터와의 스펙 학습 (ARM IHI 0033C). 스펙 범위는 1~8단계(개요 ~ interconnect)이고, Locked/HPROT/AHB5 확장은 다루지 않았다.

**파형 표기 규칙**

- `Cn`은 n번째 cycle이고, 표의 `HREADY` 값은 **그 cycle 끝 edge의 값**이다.
- "edge에서 확정" 줄은 그 cycle 끝 edge에서 끝나거나 받아지는 것을 적은 것이다.

---

## 1. 개요 — AXI와 비교

### 1.1 핵심 아이디어 — 주소와 데이터를 겹친다

APB는 "주소를 깔고 → 데이터를 주고받기"를 직렬로 처리한다. AHB는 이 둘을 **한 cycle 어긋나게 겹친다** (명령어 pipeline과 같은 발상).

- A1의 데이터(D1)를 주고받는 cycle에 **이미 A2의 주소가 나간다.**
- pipeline이 차면 **매 cycle 1 transfer**가 끝난다. 이것이 AHB가 APB보다 빠른 이유다. 신호 단위 파형과 cycle 수 비교는 [2.3](#23-transfer-pipeline)에 있다.

### 1.2 AHB-Lite — 실무 기본형

| | AHB (원형) | AHB-Lite |
|---|---|---|
| Manager 수 | 여러 개 (arbiter로 중재) | **1개** |
| 추가 응답 | SPLIT / RETRY | 없음 (OKAY / ERROR만) |
| 복잡도 | 높음 | arbitration·SPLIT·RETRY를 들어내 단순 |

- 실무에서는 대부분 AHB-Lite를 쓰고, Manager가 여럿 필요하면 그 위에 interconnect를 둔다. 이 페이지의 규칙과 파형은 AHB-Lite 기준이다.

### 1.3 등장인물

```text
 [Manager]  ── 주소/명령 ──▶  [Subordinate]
 (CPU 등)   ◀── 읽은 데이터 ──  (메모리, 레지스터 등)
            ── 쓸 데이터 ──▶
```

- **Manager**(옛 Master): transfer를 시작하는 쪽. **Subordinate**(옛 Slave): 응답하는 쪽.
- **transfer** = Manager의 읽기/쓰기 한 번. 항상 **address phase(1 cycle) + data phase(1 cycle 이상)**로 이뤄진다.

### 1.4 채널 구조

```text
AXI:  AW ─▶  W ─▶  B ◀─      (쓰기 3채널)
      AR ─▶  R ◀─            (읽기 2채널)
      → 채널마다 VALID/READY

AHB:  HADDR/HTRANS/HWRITE/HSIZE/HBURST ─▶   (주소+제어, 읽기/쓰기 공용)
      HWDATA ─▶ / HRDATA ◀─                  (데이터)
      HREADY, HRESP ◀─                       (응답)
      → handshake는 HREADY 하나
```

- AHB는 읽기·쓰기가 **주소 버스를 공유**하고, `HWRITE`로 방향만 정한다.

### 1.5 handshake·순서 비교

| | AXI | AHB |
|---|---|---|
| 기다리게 하는 법 | 받는 쪽이 READY=0 | Subordinate가 HREADY=0 |
| 주소 쪽 대기 | AWREADY/ARREADY로 늦출 수 있음 | **못 늦춤**. 주소는 바로 받아야 함 |
| 데이터 쪽 대기 | WREADY/RVALID로 조절 | HREADY=0으로 data phase를 늘림 |
| 순서·동시성 | outstanding + ID로 out-of-order 가능 | outstanding·ID·LAST 없음. 항상 in-order |
| 동시에 진행되는 것 | 여러 transaction | data phase 1개 + 다음 address phase 1개 |

### 1.6 신호 — 방향과 AXI 대응

| AHB | 방향 | 뜻 | AXI 대응 |
|---|---|---|---|
| `HADDR` | M→S | 주소 (address phase) | `AxADDR` |
| `HTRANS[1:0]` | M→S | transfer 종류 IDLE/BUSY/NONSEQ/SEQ | `VALID` (유사, 종류까지 표시) |
| `HWRITE` | M→S | 1=write, 0=read | – (AXI는 채널로 구분) |
| `HSIZE[2:0]` | M→S | beat 크기 = 2^HSIZE byte | `AxSIZE` |
| `HBURST[2:0]` | M→S | burst 종류 + 길이 | `AxLEN` + `AxBURST` |
| `HPROT` | M→S | 보호 속성 | `AxPROT` / `AxCACHE` |
| `HMASTLOCK` | M→S | locked transfer | – |
| `HWDATA` | M→S | write 데이터 (data phase) | `WDATA` |
| `HRDATA` | S→M | read 데이터 (data phase) | `RDATA` |
| `HREADY` | S→M (HREADYOUT → Mux) | data phase 완료. **버스 전체에 하나** | `READY` |
| `HRESP` | S→M | OKAY(0) / ERROR(1)만 | `BRESP` / `RRESP` |
| `HSEL` | Decoder→S | Subordinate 선택 | – |

- `HREADY`가 버스의 박자다. `HREADY=1`인 cycle 끝에 지금 data phase가 끝나고 **동시에 다음 address phase도 확정**된다 (2절).

---

## 2. Transfer 기초 — 2단 pipeline (Fig 3-1 ~ 3-5)

### 2.1 핵심 규칙

!!! tip "매 cycle 끝 edge에서 HREADY 하나로 판정"
    - `HREADY=1`: 지금 data phase인 transfer가 끝난다. 같은 cycle에 address phase인 transfer가 있으면 **그 주소도 함께 확정**된다.
    - `HREADY=0`: 둘 다 그대로 한 cycle 더 간다.

- Subordinate는 address phase 연장을 요청할 수 없다 → **모든 Subordinate는 address phase 동안 주소를 샘플링할 수 있어야 한다** (스펙 문장).
- `HREADY=0`은 언제나 "**지금** data phase 중인 transfer"를 늘린다. 다음 주소가 같이 밀리는 건 **부수 효과**다.
- address phase cycle의 HREADY는 **앞 transfer의 data phase 상태**다. 앞 transfer가 없으면 1이다.

### 2.2 0-wait transfer 하나 (Fig 3-1/3-2)

| 신호 | C0 | C1 |
|---|---|---|
| phase | addr A | data A |
| HADDR | A | – |
| HWDATA / HRDATA | – | D(A) |
| HREADY | 1 | 1 |
| edge에서 확정 | A 주소 (앞 transfer 없음) | A 완료 (0-wait) |

- `HWRITE=1`이면 Manager가 `HWDATA`를, `HWRITE=0`이면 Subordinate가 `HRDATA`를 구동한다.

### 2.3 연속 transfer — pipeline의 이득

transfer 하나로는 겹침이 안 보인다. 0-wait로 **세 번 연속** 쓰면 드러난다.

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | IDLE |
| HADDR | A1 | A2 | A3 | – |
| HWDATA | – | D1 | D2 | D3 |
| HREADY | 1 | 1 | 1 | 1 |
| edge에서 확정 | A1 주소 | A1 완료 + A2 주소 | A2 완료 + A3 주소 | A3 완료 |

- C1, C2: 다음 주소를 내는 **동시에** 앞 데이터를 준다.
- 3 transfer에 4 cycle. APB처럼 직렬이면 6 cycle(2 × 3)이다. 일반적으로 **N transfer = N+1 cycle** (APB는 2N).

### 2.4 wait state — 읽기와 쓰기 (Fig 3-3/3-4)

**읽기 2 wait**

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| phase | addr A | data A (wait 1) | data A (wait 2) | data A |
| HADDR | A | – | – | – |
| HRDATA | – | x | x | **D(A)** |
| HREADY | 1 | 0 | 0 | 1 |
| edge에서 확정 | A 주소 | – | – | A 완료 (HRDATA 샘플) |

**쓰기 1 wait**

| 신호 | C0 | C1 | C2 |
|---|---|---|---|
| phase | addr A | data A (wait) | data A |
| HADDR | A | – | – |
| HWDATA | – | D(A) | D(A) (유지) |
| HREADY | 1 | 0 | 1 |
| edge에서 확정 | A 주소 | – | A 완료 (HWDATA 샘플) |

| | 규칙 | AXI 대응 |
|---|---|---|
| 읽기 | `HREADY=1`로 끝내는 cycle에만 맞는 데이터를 주면 됨 | RVALID를 늦게 올리는 것 |
| 쓰기 | wait 동안 `HWDATA`를 **바꾸면 안 됨** (언제 샘플될지 모름) | WVALID=1, WREADY=0 동안 WDATA 유지 |

!!! tip "APB와의 결정적 차이"
    APB는 주소와 write 데이터를 **같은 phase**(SETUP부터)에 함께 낸다. AHB는 **주소를 먼저(C0), 데이터를 한 cycle 뒤(C1)** 낸다. 이 한 cycle 어긋남 덕에 한 transfer의 data phase 동안 다음 transfer의 address phase를 겹칠 수 있다.

### 2.5 pipeline에서 주소가 밀리는 경우

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| HADDR | A | B | B (유지) | – |
| HWDATA | – | D(A) | D(A) (유지) | D(B) |
| HREADY | 1 | **0** | 1 | 1 |
| edge에서 확정 | A 주소 | – (A wait, B 미확정) | A 완료 + B 주소 | B 완료 |

- C1의 `HREADY=0`은 A의 data phase를 늘리는 것이지, B 주소를 거부하는 게 아니다.

### 2.6 pipeline + wait 혼합 (Fig 3-5)

A = 0-wait 쓰기, B = 1-wait 읽기, C = 0-wait 쓰기.

| 신호 | C0 | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| HADDR | A | B | C | C (유지) | – |
| HWDATA | – | D(A) | – | – | D(C) |
| HRDATA | – | – | x | D(B) | – |
| HREADY | 1 | 1 | **0** | 1 | 1 |
| edge에서 확정 | A 주소 | A 완료 + B 주소 | – (B wait) | B 완료 + C 주소 | C 완료 |

- C1: A의 data와 B의 주소가 겹친다 (pipeline).
- C2: B가 wait(`HREADY=0`)을 건다 → 같은 cycle에 있던 **C의 address phase가 덩달아 늘어난다**.
- C3: B 데이터가 오고 C 주소가 확정된다. C4에 C의 데이터가 온다.

### 2.7 따로 보낼 때 (IDLE 사이에 끼움)

| 신호 | C0 | C1 | C2 |
|---|---|---|---|
| HTRANS | NONSEQ | IDLE | IDLE |
| HADDR | A | – | – |
| HWDATA | – | D(A) | D(A) (유지) |
| HREADY | 1 | 0 | 1 |
| edge에서 확정 | A 주소 즉시 확정 (앞 transfer 없음) | – (A wait) | A 완료 |

| | 따로 보낼 때 | pipeline일 때 |
|---|---|---|
| 주소 cycle의 HREADY | 1 (앞에 진행 중인 게 없음) | 앞 transfer의 data가 결정 |
| 주소가 밀릴 수 있나 | 안 밀림, 바로 확정 | 앞 data가 wait면 덩달아 밀림 |
| Subordinate가 늦출 수 있는 것 | 자기 data phase만 | 자기 data phase만 |

---

## 3. HTRANS

pipeline이라 address phase에는 **매 cycle 무언가가 흐른다.** 그래서 Manager는 매 cycle 그 주소가 실제 transfer인지, 쉬는 cycle인지, burst의 일부인지를 `HTRANS`로 알려야 한다.

### 3.1 네 가지 값

| HTRANS | 이름 | 뜻 | Subordinate 반응 | AXI로 치면 |
|---|---|---|---|---|
| 00 | **IDLE** | 할 일 없음 | 무시, 0-wait OKAY | VALID=0 |
| 01 | **BUSY** | burst 중간에 Manager가 잠깐 쉼 | 무시, 0-wait OKAY | 없음 |
| 10 | **NONSEQ** | single 또는 burst의 첫 beat | 실제 transfer | VALID=1 |
| 11 | **SEQ** | burst의 나머지 beat | 실제 transfer | VALID=1 |

- **NONSEQ**: 주소·control이 이전 transfer와 무관. single transfer도 "길이 1짜리 burst"로 보고 NONSEQ로 보낸다.
- **SEQ**: control은 이전과 **동일**, 주소 = **이전 주소 + transfer size** (WRAP이면 경계에서 감음).

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | SEQ |
| HADDR | 0x20 | 0x24 | 0x28 | 0x2C |
| HSIZE | word | word | word | word |

- 주소는 4B씩 증가하고, control(HSIZE 등)은 전부 같다.

### 3.2 BUSY가 낀 burst (Fig 3-6, INCR 읽기)

| 신호 | C0 | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| HTRANS (addr) | NONSEQ ① | BUSY ② | SEQ ③ | SEQ ④ | – |
| HADDR | 0x20 | 0x24 | 0x24 | 0x28 | – |
| data phase | – | ① 0x20 | ② BUSY | ③ 0x24 | ④ 0x28 |
| HRDATA | – | D(20) | 무시 | D(24) | D(28) |
| HRESP | – | OKAY | **OKAY** | OKAY | OKAY |
| HREADY | 1 | 1 | **1** | 1 | 1 |

- C2 열이 BUSY의 data phase다: `HREADYOUT=1`, `HRESP=OKAY`, 데이터는 의미 없음.

- **C1**: 0x20의 데이터 D(20)이 와서 끝난다. 같은 cycle에 Manager는 BUSY와 함께 **다음 beat 주소(0x24)**를 낸다 (must).
- **C2**: BUSY의 data phase. Subordinate는 0-wait OKAY만 주고, 데이터는 Manager도 무시한다. Manager는 같은 0x24를 이번엔 SEQ로 낸다.
- **C3**: 0x24 SEQ의 data phase라 D(24)가 온다.

!!! tip "데이터는 바로 앞 cycle의 address phase가 결정한다"
    BUSY 다음 cycle에는 데이터가 없고, SEQ 다음 cycle에는 데이터가 있다.

### 3.3 "0-wait OKAY"의 뜻

IDLE/BUSY도 형식상 address phase와 data phase를 가진다. 할 일이 없으니 data phase에서 **`HREADYOUT=1`, `HRESP=OKAY`**로 바로 끝낸다. 여기서 `HREADY=0`을 내면 쉬는 cycle 때문에 버스 전체가 멈춘다.

| 신호 | C1 | C2 |
|---|---|---|
| addr phase | BUSY | (다음 beat) |
| data phase | 앞 transfer | **BUSY** |
| HREADYOUT | 앞 transfer 몫 (여기서는 1 → C1 끝에 BUSY 샘플) | **1** (바로) |
| HRESP | 앞 transfer 몫 | **OKAY** |

- 응답 시점은 BUSY를 받은 cycle이 아니라 **그다음 cycle(BUSY의 data phase)**이다. C1의 HREADY는 앞 transfer 몫이라 0일 수도 있다.

```systemverilog
// 일반적인 구현 형태 (Spec 마스터 추론)
if (HSEL && HREADY) trans_q <= HTRANS;                  // address phase 샘플
if (trans_q == IDLE || trans_q == BUSY) begin           // data phase 응답
  HREADYOUT = 1; HRESP = OKAY;
end
```

| transfer | data phase 응답 |
|---|---|
| NONSEQ / SEQ (실제) | 필요하면 wait, OKAY 또는 ERROR |
| IDLE / BUSY (가짜) | 항상 바로 `1` + OKAY. wait·ERROR 금지 |

!!! tip "누가 쉬는가"
    `BUSY` = **Manager**가 쉼 (burst 도중에만), `HREADY=0` = **Subordinate**가 쉼. burst 밖에서 Manager가 쉴 때는 `IDLE`.

---

## 4. HSIZE / byte lane

### 4.1 HSIZE 값

| HSIZE | 크기 | 이름 |
|---|---|---|
| 000 | 1B (8bit) | Byte |
| 001 | 2B (16bit) | Halfword |
| 010 | 4B (32bit) | Word |
| 011 | 8B (64bit) | Doubleword |
| 100~111 | 16B~128B | line |

- **HSIZE ≤ data bus 폭** (must). 32bit 버스면 000/001/010만 가능.
- address phase timing에 나가고, **burst 동안 불변**.
- 한 beat 크기는 버스 폭이 아니라 **HSIZE**가 정한다. 32bit 버스에서도 HSIZE=Byte면 1B만 옮긴다.

### 4.2 byte lane

```text
HWDATA/HRDATA  [31:24][23:16][15:8][7:0]
byte lane         3      2      1     0
```

| HSIZE | HADDR | 유효 lane |
|---|---|---|
| Byte | 0x01 | lane 1 (`[15:8]`) |
| Byte | 0x03 | lane 3 (`[31:24]`) |
| Half | 0x02 | lane 2, 3 (`[31:16]`) |
| Word | 0x00 | lane 0~3 |

- `Byte_Lane = HADDR mod (버스 바이트 수)` (little-endian).
- 기본 AHB에는 **WSTRB 같은 strobe가 없다** → Subordinate가 HADDR·HSIZE로 lane을 직접 고른다. 모든 lane에 복제할 필요는 없고 유효 lane만 맞으면 된다.
- 주소는 HSIZE에 **aligned**여야 한다 (Word면 하위 2bit = 00). AXI처럼 unaligned 시작 주소를 지원하지 않는다.

### 4.3 narrow burst — beat마다 lane이 바뀐다

32bit 버스, HSIZE=Byte, INCR4, 시작 0x00.

| beat | HADDR | lane3 `[31:24]` | lane2 `[23:16]` | lane1 `[15:8]` | lane0 `[7:0]` |
|---|---|---|---|---|---|
| 0 | 0x00 |  |  |  | AA |
| 1 | 0x01 |  |  | BB |  |
| 2 | 0x02 |  | CC |  |  |
| 3 | 0x03 | DD |  |  |  |

!!! warning "첫 beat의 lane을 끝까지 쓰면 틀린다"
    Subordinate는 **beat마다 HADDR를 다시 보고** lane을 골라야 한다. AXI narrow transfer와 같은 개념이고, 차이는 AHB 기본형에 strobe가 없다는 것뿐이다.

---

## 5. Burst (HBURST)

### 5.1 HBURST 값

| HBURST | 이름 | 용도 | AXI로 치면 |
|---|---|---|---|
| 000 | SINGLE | 일반 단일 접근 | LEN=0 |
| 001 | INCR | 길이를 모를 때 | INCR인데 **길이 미정** (AXI에 없음) |
| 011 / 101 / 111 | INCR4 / 8 / 16 | 정해진 크기의 블록 | INCR, LEN=3/7/15 |
| 010 / 100 / 110 | WRAP4 / 8 / 16 | **cache line fill** | WRAP, LEN=3/7/15 |

- 길이 = **beat 수**, 총 바이트 = beat 수 × HSIZE. 예: 32bit 버스, Word, INCR4 → 16B.
- 고정 길이는 4/8/16만. 그 외 길이는 **INCR**로 보내고 NONSEQ나 IDLE로 끝낸다.
- AXI의 **FIXED burst는 없다**.

### 5.2 주소 계산

| 종류 | 예 | 주소 순서 |
|---|---|---|
| INCR | INCR4, Word, 0x38 | `38 → 3C → 40 → 44` |
| INCR | INCR8, Half, 0x34 | `34 → 36 → 38 → 3A → 3C → 3E → 40 → 42` |
| WRAP (경계 16B) | WRAP4, Word, 0x34 → 블록 `0x30~0x3F` | `34 → 38 → 3C → 30` |
| WRAP (경계 16B) | WRAP4, Word, 0x04 → 블록 `0x00~0x0F` | `04 → 08 → 0C → 00` |
| WRAP (경계 8B) | WRAP4, Half, 0x04 → 블록 `0x00~0x07` | `04 → 06 → 00 → 02` |
| WRAP (경계 32B) | WRAP8, Word, 0x34 → 블록 `0x20~0x3F` | `34 → 38 → 3C → 20 → 24 → 28 → 2C → 30` |
| WRAP (경계 32B) | WRAP8, Word, 0x18 → 블록 `0x00~0x1F` | `18 → 1C → 00 → 04 → 08 → 0C → 10 → 14` |

- INCR: `다음 주소 = 이전 주소 + HSIZE 바이트`, 경계에서 감지 않음.
- WRAP: **경계 = beat 수 × HSIZE 바이트**, 그 크기로 정렬된 블록 안에서 돈다. AXI WRAP과 계산법이 같다.

### 5.3 WRAP이 필요한 이유 — critical word first

CPU가 cache miss로 line 하나(예: 32B)를 통째로 채워야 하는데, **당장 필요한 word가 line 중간**에 있을 수 있다.

| 방식 (32B line `0x00~0x1F`, Word, 필요한 word 0x14) | 주소 순서 | 필요한 word 도착 |
|---|---|---|
| INCR8로 line 처음부터 | `00 → 04 → 08 → 0C → 10 → 14 → 18 → 1C` | 6번째 beat |
| WRAP8로 필요한 word부터 | `14 → 18 → 1C → 00 → 04 → 08 → 0C → 10` | **1번째 beat** |

- WRAP은 필요한 word부터 받고, line 경계에 닿으면 line 앞으로 돌아와 나머지를 채운다.

```text
wrap 경계(byte) = 2^HSIZE × beat 수
블록 시작      = floor(시작 주소 / wrap 경계) × wrap 경계
다음 주소      = 현재 주소 + 2^HSIZE, 블록 끝을 넘으면 블록 시작으로
```

| 예 | 출발 위치 | wrap? | 순서 |
|---|---|---|---|
| WRAP4, Word, 0x34 (블록 `0x30~0x3F`) | 블록 **중간** | **예** | `34 → 38 → 3C → 30` |
| WRAP8, Word, 0x1000 (블록 `0x1000~0x101F`) | 블록 **시작** (aligned) | 아니오 | `1000 → 1004 → … → 101C` |

!!! tip "aligned 시작이면 WRAP과 INCR의 주소가 같다"
    8 beat가 블록을 정확히 채우고 끝나므로 되돌아올 일이 없다. WRAP의 "되돌아옴"은 **출발 주소가 블록 중간일 때만** 보인다.

### 5.4 꼭 지켜야 하는 규칙

| 규칙 | 내용 |
|---|---|
| 1KB 경계 | INCR burst는 1KB 경계를 넘으면 안 됨 (must not). 예: INCR4, Word, 0x3F8 → `3F8, 3FC, 400(✗)` |
| 이유 | decode region(Subordinate 하나의 영역)이 최소 1KB → burst 도중 다른 Subordinate로 넘어가는 것을 막음. AXI 4KB 규칙과 같은 목적 |
| 정렬 | burst 안 모든 beat는 HSIZE로 aligned |
| 마지막 beat | 고정 길이 burst는 마지막이 **SEQ** |
| BUSY 위치 | NONSEQ로 시작한 burst **중간에만**. SINGLE 뒤 BUSY 금지 |
| BUSY로 종료 | **INCR(미정)만** 가능 (BUSY 다음 IDLE/NONSEQ) |

| burst | HTRANS 순서 | 판정 | 이유 |
|---|---|---|---|
| INCR4 | NONSEQ → SEQ → BUSY → SEQ → SEQ → IDLE/NONSEQ | ✅ | 4 beat 다 채우고 SEQ로 끝 |
| INCR4 | NONSEQ → SEQ → SEQ → SEQ → BUSY | ❌ | 4 beat 끝났는데 BUSY |
| INCR4 | NONSEQ → SEQ → SEQ → BUSY → IDLE | ❌ | 3 beat만 보내고 종료 |
| INCR | NONSEQ → SEQ → SEQ → BUSY → IDLE | ✅ | 길이 미정이라 OK |
| INCR | NONSEQ → SEQ → BUSY → NONSEQ(새 transfer) | ✅ | 길이 미정이라 OK |

### 5.5 LAST 신호 없이 burst 끝을 아는 법

| burst | 끝을 아는 방법 |
|---|---|
| 고정 길이 | HBURST로 beat 수를 미리 안다 → SEQ 개수를 센다 |
| INCR (미정) | 다음 cycle에 SEQ가 아닌 값(IDLE/NONSEQ)이 나오면 끝 |

!!! warning "Subordinate는 burst가 다 안 끝나도 정상 동작해야 한다"
    ERROR 후 Manager가 남은 beat를 취소하거나, interconnect가 다른 Manager에게 버스를 넘기려고 burst를 끊을 수 있다. "4 beat 다 올 것"이라고 가정하면 안 된다.

---

## 6. Waited transfer — wait 중 변경 규칙 (Fig 3-13 ~ 3-17)

앞 transfer가 wait 중(`HREADY=0`)일 때 address phase에 나와 있는 다음 transfer는 **기본적으로 바꿀 수 없다** (AXI의 "VALID 올리면 READY까지 payload 유지"와 같은 원칙). 예외만 외운다.

### 6.1 HTRANS 변경

| 지금 HTRANS | 허용되는 변경 | 바꾼 뒤 |
|---|---|---|
| IDLE | → NONSEQ | HREADY=1까지 NONSEQ 유지 |
| BUSY (고정 길이 burst) | → SEQ만 | HREADY=1까지 SEQ 유지 |
| BUSY (INCR 미정) | → 아무 값 | SEQ면 계속, IDLE/NONSEQ면 burst 종료 |
| NONSEQ / SEQ | **변경 금지** | – |

**① IDLE → NONSEQ (Fig 3-13)**

| 신호 | C0 | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|---|
| HTRANS | NONSEQ | IDLE | IDLE | **NONSEQ** | NONSEQ | NONSEQ | SEQ |
| HADDR | A | Y | Z | B | B | B | B+4 |
| HBURST | SINGLE | – | – | INCR4 | INCR4 | INCR4 | INCR4 |
| data phase | – | A | A | A | A | A | B |
| HREADY | 1 | 0 | 0 | 0 | 0 | 1 | 1 |
| edge에서 확정 | A 주소 | – | – | – | – | A 완료 + B 주소 | B 완료 + B+4 주소 |

- C1~C4: A(SINGLE)의 data phase가 wait 중. 그동안 IDLE이라 주소를 Y, Z로 자유롭게 바꾼다.
- C3: IDLE → NONSEQ(B). **NONSEQ가 된 순간부터** HTRANS·주소 고정.
- C5 끝: A 완료와 동시에 B 주소 확정.

**② 고정 길이 burst의 BUSY → SEQ (Fig 3-14, INCR4)**

| 신호 | C0 | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|---|
| HTRANS | SEQ | BUSY | BUSY | **SEQ** | SEQ | SEQ | SEQ |
| HADDR | 0x24 | 0x28 | 0x28 | 0x28 | 0x28 | 0x28 | 0x2C |
| data phase | 앞 beat | 0x24 | 0x24 | 0x24 | 0x24 | 0x24 | 0x28 |
| HREADY | 1 | 0 | 0 | 0 | 0 | 1 | 1 |
| edge에서 확정 | 앞 beat 완료 + 0x24 주소 | – | – | – | – | 0x24 완료 + 0x28 주소 | 0x28 완료 + 0x2C 주소 |

- 고정 길이라 BUSY에서 바꿀 수 있는 건 **SEQ뿐**. IDLE/NONSEQ로 바꾸면 burst를 덜 채우고 끝내는 것이라 금지.

**③ INCR의 BUSY → 아무거나 (Fig 3-15)**

| 신호 | C0 | C1 | C2 | C3 | C4 | C5 | C6 |
|---|---|---|---|---|---|---|---|
| HTRANS | SEQ | BUSY | BUSY | **NONSEQ** | NONSEQ | NONSEQ | SEQ |
| HADDR | 0x64 | 0x68 | 0x68 | 0x10 | 0x10 | 0x10 | 0x14 |
| HBURST | INCR | INCR | INCR | INCR4 | INCR4 | INCR4 | INCR4 |
| data phase | 앞 beat | 0x64 | 0x64 | 0x64 | 0x64 | 0x64 | 0x10 |
| HREADY | 1 | 0 | 0 | 0 | 0 | 1 | 1 |
| edge에서 확정 | 앞 beat 완료 + 0x64 주소 | – | – | – | – | 0x64 완료 + 0x10 주소 | 0x10 완료 + 0x14 주소 |

- Manager가 BUSY로 고민하다 C3에서 새 burst(NONSEQ, 0x10)로 바꾼다. INCR burst는 0x64 beat에서 끝난 것이 된다.

| 경우 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| ✅ HTRANS | IDLE | IDLE | NONSEQ | NONSEQ |
| ❌ HTRANS | NONSEQ | NONSEQ | **IDLE** | IDLE |
| HREADY (공통) | 0 | 0 | 0 | 1 |

- ✅: IDLE → NONSEQ는 허용. ❌: 실제 transfer(NONSEQ)를 wait 중에 IDLE로 철회하는 건 금지.

### 6.2 주소 변경

스펙: wait 중 Manager는 주소를 **한 번만** 바꿀 수 있다. 예외는 두 가지다.

| 예외 | 내용 |
|---|---|
| IDLE 동안 | 자유롭게 변경. 단 NONSEQ로 바꾼 뒤에는 HREADY=1까지 고정 |
| ERROR 응답 이후 | HREADY=0이어도 변경 가능 (남은 burst 취소 → IDLE이나 새 주소로) |

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| HTRANS | IDLE | IDLE | NONSEQ | NONSEQ |
| HADDR | 0x10 | 0x20 | 0x30 | 0x30 (고정) |
| HREADY | 0 | 0 | 0 | 1 |
| 비고 | IDLE: 주소 자유 | IDLE: 주소 자유 | NONSEQ부터 고정 | C3 끝에 0x30 확정 |

### 6.3 Subordinate 설계 결론

address phase 신호는 wait 중에 바뀔 수 있다 → Subordinate는 **HREADY=1인 edge에서만** HSEL·HADDR·HTRANS·control을 샘플링한다 (`if (HSEL && HREADY)`).

!!! tip "비유 — 창구 앞 줄"
    앞 transfer가 wait 중이면 다음 transfer는 **창구 앞에 줄 선 손님**이다.
    실제 손님(NONSEQ/SEQ)은 창구가 열릴 때까지 바뀌면 안 된다. 빈자리(IDLE)나 BUSY는 실제 손님으로 바꿀 수 있다.
    창구에서 "A는 에러"라고 하면(ERROR), 줄 선 B는 취소하고 나가도 된다.

---

## 7. HRESP — OKAY와 2-cycle ERROR

### 7.1 HRESP × HREADYOUT 조합

| HRESP | HREADYOUT | 의미 |
|---|---|---|
| OKAY(0) | 0 | 아직 처리 중 (wait) |
| OKAY(0) | 1 | 성공, 끝 |
| ERROR(1) | 0 | ERROR 1st cycle |
| ERROR(1) | 1 | ERROR 2nd cycle, 끝 |

- AHB 기본형은 **OKAY와 ERROR 두 가지**뿐이다 (AXI의 SLVERR/DECERR 구분 없음).
- **wait 중에는 반드시 OKAY** (must). ERROR를 늦게 내려면 앞에 OKAY + HREADY=0 wait을 넣는다.

| 신호 | C0 | C1 | C2 | C3 |
|---|---|---|---|---|
| HRESP | OKAY | OKAY | ERROR | ERROR |
| HREADY | 0 | 0 | 0 | 1 |
| 의미 | wait | wait | ERROR 1st | ERROR 2nd (완료) |

- `HREADY=0`이어도 **HRESP 값은 유효**하다. Manager는 1st cycle 끝 edge에서 `ERROR + HREADY=0`을 보고 "에러 진행 중, 한 cycle 더"를 안다.

### 7.2 2-cycle ERROR의 이유 — INCR4 전체 스케줄

32bit 버스, Word, 시작 0x20, **0x24 beat에서 ERROR**. ERROR는 **0x24 자신의 응답**이고, 2 cycle은 줄 서 있던 다음 beat(0x28)를 취소할 기회를 주는 장치다.

**정상 진행 (비교 기준)**

| 신호 | C0 | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | SEQ | IDLE |
| HADDR | 0x20 | 0x24 | 0x28 | 0x2C | – |
| data phase | – | D(20) | D(24) | D(28) | D(2C) |
| HRESP | – | OKAY | OKAY | OKAY | OKAY |
| HREADY | 1 | 1 | 1 | 1 | 1 |

**① 2-cycle ERROR + Manager가 취소 (올바른 동작)**

| 신호 | C0 | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | **IDLE** | IDLE |
| HADDR | 0x20 | 0x24 | 0x28 | – | – |
| data phase | – | 0x20 | 0x24 | 0x24 | IDLE |
| HRESP | – | OKAY | ERROR | ERROR | OKAY |
| HREADY | 1 | 1 | 0 | 1 | 1 |
| edge에서 확정 | 0x20 주소 | 0x20 완료 + 0x24 주소 | (멈춤) Manager가 ERROR 인지 | 0x24 ERROR 완료 + IDLE 확정 | IDLE 완료 |

- C2 끝: HREADY=0이라 아무것도 확정되지 않는다. Manager는 여기서 ERROR를 처음 본다.
- C3: Manager가 0x28을 IDLE로 바꾼다 (ERROR 예외라 허용). 0x28은 **보내지지 않은 채** 사라진다.

**② 2-cycle ERROR + Manager가 계속 (이것도 올바른 동작)**

| 신호 | C0 | C1 | C2 | C3 | C4 | C5 |
|---|---|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | SEQ | SEQ | IDLE |
| HADDR | 0x20 | 0x24 | 0x28 | 0x28 (유지) | 0x2C | – |
| data phase | – | 0x20 | 0x24 | 0x24 | 0x28 | 0x2C |
| HRESP | – | OKAY | ERROR | ERROR | OKAY | OKAY |
| HREADY | 1 | 1 | 0 | 1 | 1 | 1 |
| edge에서 확정 | 0x20 주소 | 0x20 완료 + 0x24 주소 | (멈춤) | 0x24 ERROR 완료 + 0x28 주소 | 0x28 완료 + 0x2C 주소 | 0x2C 완료 |

- C3에서 두 일이 동시에: data phase에서는 0x24가 ERROR 2nd로 끝나고, address phase에서는 **C2부터 유지하던** 0x28이 C3 끝에 확정된다. 취소는 선택이다.

**③ 1-cycle ERROR (스펙 위반)**

| 신호 | C0 | C1 | C2 | C3 | C4 |
|---|---|---|---|---|---|
| HTRANS | NONSEQ | SEQ | SEQ | SEQ | IDLE |
| HADDR | 0x20 | 0x24 | 0x28 | 0x2C | – |
| data phase | – | 0x20 | 0x24 | 0x28 | 0x2C |
| HRESP | – | OKAY | ERROR | OKAY | OKAY |
| HREADY | 1 | 1 | **1** | 1 | 1 |
| edge에서 확정 | 0x20 주소 | 0x20 완료 + 0x24 주소 | 0x24 ERROR 완료 + **0x28 주소 (이미 확정!)** | 0x28 완료 + 0x2C 주소 | 0x2C 완료 |

- 이 표는 Manager가 0x2C를 그대로 보낸 경우다. C3의 address phase를 IDLE로 바꾸면 0x2C는 막을 수 있지만, 0x28은 C2 끝에 이미 확정돼 막을 수 없다.

| | 0x24 ERROR를 아는 시점 | 0x28 확정 시점 | 0x28 취소 가능? |
|---|---|---|---|
| 2-cycle | C2 끝 | C3 끝 | ✅ (C3에 IDLE로 바꿈) |
| 1-cycle | C2 끝 | **C2 끝 (동시)** | ❌ |

!!! warning "1-cycle ERROR는 스펙 위반 — 근본 원인은 pipeline"
    AHB는 "앞 data phase 끝"과 "다음 address 확정"이 **같은 edge**다. 1-cycle ERROR면 Manager가 에러를 아는 순간 다음 transfer가 이미 Subordinate에 받아져, 쓰기라면 원치 않는 데이터가 한 번 더 써질 수 있다. 1st cycle(`HREADY=0`)이 그 사이에 **1 cycle 틈**을 만든다.
    반대로 1st cycle(ERROR, HREADY=0) 뒤에 OKAY로 끝내는 것도 금지다. 결과가 모호해진다.

- AXI는 주소·응답 채널이 분리되고 outstanding으로 주소를 미리 다 보내므로 이런 "취소" 개념이 없다. 에러가 나도 이미 보낸 transfer는 모두 응답을 받는다.

### 7.3 그 외 규칙

| 규칙 | 내용 |
|---|---|
| ERROR 때 read data | 유효할 필요 없음. **0 권장** (데이터 누설 방지) |
| 최대 wait 수 | Subordinate마다 최대 wait cycle이 정해져 있어야 함 (wait이 버스 전체를 멈추므로 최대 latency 계산용) |
| 취소 범위 | 이미 확정된 transfer는 취소 불가. 취소할 수 있는 건 ERROR 뒤에 줄 선 다음 transfer뿐 |

---

## 8. Interconnect 구성 — Decoder / Mux / default Subordinate

AHB(특히 AHB-Lite)는 보통 **Manager 1 : Subordinate N** 구조다 (Manager가 여럿이면 arbiter/matrix 추가). 스펙 Fig 4-1(AHB-Lite block diagram), Fig 4-2(Multiplexor interconnection)가 이 구조다.

| 블록 | 하는 일 |
|---|---|
| Decoder | HADDR → Subordinate별 `HSELx` (one-hot) |
| Mux | 지금 data phase인 Subordinate의 HRDATA / HRESP / HREADYOUT을 골라 Manager에게 전달. 고른 HREADYOUT은 HREADY로 모든 Subordinate에도 broadcast |
| Default Subordinate | 아무 영역에도 안 맞는 주소 담당 |

!!! tip "Mux와 HREADY 동작은 11절"
    연결 구조, mux_sel retime, HREADY vs HREADYOUT, HREADY가 Subordinate로 들어가는 이유는 [11절](#11-interconnect-mux-hready)에 정리했다.

### 8.1 Decoder와 HSEL

- HADDR만 보고 one-hot HSEL을 만드는 **조합 회로**.
- HSEL은 encoded 값이 아니라 **Subordinate마다 1bit**(`HSELx`). num_slv=5면 HSEL0~HSEL4, 각 1bit. 3bit encoded 값은 mux select 쪽 구현에서 쓰는 경우가 많다 (구현 방식, 추정).
- **Subordinate당 최소 영역 1KB** → burst 1KB 경계 규칙과 짝을 이뤄 burst 도중 HSEL이 바뀌지 않는다.
- Subordinate 하나가 HSEL을 여러 개 가질 수도 있다 (영역이 여러 곳일 때).

### 8.2 Default Subordinate

```text
메모리 맵
0x0000 ~ 0x0FFF : Sub0 (SRAM)
0x1000 ~ 0x1FFF : Sub1 (레지스터 블록)
0x2000 ~ 0xFFFF : 아무도 없음 ← 0x5000 NONSEQ 접근 시
```

| 신호 | C0 | C1 | C2 … |
|---|---|---|---|
| addr phase | 0x5000 (NONSEQ) | 다음 transfer (대기) | 다음 transfer (대기) |
| data phase | – | 0x5000: 응답자 없음 | 0x5000: 응답자 없음 |
| HREADY | 1 | X 또는 0 | X 또는 0 |
| 결과 | 0x5000 주소 확정 | mux가 고를 HREADYOUT 없음 | bus hang |

```text
HADDR ──▶ Decoder ──▶ HSEL0 ─▶ Sub0
                  ├─▶ HSEL1 ─▶ Sub1
                  └─▶ HSEL_default ─▶ Default Sub   (나머지 영역 전부)
```

| 받은 HTRANS | Default Subordinate 응답 |
|---|---|
| NONSEQ / SEQ | **ERROR** (2-cycle) |
| IDLE / BUSY | 0-wait **OKAY** |

- 기능(메모리·레지스터)은 없고 응답만 하는 작은 블록이다.
- 스펙 조건: 메모리 맵이 **전체 주소 공간을 다 채우지 않으면** 둔다. 다 채워져 있으면 필요 없다.
- AXI interconnect가 빈 주소에 **DECERR**을 주는 것과 같은 역할. AHB에는 DECERR이 없어 ERROR로 대신한다.

---

## 9. VIP 구현 관점

Mux와 Decoder는 interconnect(시스템) 쪽 부품이라 VIP의 핵심은 **Manager와 Subordinate** 두 개다.

```text
          ┌──────────────┐
HSEL   ──▶│              │
HREADY ──▶│   Sub VIP    │──▶ HREADYOUT
HADDR..──▶│              │──▶ HRESP, HRDATA
          └──────────────┘

1:1 연결 (Mux 없음, HSEL = 1)
[Manager VIP] ──addr/ctrl──────▶ [Subordinate VIP]
              ◀──HRDATA/HRESP──
       HREADY ◀──────┬────────── HREADYOUT
                     └─────────▶ HREADY (Subordinate 입력)
```

| 구성 | 포트 / 동작 |
|---|---|
| Subordinate VIP | `HSEL`, `HREADY` 입력 + `HREADYOUT` 출력을 **반드시 분리된 포트**로. 주소는 `HSEL && HREADY` 기준 sampling. data phase 길이는 `HREADYOUT`으로만 조절. 신호 표 기준은 [11.5](#115-table-2-3-2-5) |
| Manager VIP | `HREADY`, `HRESP`, `HRDATA`만 봄 (Table 2-5 신호를 입력). HSEL·HREADYOUT은 몰라도 됨 |
| Monitor | 주소 sampling을 반드시 `HREADY` 입력 기준으로 |
| 1:1 TB | `HREADY = HREADYOUT` (wire 하나), `HSEL = 1` |
| 1:N TB | 사용자가 decoder·mux 연결. VIP가 간단한 decoder/mux/default Subordinate를 옵션으로 제공 가능 (추론, 스펙 필수 아님) |

!!! warning "1:1에서 HREADYOUT을 HREADY 대신 쓰지 말 것"
    1:1에서는 두 값이 같아 티가 안 나지만, 실제 DUT 버스(Subordinate 여러 개)에 붙이면 **남의 wait 중에 주소를 잘못 받는** 버그가 된다. 포트를 나누는 이유는 Subordinate 설계가 연결 환경과 무관하게 동일해야 하기 때문이다. 이유는 [11.4](#114-hready-subordinate) 참고.

- Default 모드: Subordinate VIP를 "모든 NONSEQ/SEQ에 ERROR" 모드로 설정할 수 있으면 편하다. 미매핑 주소 NONSEQ → 2-cycle ERROR, IDLE → 0-wait OKAY를 체크한다 (추론).

!!! tip "상용 AHB VIP 구성 (Spec 마스터 경험상 일반적인 경우)"
    Manager, Subordinate, Monitor를 기본으로 주고, 여러 Subordinate 환경용 간단한 Decoder/Mux나 default Subordinate를 테스트벤치용 선택 컴포넌트로 두기도 한다.

---

## 10. 전체 요약

| 주제 | 핵심 |
|---|---|
| 개념 | address/data phase를 한 cycle 겹침 → N transfer = N+1 cycle. 실무는 단일 Manager인 AHB-Lite |
| Pipeline | 매 cycle 끝 `HREADY=1`이면 data 완료 + 다음 주소 확정, `0`이면 둘 다 유지 |
| HTRANS | IDLE/BUSY는 0-wait OKAY. NONSEQ = 시작, SEQ = 이어짐(+size). BUSY의 주소는 다음 beat |
| HSIZE | beat 크기, 버스 폭 이하, burst 중 불변. lane = HADDR mod 버스 바이트 |
| Burst | HBURST = 종류 + 길이. WRAP 경계 = beat × size (critical word first). INCR 1KB 경계 금지. 고정 길이는 SEQ로 끝 |
| Waited transfer | 실제 transfer는 wait 중 고정. IDLE→NONSEQ, BUSY→SEQ(INCR은 아무거나), ERROR 후 변경 허용 |
| HRESP | OKAY / ERROR. wait 중 OKAY. ERROR는 2-cycle (pipeline 때문) |
| Interconnect | 나가는 건 broadcast + HSEL, 돌아오는 건 mux. 주소 받는 시점은 HREADY로 알고, 내 data phase 끝은 HREADYOUT으로 정함. 빈 주소는 default Subordinate |

---

## 11. Interconnect 정리 — Mux와 HREADY

### 11.1 연결 구조 — 나가는 건 broadcast, 돌아오는 건 mux

```text
Manager ──HADDR/HTRANS/HWRITE/HSIZE/HBURST/HWDATA (broadcast)──▶ Sub0, Sub1, Sub2
HADDR ──▶ Decoder ──HSEL0/HSEL1/HSEL2 (one-hot)──▶ 각 Sub

Sub0 ─HRDATA/HRESP/HREADYOUT0─┐
Sub1 ─HRDATA/HRESP/HREADYOUT1─┼─▶ Mux ─▶ HRDATA, HRESP, HREADY ─▶ Manager
Sub2 ─HRDATA/HRESP/HREADYOUT2─┘                    └──── HREADY ─▶ 모든 Sub (입력)
```

| 방향 | 신호 | 연결 |
|---|---|---|
| Manager → Sub | HADDR, HTRANS, HWRITE, HSIZE, HBURST, HPROT, HWDATA | 모든 Sub에 broadcast. 내 것인지는 HSEL로 구분 |
| Sub → Manager | HRDATA, HRESP, HREADYOUT | Mux가 하나를 골라 전달 |
| Mux → 전체 | HREADY | Manager와 모든 Sub에 같은 wire로 broadcast |

### 11.2 mux_sel — data phase로 retime한 HSEL

HSEL은 address phase 신호이고 HRDATA는 다음 cycle(data phase)에 나온다. 그래서 Mux는 **HREADY=1 edge에서 저장해 둔 HSEL**로 고른다.

| 신호 | C0 | C1 | C2 |
|---|---|---|---|
| addr phase | A (Sub0) | B (Sub1) | – |
| data phase | – | A (Sub0) | B (Sub1) |
| HSEL | Sub0 | Sub1 | – |
| HREADY | 1 | 1 | 1 |
| mux_sel | – | **Sub0** | **Sub1** |

```systemverilog
if (HREADY) mux_sel <= HSEL;   // wait 중에는 유지 (일반적인 구현 예)
```

- HRDATA, HRESP, HREADYOUT 세 신호를 **같은 mux_sel**로 고른다. HREADYOUT은 고르는 기준이 아니다.

### 11.3 HREADY vs HREADYOUT

| | HREADYOUT | HREADY |
|---|---|---|
| 개수 | Subordinate마다 하나 | **버스 전체에 하나** |
| src → dst | 각 Sub(출력) → Mux | Mux → Manager + 모든 Sub(입력) |
| 의미 | **내** data phase 끝남/아직 | **버스 전체**의 현재 transfer 끝남/아직 |

- "Subordinate가 HREADY=0을 준다"는 정확히는 **HREADYOUT=0이 mux를 거쳐 HREADY로 전달**된다는 뜻이다.
- HREADY=0이면 **모두가 멈춘다.** 당사자 Sub는 그동안 내부 일(예: 느린 SRAM read)을 계속하고, 끝나는 시점을 HREADYOUT=1로 직접 정한다.

### 11.4 HREADY가 Subordinate로 들어가는 이유

목적은 **내 transfer의 시작 시점(주소를 받는 edge)**을 정확히 아는 것이다.

1. HSEL=1은 "나한테 온 주소"일 뿐, 지금 받아도 된다는 뜻은 아니다.
2. **`HSEL && HREADY && (NONSEQ/SEQ)`인 edge**에서만 주소와 control을 저장하고, 다음 cycle부터 내 data phase다.
3. 다른 Sub의 data phase가 진행 중이면 HREADY=0이므로 기다린다. Sub1은 Sub0의 HREADYOUT을 볼 수 없어서 HREADY 입력이 필요하다.
4. AHB는 data 경로가 한 벌뿐이고 **outstanding이 없어** 중간에 끼어들 수 없다.

| | HREADY를 보고 저장 | HSEL만 보고 저장 |
|---|---|---|
| 주소 저장 시점 | 앞 transfer가 끝난 edge | 앞 transfer wait 중에 바로 |
| data phase | 앞 transfer가 끝난 뒤 시작 | 앞 transfer와 겹침 |
| 결과 | 정상 | 잘못된 data, 같은 transfer 중복 처리 |

- 1:1 연결이면 HREADY = 자기 HREADYOUT이라 차이가 없지만, 1:N에서는 바로 깨진다. 그래서 내부 로직에서 HREADYOUT을 HREADY 대신 쓰지 않는다 ([9절](#9-vip) 포트 분리).

### 11.5 스펙 신호 표의 이름 붙이기 (Table 2-3, 2-5)

- 스펙은 신호를 **블록 기준**으로 나열해, 같은 이름(HRDATA, HRESP)이 Subordinate 표(2-3)와 Multiplexor 표(2-5)에 모두 나온다. mux를 지나도 이름을 유지한다(Table 2-5 note a).
- READY만 mux 결과가 다시 Subordinate 입력으로 들어오므로, 입력·출력 이름이 겹치지 않게 출력을 `HREADYOUT`으로 나눴다.

!!! tip "한 줄 정리"
    Subordinate는 **다른 Subordinate의 data phase가 언제 끝나는지 모른다.** 그래서 내 주소를 언제 받아야 할지 스스로 알 수 없고, 이를 버스 전체의 `HREADY`로 안다 → `HSEL && HREADY && (NONSEQ|SEQ)`일 때 주소를 받는다.
    반대로 **내 data phase가 언제 끝날지는 내가 정한다** → 처리 중이면 `HREADYOUT=0`으로 늘리고, 끝나면 `HREADYOUT=1`을 낸다. 이 값이 Mux를 거쳐 `HREADY`가 된다.

---

## 12. 퀴즈 (5문제)

!!! success "결과: 5문제 전부 정답"

### Q1. Pipeline

32-bit 버스. C0에 A(0x10, NONSEQ, read), C1에 B(0x20, NONSEQ, read)가 address phase에 있다. C1에서 HREADY=0, C2에서 HREADY=1이다.

(a) B의 주소는 어느 cycle 끝 edge에서 확정되나?
(b) B의 HRDATA는 어느 cycle에 유효해야 하나? (B는 0-wait)

??? success "정답"
    **(a) C2 끝  (b) C3**

    | cycle | C0 | C1 | C2 | C3 |
    |---|---|---|---|---|
    | addr phase | A | B | B (유지) | – |
    | data phase | – | A (wait) | A 완료 | **B** |
    | HREADY | 1 | 0 | 1 | 1 |
    | edge에서 확정 | A 주소 | 없음 (멈춤) | A 완료, **B 주소** | **B 완료 (HRDATA 유효)** |

    C1의 HREADY=0 때문에 B의 address phase가 C2까지 늘어난다.

### Q2. HTRANS / Burst

INCR4 burst 도중 Manager가 BUSY를 보냈다.

(a) Subordinate는 그 BUSY의 data phase에서 어떤 응답을 줘야 하나? (HREADYOUT, HRESP)
(b) INCR4 burst를 마지막에 BUSY로 끝내도 되나?

??? success "정답"
    **(a) HREADYOUT=1, HRESP=OKAY (0-wait). Subordinate는 그 transfer를 무시한다.**

    **(b) 안 된다.** 고정 길이 burst는 마지막 beat가 반드시 SEQ이고, 그다음에는 IDLE이나 NONSEQ가 온다. BUSY로 끝낼 수 있는 건 길이 미정인 INCR뿐이다.

### Q3. WRAP

WRAP8, HSIZE=word(4B), 시작 주소 0x18. 8개 beat의 주소를 순서대로 쓰라. (힌트: wrap 범위부터)

??? success "정답"
    wrap 범위 = 8 beat × 4B = 32B → **0x00 ~ 0x1F**

    **0x18 → 0x1C → 0x00 → 0x04 → 0x08 → 0x0C → 0x10 → 0x14**

    0x1C 다음에 0x20이 아니라 블록 처음(0x00)으로 돌아간다.

### Q4. HRESP

Subordinate가 ERROR를 1 cycle만 줬다 (HRESP=ERROR, HREADYOUT=1). 왜 스펙 위반인지 한 줄로 설명하라.

??? success "정답"
    **1-cycle ERROR는 HREADY=1과 같은 edge에 다음 transfer의 주소까지 확정돼 버려서, Manager가 그 transfer를 취소할 기회가 없다. 원인은 pipeline이다.**


### Q5. Interconnect

Sub0이 wait 중(HREADYOUT0=0)이고, 그 cycle에 Sub1으로 가는 NONSEQ가 address phase에 있다 (HSEL1=1).

(a) Sub1은 이 cycle 끝에 주소를 저장해야 하나?
(b) 이때 mux는 누구의 HRDATA/HRESP/HREADYOUT을 고르고 있나?

??? success "정답"
    **(a) 저장하지 않는다.** 판단 근거는 `HSEL1 && HREADY`다. HSEL1=1이어도 HREADY=0이라 저장하지 않는다. 기다리는 이유는 AHB에 outstanding이 없어서다.

    **(b) Sub0.** mux_sel은 data phase 중인 Sub0에 머물러 있고, HREADY=0인 동안에는 갱신되지 않는다.
