# Unit 2 — AXI (그 벽을 깨는 버스)

> 핵심 질문: AHB는 왜 GPU↔DDR 같은 고대역폭 경로에서 *대역폭의 2~3%밖에* 못 내고 죽나? 그 한계의 정체는 무엇이고, AXI는 **채널 분리 + VALID/READY + ID**라는 세 장치로 그걸 어떻게 푸나? 그리고 그 자유(outstanding/out-of-order)를 풀어주면서 **데드락·순서·데이터 정렬**은 어떤 규칙으로 잡나?
>
> ※ 이 단원을 읽으며 나온 세부 질문(AHB 복제로 안 되나, write도 중간에 깨지잖아, WID 삭제 이유, interleave vs reorder, READY의 구현 자유, AxREGION 등)은 별도 페이지 **`amba-unit2-qa.md`** 에 던진 순서대로 정리돼 있다.

## 0. 핵심 한 문장

> **AXI = "주소·데이터·응답을 따로따로 흐르는 독립 채널로 쪼개고, 각 채널을 VALID/READY 핸드셰이크로 굴리며, ID로 트랜잭션을 구분"하는 버스.** 이 세 가지(채널 분리 + VALID/READY + ID)가 합쳐져서, AHB가 못 했던 *다중 outstanding*과 *out-of-order*가 비로소 가능해진다. Unit 1이 끝난 자리("APB·AHB는 single outstanding, ID 없음, 전부 in-order")가 바로 AXI의 출발점이다.

---

## 1. 왜 AXI인가 — AHB가 GPU↔DDR에서 "죽는다"

Unit 1에서 AHB의 벽을 "single outstanding"이라고 한 줄로 정리했다. 그게 **왜 치명적인지**는 숫자로 봐야 실감이 온다.

### 1-1. DRAM은 "느리고(latency) 굵다(bandwidth)"

DRAM의 두 성질을 분리해서 봐야 한다:

```text
latency(지연):    요청 → 첫 데이터까지   ≈ 수십~100 ns   (느리다)
bandwidth(대역폭): 일단 흐르기 시작하면    ≈ 수십 GB/s     (굵다)
```

문제는 이 둘이 **따로 논다**는 것. DRAM은 "한참 뜸들이다가(latency), 일단 시작하면 폭포처럼 쏟아내는(bandwidth)" 장치다. 폭포를 다 받으려면 **뜸들이는 동안에도 다음 요청을 계속 던져놔야** 한다.

### 1-2. Little's Law — 파이프를 채우려면 몇 개를 띄워야 하나

AXI 설계 전체를 관통하는 한 줄:

```text
파이프 안에 떠 있어야 하는 데이터량 = 대역폭 × 지연
                  (bandwidth-delay product, BDP)
```

고속도로 비유: 차선이 아무리 넓어도(대역폭), 톨게이트~목적지가 멀면(지연) **그 사이 도로를 가득 메울 만큼 차를 계속 들여보내야** 차선이 꽉 찬다. 한 대 보내고 도착할 때까지 기다리면, 16차선 고속도로에 차 한 대만 굴러다니는 꼴.

**구체적 숫자로:**

```text
목표: GPU가 DDR에서 25.6 GB/s 로 읽고 싶다
DDR read latency ≈ 100 ns

필요한 in-flight 데이터 = 25.6 GB/s × 100 ns = 2560 byte 가 항상 떠 있어야 함
```

이제 AHB로 이걸 해보면:

```text
AHB single outstanding: 한 번에 떠 있는 건 "버스트 딱 하나"
AHB 최대 버스트 = 16 beat × 4 byte(32bit 버스) = 64 byte

→ 64 byte 보내고 응답(100ns) 다 기다린 뒤에야 다음 64 byte
→ 유효 대역폭 = 64 byte / 100 ns = 0.64 GB/s

         0.64 GB/s  /  25.6 GB/s  ≈  2.5%
         ───────────────────────────────
         DDR 대역폭의 2.5%만 쓰고 나머지 97.5%는 버스가 노는 중
```

**이게 "AHB가 GPU↔DDR에서 죽는다"의 정체다.** 버스가 느려서가 아니라, *한 번에 하나만 띄울 수 있어서* latency를 bandwidth로 가리질 못한다. 파이프에 2560바이트를 채워야 하는데 64바이트만 넣고 응답을 기다리니까.

### 1-3. 그럼 뭘 바꿔야 하나 (AXI의 3대 결정)

위 숫자를 25.6 GB/s로 끌어올리려면 **2560 / 64 ≈ 40개의 버스트를 동시에 떠 있게** 해야 한다.

| 필요한 것 | 왜 | AXI의 장치 |
|---|---|---|
| 응답 안 기다리고 다음 주소 던지기 | 40개를 미리 쏴놔야 파이프가 참 | **채널 분리** (주소를 데이터/응답에서 떼어냄) |
| 보내는 쪽·받는 쪽 둘 다 자기 페이스로 | 채널이 따로 흐르려면 각자 멈출 수 있어야 | **VALID/READY** (양방향 핸드셰이크) |
| 40개가 뒤섞여 돌아와도 누구 건지 구분 | 빨리 된 것부터 받으려면(out-of-order) 이름표 필요 | **ID** (AWID/ARID/BID/RID) |

> **(참고)** "AHB를 여러 개 깔면 안 되나?"는 자연스러운 반론이고, ARM도 Multi-layer AHB로 해봤다. 왜 그게 이 문제를 못 푸는지는 → Q&A Q1.

> **한 줄:** AHB는 "한 대 보내고 도착할 때까지 기다리는" 버스라 BDP를 못 채운다. AXI는 **채널을 떼어 40대를 동시에 도로에 풀고(채널분리+outstanding), 각 차에 번호판을 붙여(ID) 도착 순서가 뒤바뀌어도(out-of-order) 정리**한다. 이 세 가지가 Unit 2 전부의 뼈대다.

---

## 2. AXI의 첫 번째 결정 — 채널을 5개로 쪼갠다

AHB는 주소 phase·데이터 phase가 `HREADY` 하나로 묶여 한 박자씩만 어긋났다. AXI는 묶여 있는 걸 풀어, 주소와 데이터를·read와 write를 **각자 독립된 통로(채널)로 분리**한다. 5개 채널이다.

```text
                    ┌──────────── WRITE ────────────┐
   ┌────────┐  AW   │ 주소·길이·ID·burst·size·prot…  │  ──►  ┌────────┐
   │        │───────┼────────────────────────────────┤       │        │
   │ MASTER │  W    │ 데이터·WSTRB·WLAST              │  ──►  │ SLAVE  │
   │        │───────┼────────────────────────────────┤       │        │
   │ (GPU)  │  B    │ 응답(OKAY/SLVERR/DECERR)·BID    │  ◄──  │ (DDR)  │
   │        │       └────────────────────────────────┘       │        │
   │        │  ┌──────────── READ ─────────────┐             │        │
   │        │  │ AR  주소·길이·ID·burst·size…   │  ──►        │        │
   │        │──┼───────────────────────────────┤             │        │
   │        │  │ R   데이터·resp·RID·RLAST      │  ◄──        │        │
   └────────┘  └───────────────────────────────┘             └────────┘
```

- **AW / W / B** — 쓰기 3종: 주소 채널 / 데이터 채널 / 응답 채널.
- **AR / R** — 읽기 2종: 주소 채널 / 데이터+응답 채널. (read는 응답이 데이터에 실려 와서 별도 B가 없음)

핵심은 **이 5개가 서로 독립적으로 흐른다**는 것:

```text
AHB:  주소─데이터─응답이 HREADY 하나로 묶임 → 한 박자에 다 같이 전진
AXI:  AW가 막혀도 AR은 흐른다. W 데이터를 보내는 중에 다음 AW 주소를 또 보낸다.
      → read 채널과 write 채널이 완전히 따로 논다 (동시에 읽고 쓰기 가능)
```

---

## 3. 5채널 구조 (신호)

방향 표기: 모든 채널에서 정보를 **보내는 쪽이 `xVALID`**, 받는 쪽이 `xREADY`.

**AW — Write Address** (M→S)
| 신호 | 설명 |
|---|---|
| `AWADDR` | 버스트 **시작** 주소 |
| `AWID` | 트랜잭션 식별자 (ordering의 핵심) |
| `AWLEN` | 버스트 beat 수 − 1 (AXI4: 0~255 → 1~256 beat) |
| `AWSIZE` | beat당 byte = 2^AWSIZE |
| `AWBURST` | FIXED / INCR / WRAP |
| `AWLOCK` | normal / exclusive |
| `AWCACHE` `AWPROT` `AWQOS` `AWREGION` | 메모리 속성·보호·우선순위·영역 |
| `AWVALID`/`AWREADY` | 핸드셰이크 |

**W — Write Data** (M→S)
| 신호 | 설명 |
|---|---|
| `WDATA` | 쓰기 데이터 |
| `WSTRB` | byte별 유효 마스크 (1비트/byte lane) |
| `WLAST` | 이 beat가 버스트의 **마지막**임 |
| `WVALID`/`WREADY` | 핸드셰이크 |

> AXI4의 W 채널엔 **ID가 없다.** (AXI3엔 `WID`가 있었음) → 삭제 이유는 §4-4 / Q&A Q4·Q5.

**B — Write Response** (S→M)
| 신호 | 설명 |
|---|---|
| `BID` | 어느 write의 응답인지 (AWID와 매칭) |
| `BRESP` | OKAY / EXOKAY / SLVERR / DECERR |
| `BVALID`/`BREADY` | 핸드셰이크 |

> write는 응답이 **버스트당 하나(B 한 번)**. 데이터 16 beat를 써도 B는 한 번만 온다.

**AR — Read Address** (M→S) — AW와 신호 구성 동일(`ARADDR`/`ARID`/`ARLEN`…).

**R — Read Data** (S→M)
| 신호 | 설명 |
|---|---|
| `RDATA` | 읽은 데이터 |
| `RID` | 어느 read의 데이터인지 (ARID와 매칭) |
| `RRESP` | beat마다 응답 (OKAY/EXOKAY/SLVERR/DECERR) |
| `RLAST` | 버스트의 **마지막** beat |
| `RVALID`/`RREADY` | 핸드셰이크 |

> read는 응답이 **데이터에 실려서**(`RRESP`) 온다. 그래서 read엔 B 같은 별도 응답 채널이 없다 — 채널이 2개(AR/R)인 이유.

---

## 4. 왜 이렇게 설계되었나

구조만 외우면 안 된다. 각 결정엔 이유가 있다.

### 4-1. 왜 주소와 데이터를 분리했나

AW와 W를 완전히 독립시켜서:

```text
AW: ───[A0][A1][A2][A3][A4]...        ← 주소를 응답 안 기다리고 연달아
W :        [D0..][D1..][D2..]...      ← 데이터는 데이터대로 자기 페이스
            └ AW와 박자가 안 묶임. 주소가 데이터보다 한참 앞서갈 수 있음
```

→ §1의 "40개 미리 던지기"가 이래서 가능. AW 채널만 따로 빨리 돌리면 outstanding이 쌓인다.

### 4-2. 왜 read와 write를 별도 채널로

AHB는 read/write가 같은 데이터선·같은 `HREADY`를 공유 → 읽는 동안 못 쓰고, 쓰는 동안 못 읽음. AXI는 **AR/R(읽기)과 AW/W/B(쓰기)가 물리적으로 다른 채널** → **full-duplex**. GPU가 텍스처를 읽으면서 동시에 렌더 결과를 쓰는 게 한 버스에서 동시 진행된다.

### 4-3. 왜 write 응답(B)은 버스트당 하나인데, read 응답(RRESP)은 beat마다인가

갈리는 건 **데이터가 흐르는 방향**이다.

```text
READ : 데이터가 slave→master로 돌아온다. master가 돌아온 word를 "쓸지/버릴지"
       판단해야 하므로 검증 도장(RRESP)이 word마다 붙어야 한다.
       게다가 응답이 데이터와 같은 방향(S→M)이라 beat마다 공짜로 얹힌다.
WRITE: 데이터가 master→slave로 나간다. master로 돌아오는 데이터가 없으니
       beat 단위로 할 게 없다 — "이 write 통째로 성공? 실패?" 한 줄이면 충분.
       게다가 응답이 데이터와 반대 방향이라 얹힐 수 없어, WLAST 뒤 요약 한 번이 된다.
```

`BRESP`는 **버스트 전체의 종합 결과(worst-case)** 다. 한 beat라도 깨지면 SLVERR를 띄우되, 어느 beat인지는 알려주지 않는다(알아도 master가 못 쓰니까). write가 중간 beat에서 깨질 수 있는데도 B가 하나뿐인 이유 → Q&A Q2·Q3.

### 4-4. 왜 AXI4는 WID를 없앴나

AXI3엔 `WID`가 있어 **write data interleaving**(서로 다른 write의 데이터 beat를 뒤섞어 보내기)이 가능했다.

```text
AXI3 (interleaving):
WDATA :  X0   Y0   X1   Y1   X2   Y2     ← X와 Y의 beat가 번갈아
WID   :  1    2    1    2    1    2      ← 매 beat "누구 데이터" 라벨 필요
```

얻는 것(W 채널 빈틈 메우기)은 거의 안 쓰는 자유인데, 비용(slave가 매 beat WID 읽고 분류·재조립)은 크다. AXI4는 **"write 데이터는 AW 던진 순서대로 한 버스트씩 끊김 없이"** 로 규칙을 굳히고 `WID`를 삭제했다. **순서를 이름표 삼으니 라벨이 필요 없어진 것.** (자세히는 Q&A Q4)

> **핵심 직관:** AXI 설계의 모든 선택은 "**값진 자유는 풀고, 안 쓰는 자유는 도로 닫는다**"는 균형 위에 있다. 채널 분리/outstanding/out-of-order는 풀고(가치 큼), write interleaving은 닫았다(가치 작고 비쌈).

---

## 5. Handshake + 데드락 방지 규칙

5채널 전부 **동일한 VALID/READY 한 쌍**으로 굴러간다.

```text
전송 1건 성립 = 클럭 상승 에지에서  xVALID=1 AND xREADY=1
```

### 5-1. 핸드셰이크 3대 불변 규칙

```text
① VALID는 한번 올리면, 핸드셰이크(VALID&READY) 성립 전까지 내릴 수 없다.
② VALID일 때 실린 정보(주소/데이터)도 핸드셰이크 전까지 바뀌면 안 된다.
③ ★VALID는 READY를 기다려서 올리면 안 된다★ (데드락 방지의 핵심)
   반대로 READY는 VALID를 보고 올려도 되고, 안 보고 미리 올려도 된다.
```

### 5-2. ③번이 왜 데드락을 막나

데드락은 **둘 다 서로를 기다릴 때만** 생긴다:

```text
master: "네가 READY 올리면 나 VALID 올릴게"
slave : "네가 VALID 올리면 나 READY 올릴게"   → 둘 다 영원히 0. 교착. 💀
```

그래서 AXI는 **비대칭**을 강제한다. VALID는 READY를 절대 안 기다린다(상대 무시하고 무조건 올림). 그러면 READY가 VALID를 기다리든 말든 순환 고리가 끊겨 교착이 안 난다. → **꼭 필요한 최소한(VALID)만 묶고 READY는 자유**. 받는 쪽은 "항상 READY(빠름)" ↔ "버퍼 보고 READY(안전/저비용)"를 골라 latency·면적을 트레이드오프할 수 있다. (READY의 구현 자유 → Q&A Q7)

### 5-3. 채널 간 의존성 규칙 (진짜 데드락의 무대)

채널 하나 안보다 **채널들 사이** 의존이 더 위험하다.

```text
WRITE 쪽:
  • master는 AWVALID/WVALID 를 slave의 AWREADY/WREADY 와 무관하게 올려야 함
  • slave는 AW 와 W 를 다 받기 전엔 BVALID 못 올림 (다 써야 응답)
READ 쪽:
  • slave는 AR 핸드셰이크 전엔 RVALID 못 올림 (주소를 받아야 데이터를 냄)
```

가장 흔한 실전 데드락: slave가 "AW 먼저 받아야 W 받겠다"고 WREADY를 AWVALID에 묶었는데, master가 "W 먼저 다 보내고 AW 보낼게" 하는 순간 교착. → AW/W 순서 의존을 집요하게 찌르는 게 검증 핵심.

> **한 줄:** VALID/READY는 "둘 다 1인 에지에 성립"이 전부지만, **VALID가 READY를 기다리지 않는다**는 비대칭이 데드락을 원천 봉쇄한다. 진짜 함정은 *채널 사이* 의존(AW↔W↔B)이라, 거기에 순환이 없게 설계·검증하는 게 핵심.

---

## 6. Burst / WSTRB / Narrow transfer (데이터 계층)

### 6-1. 버스트 정의 3총사

```text
AxLEN  : beat 수 − 1   → 실제 beat 수 = AxLEN + 1
         AXI4: INCR은 1~256 beat (AxLEN 8비트), WRAP/FIXED는 1~16
         AXI3: 전부 1~16 (AxLEN 4비트)
AxSIZE : beat당 byte = 2^AxSIZE   (버스 폭 이하)
AxBURST: 00=FIXED  01=INCR  10=WRAP
```

### 6-2. 세 가지 버스트 타입

```text
FIXED : 주소 고정. 매 beat 같은 주소.        → FIFO/포트 레지스터에 연속 쓰기
INCR  : 주소가 AxSIZE만큼 계속 증가.          → 일반 메모리 접근 (가장 흔함)
WRAP  : 블록 안에서 돌고 경계서 되돌아옴.     → 캐시 라인 fill (critical-word-first)
```

> WRAP 주소 계산은 Unit 1 §5 그대로 (블록 = size×len으로 정렬, 출발이 블록 중간일 때만 wrap이 보임).

### 6-3. ★4KB 경계 규칙★ (AXI에서 제일 자주 터지는 룰)

```text
하나의 버스트는 4KB(0x1000) 경계를 절대 넘을 수 없다.
```

**왜?** 인터커넥트의 주소 디코딩 단위(페이지)가 보통 4KB라, 버스트가 경계를 넘으면 한 버스트가 두 slave에 걸쳐 라우팅 불능 + 보호/캐시 속성도 페이지 단위라 섞인다.

```text
AWADDR=0x0FF0, AWLEN=15(16beat), AWSIZE=2(4byte) 라면?
  마지막 주소 = 0x0FF0 + 15×4 = 0x102C  → 0x1000 경계 넘음 ❌ 위반!
  → master/인터커넥트가 0x0FF0~0x0FFC / 0x1000~ 로 쪼개 보내야 함
```

### 6-4. WSTRB — byte 단위 부분 쓰기

`WDATA`는 버스 폭(예: 4byte) 전체지만, 그중 **실제로 쓸 byte만** `WSTRB` 비트로 켠다.

```text
32bit 버스, 주소 0x02 에 1 byte(0xAB) 쓰기:
WDATA  = 0x__AB____   (lane2에 데이터)
WSTRB  = 0b0100       (lane2만 1 → 그 byte만 메모리 반영, 나머지 무시)
          3210
```

read엔 WSTRB 없음(다 읽으니까). strobe 안 켠 lane의 WDATA는 don't-care.

### 6-5. Narrow transfer — beat가 버스보다 좁을 때

`AxSIZE < 버스폭`이면 데이터가 버스의 **일부 lane**에만 실린다. 어느 lane이냐는 **주소와 버스트 타입**이 정한다.

```text
64bit 버스(8 lane), AxSIZE=1(2byte/beat), INCR, 시작주소 0x0
beat0  주소0x0 → lane[1:0]
beat1  주소0x2 → lane[3:2]   ← 주소 따라 lane이 옮겨감
beat2  주소0x4 → lane[5:4]
beat3  주소0x6 → lane[7:6]

같은 걸 FIXED로 하면 → 매 beat lane[1:0] 고정 (주소 안 변하니까)
```

→ 좁은 IP를 넓은 버스에 붙일 때 발생. narrow+unaligned에서 lane 정렬 계산이 꼬이기 쉬워 검증 단골.

---

## 7. Read / Write 사이클 예시 (채널 위에서 추적)

### 7-1. Read 버스트 1개 (INCR, 4 beat)

`ARADDR=0x100, ARLEN=3, ARSIZE=2(4byte), ARID=5`

```text
        T1    T2    T3    T4    T5    T6    T7
        ── AR 채널 ──
ARVALID  /‾‾‾‾\
ARREADY  /‾‾‾‾\
ARADDR   <0x100>
ARID     < 5  >
                  ── R 채널 (slave가 데이터 흘림) ──
RVALID         /‾‾‾‾‾‾‾‾‾‾\__/‾‾‾‾\
RREADY    /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
RID            < 5  ><5 ><5 >   < 5 >
RDATA          <D0 ><D1><D2>   <D3 >
RLAST          0    0   0       1     ← 마지막 beat 표시
RRESP          OK   OK  OK      OK
                              ↑ T5 RVALID=0: slave가 잠깐 못 냄(자기 페이스)
```

- T1: **AR 한 번**으로 버스트 전체(주소+길이)를 기술.
- T2~: slave가 R 채널로 데이터를 흘림. `RVALID&RREADY` 성립 에지마다 1 beat.
- T5: slave가 `RVALID=0`으로 잠깐 멈춤 — VALID/READY라 가능. `RLAST=1`로 끝.

### 7-2. Write 버스트 1개 (INCR, 4 beat)

`AWADDR=0x200, AWLEN=3, AWID=7`

```text
        T1    T2    T3    T4    T5    T6
        ── AW 채널 ──
AWVALID  /‾‾‾‾\
AWREADY  /‾‾‾‾\
AWADDR   <0x200>
AWID     < 7  >
        ── W 채널 ──
WVALID        /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
WREADY        /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
WDATA         <D0 ><D1 ><D2 ><D3 >
WSTRB         <1111 모두 유효 ...  >
WLAST         0    0    0    1      ← 마지막 데이터 beat
        ── B 채널 (응답은 버스트당 1번) ──
BVALID                        /‾‾‾‾\
BREADY                        /‾‾‾‾\
BID                           < 7  >
BRESP                         < OK >
```

- AW(주소 1번) + W(데이터 4 beat, `WLAST`로 끝) + **B(응답 1번)**.
- B는 데이터를 다 받은 뒤 한 번. `BID=7`로 어느 write였는지. W 데이터엔 ID 없음 → "AW 순서대로 한 버스트씩" 규칙(§4-4)으로 매칭.

---

## 8. ID 기반 Ordering + Outstanding + Out-of-order

### 8-1. 단 하나의 황금률

```text
같은 ID 끼리는 순서 보장(in-order).   다른 ID 끼리는 순서 보장 없음(reorder 가능).
```

```text
같은 ARID로 read 3개 → 데이터는 반드시 던진 순서로 돌아온다 (in-order)
다른 ARID(5,6,7)로 read 3개 → 7번이 제일 먼저 와도 됨 (out-of-order)
```

### 8-2. Outstanding — 응답 전에 계속 던지기

```text
ARVALID  /‾\/‾\/‾\/‾\          ← 주소 4개를 응답 안 기다리고 연달아 (outstanding=4)
RVALID              /‾\/‾\…    ← 데이터는 한참 뒤에 돌아오기 시작
```

§1의 BDP 문제가 이걸로 풀린다. AR을 40번 미리 쏴서 파이프를 채우면 DDR 대역폭을 다 쓴다. **outstanding 깊이 = ID 추적 버퍼 크기**가 한계.

### 8-3. Out-of-order — 빨리 된 것부터 받기

```text
master가 던진 순서:  ARID=5(느린 DRAM) → ARID=6(빠른 SRAM)
돌아오는 순서:       RID=6 데이터 먼저!  →  RID=5 데이터 나중
                    └ 6번이 5번을 안 기다림. 느린 놈이 빠른 놈 발목 안 잡음
```

AHB는 느린 slave 하나가 버스 전체를 잡았지만(Unit 1 §4-7), AXI는 ID만 다르면 추월 가능.

### 8-4. 같은 ID를 쓰는 이유 (왜 안 그냥 전부 다른 ID?)

```text
write 0x100 → read 0x100  을 서로 다른 ID로 보내면?
  → out-of-order 허용이라 read가 write를 추월 → 옛날 값 읽음 (버그!)
→ 순서가 지켜져야 하는 트랜잭션은 같은 ID로 묶고, 독립인 것만 다른 ID로 풀어 추월 허용.
```

ID는 "추월해도 되는 트랜잭션 그룹"을 master가 선언하는 수단이다.

### 8-5. Interleaving — AXI3 vs AXI4

여기서 **interleave(beat 잘게 섞기)** 와 **reorder(버스트 단위 순서 바꾸기)** 를 구분해야 한다.

```text
interleave (beat 단위로 다른 트랜잭션을 번갈아):
  AXI3: read·write 둘 다 허용
  AXI4: read·write 둘 다 제거 — 한 버스트 데이터는 끊김 없이 연속

reorder (버스트 통째로, 순서만 바뀜):
  read: ARID로 허용 (남김) — 돌아오는 타이밍을 master가 못 정하니 값짐
  write 데이터: 불필요 — master가 보내는 순서를 직접 정하니까
```

> AXI4의 reorder는 **다른 ID의 "버스트끼리"** 만 뒤바뀐다. 한 버스트의 beat들은 항상 연속·in-order. (write가 WID 삭제, read가 RID 유지인 비대칭의 근거 → Q&A Q4·Q5·Q6)

> **한 줄:** ID = "추월 허가증". 같은 ID는 줄 서고(in-order), 다른 ID는 추월 OK(out-of-order). outstanding으로 파이프를 채우고, out-of-order로 느린 놈이 빠른 놈을 막지 않게 한다. 단 AXI4는 *버스트 단위* 추월만 — beat 인터리빙은 닫았다.

---

## 9. Exclusive Access (락 없는 원자적 연산)

멀티코어에서 세마포어/atomic을 하려면 "읽고-수정하고-쓰는 사이 아무도 못 끼게" 해야 한다. 옛날엔 버스를 통째로 잠갔지만(locked, AXI3), AXI4는 **exclusive**로 한다 — 버스를 안 잠그고도 원자성 보장.

```text
패턴 (LL/SC, load-linked / store-conditional 방식):

① Exclusive Read  (AxLOCK=exclusive)  주소 0x100 읽음 → slave가 "감시 시작"
② (그 사이 다른 master가 0x100에 쓰면 → 감시 깨짐)
③ Exclusive Write (AxLOCK=exclusive)  주소 0x100에 씀
     ├ 그 사이 아무도 안 건드림 → BRESP=EXOKAY (성공! 원자적이었음)
     └ 누가 건드림            → BRESP=OKAY   (실패! 다시 시도해야)
```

- **버스를 잠그지 않음** → 그동안 다른 트랜잭션도 진행 가능 (성능 유지).
- 실패하면 SW가 재시도(루프). lock-free atomic의 토대.

**제약 (검증 포인트):** exclusive read/write는 **같은 ID·같은 주소·같은 크기**, 바이트 수는 2의 거듭제곱(1~128), 주소는 그 크기로 정렬, 최대 16 beat. `EXOKAY`(01)는 exclusive 성공 시에만 — 일반 접근엔 절대 안 뜬다.

---

## 10. Cache / Prot / QoS / Region (속성 신호들)

주소·데이터 외에 "이 트랜잭션을 어떻게 다뤄라"를 알려주는 사이드밴드 신호들.

### 10-1. AxCACHE [3:0] — 메모리 속성

```text
bit0 Bufferable   : 중간 버퍼(write buffer)에 담았다 나중에 써도 됨
bit1 Modifiable/Cacheable : 트랜잭션을 쪼개/합쳐도 됨 (캐시 가능)
bit2 Read-Allocate
bit3 Write-Allocate
```

→ "Device 메모리(순서 엄격, 버퍼 금지)냐, Normal 메모리(캐시·재배열 OK)냐"를 구분. 인터커넥트/캐시가 최적화 판단에 쓴다.

### 10-2. AxPROT [2:0] — 보호 속성

```text
bit0  0=unprivileged 1=privileged   (특권 레벨)
bit1  0=secure       1=non-secure   (TrustZone 보안)
bit2  0=data         1=instruction  (명령/데이터)
```

→ slave가 "이 접근 권한 있나" 판단. 위반 시 SLVERR/DECERR.

### 10-3. AxQOS [3:0] — 우선순위 힌트 (AXI4 신규)

```text
0~15 우선순위. 인터커넥트가 여러 master 경쟁 시 높은 QoS를 먼저 스케줄.
"힌트"일 뿐 강제 아님. GPU 디스플레이(끊기면 화면 깨짐)에 높은 QoS 주는 식.
```

### 10-4. AxREGION [3:0] — 영역 식별자 (AXI4 신규)

인터커넥트가 주소를 디코딩할 때 **"너의 몇 번 영역이야"** 라는 번호(0~15)를 같이 붙여 보낸다. 한 slave 안에 영역이 여러 개라도 slave가 긴 주소를 다시 까지 않고 번호만 보고 안다 — **디코딩 중복을 없애는** 신호.

```text
인터커넥트:  주소 0x4_2000 → UART slave + AWREGION=1 (레지스터 영역)
UART slave:  "REGION=1이네, 레지스터 영역" ← 번호만 보고 끝. 주소 재디코딩 X
```

(택배에 "3층 영업부" 라벨을 우체국이 미리 붙여주는 셈. 자세히는 Q&A Q8)

### 10-5. 응답 코드 4종 (RRESP/BRESP)

```text
00 OKAY    정상
01 EXOKAY  exclusive 성공 (§9)
10 SLVERR  slave 에러 (주소는 맞는데 내부 실패: 권한, 미지원 등)
11 DECERR  decode 에러 (그 주소에 slave가 아예 없음 — 인터커넥트가 응답)
```

---

## 핵심 정리

- **왜 AXI:** AHB는 single outstanding이라 BDP(대역폭×지연)를 못 채워 GPU↔DDR에서 대역폭 2~3%만 쓴다. latency를 가리려면 수십 개를 동시에 띄워야 한다.
- **채널 5개:** AW/W/B(쓰기) + AR/R(읽기). 주소·데이터·응답을 떼고, read·write를 떼서 독립적으로 흐른다(full-duplex + outstanding).
- **VALID/READY:** 5채널 공통 핸드셰이크. **VALID는 READY를 안 기다린다**(비대칭)는 규칙 하나가 데드락 고리를 끊는다. READY는 자유.
- **ID:** 같은 ID = in-order, 다른 ID = reorder 가능. outstanding(파이프 채우기) + out-of-order(추월). 순서 지킬 건 같은 ID로 묶는다.
- **AXI4 정리:** WID 삭제(write interleaving 제거 — 순서를 라벨 삼음), AxQOS·AxREGION 추가, exclusive로 locked 대체. "값진 자유는 풀고 안 쓰는 자유는 닫는다."
- **데이터 계층:** AxLEN/SIZE/BURST, **4KB 경계 절대 불가침**, WSTRB(byte 부분 쓰기), narrow transfer(좁은 beat의 lane 배치).
- **방향이 응답을 가른다:** read는 응답이 데이터와 같은 방향이라 beat마다(RRESP), write는 반대 방향이라 버스트당 한 번(BRESP, worst-case 요약).
- **exclusive:** 버스 안 잠그고 EXOKAY/OKAY로 원자성. lock-free atomic의 토대.

---

## 🔌 검증 관점

- **핸드셰이크 불변식:** `VALID` 올린 뒤 핸드셰이크 전 내림/페이로드 변경, `VALID`가 `READY`를 기다림(③ 위반) → 데드락.
- **채널 간 의존 데드락:** AW↔W↔B 순환 의존(slave가 AW 먼저 안 받으면 WREADY 안 줌 + master가 W 먼저 보냄), B를 W 완료 전에 띄움.
- **4KB 경계:** 버스트가 0x1000 경계 침범, 경계서 쪼개기 누락, 쪼갠 두 조각의 ID/순서.
- **ID ordering:** 같은 ID인데 out-of-order 응답(위반), 다른 ID인데 인터커넥트가 불필요하게 in-order로 묶음(성능), RID/BID가 AR/AW ID와 안 맞음.
- **Outstanding/OoO:** outstanding 깊이 초과 시 거동, 느린 ID가 빠른 ID 추월 정상 동작, ID 추적 버퍼 overflow.
- **Interleaving (AXI4):** read 버스트 beat가 다른 ID와 뒤섞임(AXI4 위반), write 데이터가 AW 순서 위반.
- **Burst/WSTRB/Narrow:** `WLAST`/`RLAST` 위치 오류(beat 수와 불일치), `WSTRB`와 `AxSIZE` 불일치, narrow transfer의 lane 정렬, FIXED인데 주소 증가.
- **Exclusive:** 제약 위반(크기/정렬/ID 불일치) 시 거동, 감시 깨짐 판정, EXOKAY가 일반 접근에 뜸.
- **응답:** 없는 주소에 DECERR 안 뜸, SLVERR/DECERR 혼동, read 버스트 중간 beat 에러 표시.
- **공통:** reset 직후 첫 트랜잭션, full-duplex(읽기·쓰기 동시) 시 상호 간섭, VALID/READY가 X일 때 FSM 오염.

---

→ 이 단원을 보며 나온 모든 세부 질문과 답은 **`amba-unit2-qa.md`** 참고.
