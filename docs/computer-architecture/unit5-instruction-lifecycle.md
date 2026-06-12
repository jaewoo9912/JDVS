# Unit 5 — 명령 한 줄의 일생 (The Life of an Instruction)

> 핵심 질문: `add x1,x2,x3` 한 줄이 실행되며 칩 안에서 무슨 일이 일어나나? (fetch → decode → execute → mem → writeback)

## 0. 한 문장으로 시작하는 큰 그림

> CPU는 결국 **거대한 무한 루프** 하나다.
> `PC가 가리키는 곳에서 명령어를 꺼내 → 해석 → 실행 → 상태 갱신 → PC 전진 → 반복`

이 루프를 **instruction cycle (명령 주기)** 라고 부른다. 우리가 쪼개는 5단계는 이 한 바퀴를 시간순으로 자른 것이다.

```text
   ┌─────────────────────────────────────────────┐
   │                                             │
   ▼                                             │
 [IF] ──► [ID] ──► [EX] ──► [MEM] ──► [WB] ──────┘
 Fetch    Decode   Execute   Memory   WriteBack
 가져옴    해석      계산       메모리     결과 저장
```

핵심 통찰: **이 5단계는 "물리적 회로 블록"이 아니라 "한 명령어가 거쳐가는 논리적 일(work)의 분류"다.** 어떤 CPU는 이걸 1 클럭에 다 하고(single-cycle), 어떤 건 단계마다 1 클럭씩 쓰고(multi-cycle), 어떤 건 5개를 겹쳐서 동시에 굴린다(pipeline, Unit 8). 하지만 **일의 본질은 항상 이 5개**다.

## 1. 무대 위의 배우들 — Datapath 부품

| 부품 | 역할 | 어디서 봤나 |
|---|---|---|
| **PC** (Program Counter) | 다음에 실행할 명령어의 주소를 담은 특수 레지스터 | Unit 4 |
| **Instruction Memory** | 프로그램(명령어)이 들어있는 메모리 | Unit 4 |
| **Register File** | 32개(RISC-V)의 범용 레지스터. 2개 읽고 1개 쓰기 가능 | Unit 4 |
| **ALU** | 실제 산술/논리 계산 | Unit 2 |
| **Data Memory** | load/store가 접근하는 데이터 메모리 | Unit 4 |
| **Control Unit** | 명령어를 보고 "어느 부품을 어떻게 쓸지" 신호를 뿌리는 지휘자 | 이번 유닛 |
| **Immediate Generator** | 명령어에 박힌 상수를 뽑아 부호확장 | Unit 3 (2의 보수) |

> **DV 메모**: 이 표가 곧 **아키텍처 상태(architectural state)** 와 **마이크로아키텍처 상태**의 경계다. PC / Register File / Data Memory — 이 셋은 소프트웨어가 볼 수 있는 *architectural state*. 검증할 때 "정답"을 체크하는 지점이 바로 여기다. 나머지(ALU 내부 wire, control 신호)는 *microarchitectural*, 즉 중간 과정. 스코어보드는 보통 architectural state를 비교한다.

## 2. 5단계 — 하나씩 디테일하게

명령어 `add x5, x6, x7` (= `x5 ← x6 + x7`)를 따라가며 본다.

### ① IF — Instruction Fetch (명령어 가져오기)

**하는 일:**
1. `PC` 값을 주소로 써서 **Instruction Memory**에 던진다.
2. 그 주소에 있는 32비트 명령어를 읽어온다 → `IR`(Instruction Register)에 담는다.
3. 동시에 **`PC + 4`** 를 계산한다. (RISC-V 명령어는 4바이트니까 다음 명령어는 +4)

```text
PC ──► [Instruction Memory] ──► instruction (32-bit)
PC ──► (+4) ──► PC_next 후보
```

**왜 +4를 여기서 미리 계산?** 대부분 명령어는 그냥 다음 줄로 가니까. 분기(branch)가 아니면 `PC ← PC+4`. 미리 계산해두면 빠르다.

> **DV 메모**: 검증 포인트 두 가지 — (a) PC가 정렬(alignment)되어 있나? RISC-V는 보통 4바이트 정렬. 비정렬 PC는 exception이어야 함. (b) instruction memory가 올바른 데이터를 주나? 이건 사실상 **read transaction** 검증 — RDMA에서 메모리 read 검증하는 것과 구조가 똑같다. 주소 in, 데이터 out, 잘못된 주소면 fault.

### ② ID — Instruction Decode & Register Read (해석 & 레지스터 읽기)

**하는 일 (병렬로 동시에):**

1. **Decode**: 32비트를 필드로 쪼갠다. RISC-V R-type 예:

```text
 31      25 24   20 19   15 14  12 11   7 6        0
┌──────────┬───────┬───────┬──────┬──────┬──────────┐
│  funct7  │  rs2  │  rs1  │funct3│  rd  │  opcode  │
└──────────┴───────┴───────┴──────┴──────┴──────────┘
   7비트     5비트   5비트   3비트  5비트    7비트
```

   - `opcode` + `funct3` + `funct7` → "이건 ADD이구나" 판단
   - `rs1=x6`, `rs2=x7`, `rd=x5` → 어떤 레지스터를 쓸지

2. **Register Read**: Register File에서 `rs1`, `rs2`가 가리키는 값을 읽는다. (`x6`, `x7`의 실제 값)

3. **Control 신호 생성**: Control Unit이 opcode를 보고 신호 뭉치를 만든다.
   - `ALUOp` = ADD
   - `RegWrite` = 1 (결과를 레지스터에 쓸 거다)
   - `MemRead/MemWrite` = 0 (메모리 안 건드림)
   - `ALUSrc` = 0 (두 번째 입력은 레지스터, immediate 아님)
   - 등등...

4. **Immediate 추출**(필요하면): I/S/B/U/J 타입은 명령어에 박힌 상수를 부호확장.

> **핵심 통찰**: Decode 단계의 산출물은 "값"이 아니라 **"이 명령어가 datapath를 어떻게 통과할지에 대한 설정(control word)"** 이다. 같은 ALU·메모리·레지스터 파일인데, control 신호가 다르면 완전히 다른 명령어가 된다. **명령어 = 데이터 + 그 데이터를 처리할 control 신호의 조합.**

> **DV 메모**: Decode는 검증에서 제일 버그 많이 나오는 곳이다. opcode/funct 조합이 수십~수백 개고, 그중 **정의 안 된 조합(illegal instruction)** 이 반드시 `illegal instruction exception`을 일으켜야 한다. coverage 짤 때 "모든 valid opcode를 다 디코드했나" + "illegal opcode를 던지면 trap 나나"를 둘 다 봐야 함. 전형적인 **valid/invalid input partition** + **negative test**.

### ③ EX — Execute (실행 / 계산)

**하는 일:** ALU가 실제 계산을 한다. 단, 무엇을 계산하느냐는 명령어 종류마다 다르다 — 여기가 명령어별로 가장 갈라지는 단계다.

| 명령어 종류 | EX 단계에서 ALU가 하는 일 |
|---|---|
| R-type (`add`) | `rs1 + rs2` (실제 산술) |
| I-type (`addi`) | `rs1 + immediate` |
| **Load** (`lw`) | `rs1 + offset` → **접근할 메모리 주소 계산** |
| **Store** (`sw`) | `rs1 + offset` → **저장할 메모리 주소 계산** |
| **Branch** (`beq`) | `rs1 - rs2` → 0이면 같다(taken), 그리고 분기 목적지 주소 `PC + imm` 계산 |

```text
add  x5,x6,x7  →  ALU: x6 + x7        = 결과값
lw   x5,8(x6)  →  ALU: x6 + 8         = 메모리 주소
beq  x6,x7,L1  →  ALU: x6 - x7 == 0?  = 분기 여부 판단
```

**중요한 통찰**: Load/Store에서 ALU는 "데이터 계산"이 아니라 **"주소 계산(address generation)"** 을 한다. 같은 덧셈기인데 쓰임새가 완전히 다르다. 이게 ALU가 범용 부품인 이유다.

> **DV 메모**: EX 단계는 Unit 3(수의 표현)가 와서 물리는 곳. **오버플로우, 부호/무부호, carry** 가 여기서 검증 대상. 또 주소 계산이 메모리 경계를 넘으면? 정렬 안 맞으면? 이런 corner가 다 EX에서 싹튼다. ALU는 **directed + random + corner(0, max, min, -1, overflow boundary)** 로 두들기는 전형적 대상.

### ④ MEM — Memory Access (메모리 접근)

**하는 일:** 메모리를 실제로 건드린다. **하지만 이 단계가 필요한 명령어는 load/store 뿐이다.**

| 명령어 | MEM 단계 |
|---|---|
| **Load** (`lw`) | EX에서 계산한 주소로 Data Memory **읽기** → 값 가져옴 |
| **Store** (`sw`) | EX에서 계산한 주소에 `rs2` 값 **쓰기** |
| add, addi, beq... | **아무것도 안 함 (그냥 통과)** |

```text
lw  x5, 8(x6)  →  주소=(x6+8) 에서 데이터 읽기 ──► 다음 단계로
sw  x5, 8(x6)  →  주소=(x6+8) 에 x5 쓰기 ──► (끝)
add x5, x6, x7 →  (no-op, skip)
```

**왜 단계를 따로 뒀나?** 메모리 접근은 ALU 연산보다 **느리고**, 모든 명령어가 쓰는 게 아니니까. 이걸 별도 단계로 분리하면 pipeline에서 깔끔하게 겹칠 수 있다(Unit 8 예고편).

> **DV 메모**: 여기가 홈그라운드 — **memory transaction 검증**. read/write, alignment(`lw`는 4바이트 정렬, `lh`는 2바이트...), 비정렬 접근 시 exception, load/store가 같은 주소를 건드릴 때의 순서(Unit 13 메모리 일관성으로 확장). RDMA TB에서 하던 MR(memory region) 접근 검증의 CPU 버전.

### ⑤ WB — Write Back (결과 되돌려쓰기)

**하는 일:** 계산/읽기 결과를 **Register File에 쓴다.** (단, `RegWrite=1`인 명령어만)

| 명령어 | WB에서 무엇을 쓰나 | 어디서 온 값인가 |
|---|---|---|
| add, addi | ALU 결과 | EX 단계 출력 |
| lw | 메모리에서 읽은 값 | MEM 단계 출력 |
| sw, beq | **아무것도 안 씀** (RegWrite=0) | — |

```text
add x5,x6,x7  →  x5 ← (ALU 결과)
lw  x5,8(x6)  →  x5 ← (메모리에서 읽은 값)
sw / beq      →  레지스터 안 건드림
```

여기서 `add`와 `lw`의 마지막 차이가 control 신호 하나(`MemtoReg`)로 갈린다 — "레지스터에 쓸 값이 ALU에서 오나, 메모리에서 오나?" 이게 MUX 하나로 선택된다.

마지막으로 **PC 갱신**: 분기가 아니면 `PC ← PC+4`(IF에서 미리 계산한 값), 분기 taken이면 `PC ← 분기 목적지`.

> **DV 메모**: WB가 **architectural state가 실제로 바뀌는 commit 지점**이다. 검증에서 "이 명령어 실행 후 x5가 정말 13인가?"를 체크하는 시점이 바로 여기. reference model은 명령어 하나당 정확히 이 시점에 상태를 업데이트하고, DUT의 retire/commit 시점과 비교한다. **instruction-level scoreboard의 핵심 비교 지점.**

## 3. 명령어 4종이 5단계를 통과하는 방식 — 한눈에

| 단계 | `add` (R) | `addi`(I) | `lw` (load) | `sw` (store) | `beq`(branch) |
|---|---|---|---|---|---|
| **IF** | fetch | fetch | fetch | fetch | fetch |
| **ID** | reg 2개 읽기 | reg 1개 + imm | reg + imm | reg 2개 + imm | reg 2개 + imm |
| **EX** | rs1+rs2 | rs1+imm | 주소=rs1+imm | 주소=rs1+imm | rs1-rs2 비교 |
| **MEM** | — | — | **메모리 읽기** | **메모리 쓰기** | — |
| **WB** | rd←ALU | rd←ALU | **rd←메모리값** | — | — |
| **PC** | +4 | +4 | +4 | +4 | taken? 목적지 : +4 |

읽는 법:

- **R-type가 가장 "기본"** — MEM을 안 쓴다.
- **Load가 5단계를 다 쓰는 유일한 명령어** — 그래서 pipeline 설계에서 load 기준으로 단계를 5개로 정했다.
- **Store/Branch는 WB가 없다** — 레지스터에 결과를 안 남기니까.

## 4. Single-cycle vs Multi-cycle vs Pipeline (한 발 앞 예고)

같은 5단계 "일"을 시간에 어떻게 배치하느냐:

```text
Single-cycle:  한 클럭에 IF+ID+EX+MEM+WB 전부 → 클럭이 느림(가장 느린 명령어 기준)
               |————————— 1 clock (길다) —————————|

Multi-cycle:   단계마다 1클럭 → 명령어마다 클럭 수 다름(add는 4, lw는 5)
               |IF|ID|EX|MEM|WB|

Pipeline:      5개를 겹쳐서 → 매 클럭 새 명령어 시작 (Unit 8)
   명령1: IF ID EX MEM WB
   명령2:    IF ID EX  MEM WB
   명령3:       IF ID  EX  MEM WB
```

이번 유닛은 **"일의 분류"** 만 확실히 잡으면 된다. "어떻게 시간에 펼치냐"는 Unit 6(성능 재는 법)·Unit 8(pipeline)에서.

> **DV 메모**: DUT가 어떤 구현이든(single/multi/pipeline) **reference model은 항상 single-cycle 의미론**으로 짠다 — "명령어 하나 = 상태 한 번 갱신"이라는 atomic한 황금률. pipeline DUT를 검증할 때 핵심 난이도는 "여러 명령어가 동시에 떠있는 마이크로아키텍처 상태"를 "한 번에 하나씩 commit되는 architectural 상태"와 맞추는 매핑(=ROB/retire 시점 추적, Unit 10)이 된다.

## 핵심 정리

> 이 유닛의 진짜 메시지 — 꼭 기억할 3가지.

1. **CPU = `fetch→decode→execute→mem→writeback`의 무한 루프.** 모든 복잡함(pipeline, OoO, speculation)은 이 루프를 "더 빨리" 돌리려는 변주일 뿐이다.

2. **명령어 = 데이터 + control word.** 같은 datapath 부품(ALU, 메모리, 레지스터)이 control 신호 조합에 따라 add도 되고 load도 된다. Decode 단계가 이 control word를 만든다.

3. **검증의 경계 = architectural state(PC, RegFile, Memory).** 5단계 중 WB/PC-update가 commit 지점이고, scoreboard는 명령어 하나당 이 지점에서 정답을 비교한다. 나머지 단계는 그 정답을 만들기 위한 중간 과정.

---

## 🔌 검증 관점

- **Decode가 버그 1순위:** valid opcode를 전부 디코드하나 + 정의 안 된 조합은 `illegal instruction`으로 trap 나나 → valid/invalid partition + negative test. (opcode × funct3 × funct7 cross-coverage)
- **commit 지점만 비교:** scoreboard는 architectural state(PC·RegFile·Memory)만 본다. WB/PC-update가 명령어당 atomic commit 시점 — reference model은 여기서 상태를 1회 갱신.
- **IF:** PC alignment(4바이트) 검증, 비정렬 PC는 exception. instruction fetch = read transaction 검증.
- **EX:** Unit 3가 물리는 곳 — overflow·부호/무부호·carry, 주소 계산 경계/정렬 corner. `0/max/min/-1/overflow boundary` directed+random.
- **MEM:** read/write·alignment·비정렬 exception, 같은 주소 load/store 순서(Unit 13 일관성으로 확장).
- **single-cycle 의미론으로 모델링:** DUT가 pipeline/OoO여도 reference model은 "명령어 1개 = 상태 1회 갱신". 난이도는 retire/commit 시점 매핑(Unit 10).

---

## 📎 부록 — 이 단원에서 나온 질문들

### Q1. "1.에서 Data memory랑 instruction memory랑 어차피 한 메모리 안에 있는 거지? (ex] dram)"

답은 **"보는 층위에 따라 다르다"** 인데, 이걸 제대로 풀어야 헷갈림이 사라진다.

#### 1. 두 가지 철학: Von Neumann vs Harvard

| | **Von Neumann** | **Harvard** |
|---|---|---|
| 명령어 메모리 / 데이터 메모리 | **하나로 합침** (같은 주소공간, 같은 버스) | **물리적으로 분리** (별도 버스) |
| 장점 | 단순, 유연 (코드도 데이터처럼 다룸) | 명령어 fetch와 데이터 접근을 **동시에** 가능 |
| 단점 | fetch와 data 접근이 같은 버스 → 경합 ("Von Neumann bottleneck") | 코드/데이터 공간 분리 → 경직 |

Unit 5 다이어그램에서 Instruction Memory랑 Data Memory를 **따로 그린 건 Harvard 스타일**이다. 교육용/하드웨어 설계용으로 깔끔하다(두 개를 같은 클럭에 동시에 접근할 수 있어서 pipeline 그리기 좋음).

#### 2. 직답: "DRAM 한 덩어리 아니냐?"

**맞다. 실제 시스템의 메인 메모리(DRAM) 층위에서는 코드와 데이터가 같은 한 메모리에 섞여 있다.** 이게 Von Neumann이고, 거의 모든 범용 컴퓨터(x86, ARM, RISC-V 응용 프로세서)가 이쪽이다. 프로그램의 `.text`(코드)와 `.data`(데이터)가 같은 DRAM 주소공간에 나란히 올라간다.

그런데 — 핵심 — **CPU 바로 옆의 캐시 층위에서는 다시 분리된다.**

```text
        ┌─────────────── CPU 코어 ───────────────┐
        │                                        │
        │   [L1 I-Cache]        [L1 D-Cache]     │  ← Harvard! (분리)
        │    (명령어 전용)        (데이터 전용)      │
        └────────┬───────────────────┬───────────┘
                 │                   │
                 └─────────┬─────────┘
                           ▼
                    [L2 Cache] (통합, unified)     ← 여기서 합쳐짐
                           ▼
                    [DRAM / 메인 메모리]            ← Von Neumann (한 덩어리)
                       .text + .data 섞여있음
```

그래서 현대 CPU는 둘 다 — **"Modified Harvard"** 라고 부른다:

- **L1 캐시 레벨**: I-cache / D-cache 분리 (Harvard) → fetch와 load/store가 같은 클럭에 안 부딪침
- **L2 이하 ~ DRAM**: 하나로 통합 (Von Neumann) → 결국 같은 물리 메모리

#### 3. 왜 L1만 굳이 쪼갰나?

pipeline을 생각하면:

- **IF 단계**는 매 클럭 명령어를 fetch 해야 함
- **MEM 단계**는 (load/store면) 같은 클럭에 데이터를 접근해야 함

메모리가 포트 하나짜리 단일 블록이면, IF랑 MEM이 **같은 클럭에 같은 메모리를 동시에 못 써서 stall(structural hazard, Unit 8)** 이 생긴다. L1을 I/D로 쪼개면 두 접근이 물리적으로 다른 SRAM이라 동시에 가능 → bottleneck 해소.

즉 Unit 5 다이어그램에서 메모리를 둘로 그린 건 **"동시 접근이 필요하다"** 는 마이크로아키텍처 요구를 반영한 것이지, "물리적으로 영원히 다른 칩"이라는 뜻이 아니다.

#### 4. 코드를 데이터처럼 고칠 수 있나? (self-modifying code)

Von Neumann이니까 **원리적으로는 가능**하다 — 코드도 그냥 DRAM의 바이트일 뿐이니 store로 덮어쓸 수 있다. 그런데 Harvard 캐시 분리 때문에 함정이 생긴다:

> D-cache에 코드를 새로 써도, I-cache는 옛날 명령어를 들고 있을 수 있다(둘이 분리돼 있으니까!). 그래서 코드를 수정하면 명시적으로 **I-cache를 무효화(flush/invalidate)** 해줘야 CPU가 새 코드를 본다.

이게 JIT 컴파일러나 동적 코드 생성에서 `__builtin___clear_cache()` 같은 걸 호출하는 이유다.

#### 🔌 DV 메모

이 구분이 검증에서 중요한 이유 — **검증 대상(verification scope)의 경계**를 정하기 때문이다:

- **I/D가 분리된 L1 레벨**을 검증한다면: 두 캐시가 **독립 transaction 스트림**이고, 같은 물리 주소를 I-cache와 D-cache가 동시에 들고 있을 때의 **coherence(self-modifying code 시나리오)** 가 핵심 corner case다. negative test 1순위.
- **통합되는 L2/DRAM 레벨**을 검증한다면: 코드 fetch와 data 접근이 **같은 메모리 컨트롤러로 합류**하니까, 두 스트림이 같은 주소/뱅크를 두고 경합하는 **ordering·arbitration** 검증이 핵심.
- reference model 짤 때: 보통 메모리를 **하나의 통합 byte-addressable 배열**로 모델링한다(Von Neumann 의미론). I/D 분리는 어디까지나 성능(타이밍) 최적화라, **기능(정답) 모델은 단일 메모리**로 두고, 캐시 분리는 타이밍·coherence 체크에서만 신경 쓰면 된다.

RDMA TB에서 MR(memory region)을 하나의 주소공간으로 모델링하고, 캐싱/경로는 별도로 보는 것과 정확히 같은 추상화 전략이다.

**한 줄 요약**: DRAM 층위에선 말 그대로 **한 메모리(Von Neumann)** 맞다. 단 CPU 옆 L1 캐시에선 성능 때문에 **명령어/데이터를 다시 쪼갠다(Harvard)**. 그래서 현대 CPU = "Modified Harvard". 다이어그램이 둘로 그린 건 그 L1 관점이었다.

### Q2. "Immediate가 뭐야 쉽게 설명해줘"

간단히 말하면 **명령어 안에 직접 박혀있는 상수(숫자)** 다. "즉시값"이라고 번역한다.

#### 1. 핵심 아이디어

레지스터에 들어있는 값 말고, **명령어 그 자체에 숫자를 적어 넣는 것**.

```text
addi x5, x6, 100
            ───
            이 100이 immediate (즉시값)
```

`addi x5, x6, 100` = "x6에 들어있는 값에다 **100**을 더해서 x5에 넣어라"

여기서 `x6`은 레지스터(값이 어딘가 저장돼 있어서 꺼내와야 함)지만, `100`은 명령어 비트 안에 **그냥 적혀있다**. 그래서 "즉시(immediate) 쓸 수 있다"는 뜻 — 어디 가서 읽어올 필요 없이 명령어 해독하는 순간 바로 손에 있음.

#### 2. 왜 필요한가? — 일상 비유

요리 레시피로 비유하면:

- **레지스터 사용**: "**3번 그릇에 담긴 설탕**을 넣어라" → 3번 그릇에 가서 꺼내와야 함
- **immediate 사용**: "설탕 **2스푼**을 넣어라" → 숫자 '2'가 레시피에 바로 적혀있음

`x = x + 1` 같은 코드에서 그 `1`을 어떻게 표현할까? 1을 레지스터에 미리 넣어두고 쓰는 건 낭비다. 그냥 명령어에 `1`을 박아버리는 게 훨씬 효율적이다. 이게 immediate.

#### 3. 어디에 쓰이나

| 코드 | 명령어 | immediate |
|---|---|---|
| `x = x + 5` | `addi x5, x5, 5` | **5** |
| `arr[8]` 접근 | `lw x5, 8(x6)` | **8** (offset) |
| `if (a == b) goto L` | `beq x5, x6, L` | **L까지의 거리** (분기 offset) |
| 큰 상수 로드 | `lui x5, 0x12345` | **0x12345** |

#### 4. 명령어 비트 안에서의 모습

Unit 5에서 본 R-type은 immediate가 없었다(레지스터 3개만). 그런데 **I-type**은 한 자리를 immediate에 내준다:

```text
 R-type (add):  funct7 │ rs2 │ rs1 │ funct3 │ rd │ opcode
                                ↑
 I-type (addi): │  immediate(12비트)│ rs1 │ funct3 │ rd │ opcode
                 ───────────────────
                 rs2 자리를 없애고 그 공간에 상수를 박음
```

핵심: 명령어는 **32비트로 크기가 고정**돼 있다. 그래서 immediate에 쓸 수 있는 비트 수가 제한된다 — RISC-V I-type은 12비트. 즉 −2048 ~ +2047까지만 한 명령어에 담을 수 있다. 더 큰 수는 `lui` + `addi` 두 명령어로 쪼개서 만든다.

#### 5. 부호확장 (Unit 3와 연결되는 지점)

여기가 살짝 까다롭고, 사실 Unit 5에서 "Immediate Generator"를 따로 둔 이유다.

immediate는 명령어 안에서 **12비트**인데, ALU는 **32비트(또는 64비트)** 로 계산한다. 크기가 안 맞는다. 그래서 12비트를 32비트로 늘려야 하는데, 그냥 0으로 채우면 안 된다 — **음수가 깨지니까.**

```text
12비트 immediate:  1111_1111_1111   (= -1, 2의 보수)

❌ 0으로 채우면:  0000...0000_1111_1111_1111  = 4095 (양수로 변함! 틀림)
✅ 부호확장:      1111...1111_1111_1111_1111  = -1   (맞음)
```

맨 앞 비트(부호 비트)를 위쪽으로 쭉 복사하는 게 **sign extension(부호확장)**. Unit 3의 2의 보수가 여기서 실전 투입되는 것이다.

#### 🔌 DV 메모

immediate는 검증에서 **버그 단골손님**이다. 체크 포인트:

1. **부호확장 정확성**: 음수 immediate(맨 앞 비트 1)가 제대로 부호확장 되나? `addi x5, x0, -1` 했을 때 x5가 정말 0xFFFF...FFFF인가, 아니면 0x00000FFF로 깨지나? → 양수/음수/0/최대/최소 경계값 directed test 필수.
2. **immediate 필드 위치**: RISC-V의 악명 높은 포인트 — immediate가 명령어 비트 안에 **흩어져서(scrambled)** 배치돼 있다(특히 B-type, J-type). 분기 offset 비트들이 순서 뒤섞여 박혀있어서, decode할 때 비트를 올바른 순서로 재조립하는지 검증해야 한다. 여기 자주 틀린다.
3. **범위 경계(overflow)**: 12비트 한계(−2048 ~ +2047) 바로 안팎 값으로 corner test.

패킷 필드 파싱 검증할 때 "필드가 비트 어디에 있고, 부호가 있나 없나, 경계값에서 안 깨지나" 보는 것과 똑같은 검증 패턴이다 — immediate는 그냥 "명령어라는 패킷 안의 한 필드"인 셈.

**한 줄 요약**: immediate = **명령어 안에 직접 적어 넣은 상수**. 레지스터처럼 꺼내올 필요 없이 바로 쓰는 값이고, 크기 제한(12비트) + 부호확장이 핵심 디테일이다.

### Q3. "execute에서 rs1 / rs2 이건 어떤 걸 의미하는 거야?"

`rs`는 **source register(소스 레지스터, 입력으로 쓸 레지스터)**, 숫자는 그냥 번호다. 짝꿍인 `rd`까지 같이 정리한다.

#### 1. 이름 풀이

| 약자 | 풀네임 | 뜻 | 역할 |
|---|---|---|---|
| **rs1** | **r**egister **s**ource **1** | 첫 번째 소스 레지스터 | 계산에 쓸 **입력 1** |
| **rs2** | **r**egister **s**ource **2** | 두 번째 소스 레지스터 | 계산에 쓸 **입력 2** |
| **rd** | **r**egister **d**estination | 목적지 레지스터 | 결과를 **저장할 곳** |

핵심: 이건 **"어떤 레지스터를 쓸지 가리키는 번호표(포인터)"** 일 뿐, 값 자체가 아니다.

#### 2. 예제로 보면 바로 이해됨

```text
add  x5, x6, x7     →   x5 ← x6 + x7
     ──  ──  ──
     rd  rs1 rs2
```

읽는 법: "**rs1(x6)** 와 **rs2(x7)** 를 더해서 **rd(x5)** 에 넣어라"

- `rs1 = x6` → 첫 번째 입력은 6번 레지스터
- `rs2 = x7` → 두 번째 입력은 7번 레지스터
- `rd  = x5` → 결과는 5번 레지스터에 저장

**중요**: `rs1`은 "x6"이라는 *번호*고, EX 단계에서 실제로 계산되는 건 그 x6 안에 들어있는 *값*이다. 둘을 구분해야 한다:

```text
ID 단계:  rs1 = 6번  →  Register File에서 6번 레지스터 값을 읽음 → 예: 10
ID 단계:  rs2 = 7번  →  7번 레지스터 값을 읽음 → 예: 3
EX 단계:  ALU가 10 + 3 = 13 계산        ← 여기서 진짜 값으로 계산
WB 단계:  rd = 5번  →  5번 레지스터에 13 저장
```

#### 3. 왜 1, 2 두 개나? — ALU 입력이 두 개니까

Unit 2에서 본 ALU는 입력이 **A, B 두 개**였다.

```text
        rs1 값 ──►┐
                  [ALU] ──► 결과 (→ rd로)
        rs2 값 ──►┘
```

`rs1` → ALU의 첫 입력, `rs2` → ALU의 두 번째 입력. 대부분의 산술 연산(`+`, `-`, `&`, `|`...)이 입력 2개를 받으니까 소스 레지스터도 2개인 것이다.

#### 4. 명령어 종류마다 rs1/rs2 쓰임이 다르다

| 명령어 | rs1 | rs2 | rd |
|---|---|---|---|
| `add x5,x6,x7` | x6 (입력1) | x7 (입력2) | x5 (결과) |
| `addi x5,x6,100` | x6 (입력1) | **없음** (대신 immediate 100) | x5 (결과) |
| `lw x5,8(x6)` | x6 (주소 베이스) | **없음** | x5 (읽은 값) |
| `sw x5,8(x6)` | x6 (주소 베이스) | x5 (저장할 데이터) | **없음** |
| `beq x6,x7,L` | x6 (비교값1) | x7 (비교값2) | **없음** |

읽어볼 포인트:

- `addi`, `lw`는 **rs2가 없다** — 두 번째 입력 자리를 immediate가 차지하니까(I-type!).
- `sw`(store)는 특이하게 **rd가 없고** rs2가 "저장할 데이터"로 쓰임 — 결과를 레지스터에 안 남기고 메모리에 쓰니까.
- `beq`(branch)도 rd 없음 — 비교만 하고 결과 저장 안 함.

즉 **rs1/rs2/rd는 고정된 의미가 아니라, 명령어 종류(opcode)가 "이 자리를 어떻게 해석할지" 정한다.** 이게 Unit 5에서 말한 "decode가 control word를 만든다"의 구체적 예시다.

#### 🔌 DV 메모

rs1/rs2/rd 검증에서 핵심 corner:

1. **`x0` 특수성**: RISC-V에서 0번 레지스터(`x0`)는 **항상 0이고 쓰기가 무시**된다. `add x0, x6, x7`은 계산은 하지만 결과를 버린다. rd=x0일 때 정말 안 써지나? rs1/rs2=x0일 때 0으로 읽히나? → directed test 필수 corner.
2. **read-after-write 같은 레지스터**: `add x5, x5, x5`(rs1=rs2=rd=같은 번호) 같은 self-reference. pipeline에선 이게 **data hazard**(Unit 8)의 씨앗 — 아직 WB 안 된 값을 다음 명령어가 rs1으로 읽으려 하면? forwarding 검증의 핵심 시나리오.
3. **register file의 2-read/1-write 포트**: rs1, rs2를 **동시에 읽고** rd에 **동시에 쓰는** 게 한 명령어에서 일어난다. 같은 클럭에 rd에 쓰면서 rs1으로 그걸 읽으면 옛날 값이냐 새 값이냐? → register file 자체의 timing 검증 포인트.

패킷으로 치면 rs1/rs2/rd는 **헤더의 "src/dst 필드"** 와 똑같다 — 번호(포인터)지 데이터가 아니고, 그 번호로 실제 buffer/queue를 인덱싱해서 값을 꺼내오는 구조. RDMA에서 QP 번호로 context 찾는 것과 같은 패턴.

**한 줄 요약**: `rs1`/`rs2` = 계산 **입력**으로 쓸 레지스터 번호(source), `rd` = 결과를 **저장**할 레지스터 번호(destination). 번호일 뿐 값이 아니고, EX 단계에선 그 번호가 가리키는 *실제 값*으로 ALU가 계산한다.

### Q4. "여기서 R type 이란 게 뭐야?"

명령어를 **비트 배치 모양(format)** 으로 분류한 게 "타입"이다. R-type은 그중 하나, **"레지스터끼리 계산하는 명령어 형식"**.

#### 1. 왜 "타입"이 필요한가?

명령어는 32비트로 크기가 **고정**돼 있다. 그런데 명령어마다 필요한 정보가 다르다:

- `add x5,x6,x7` → 레지스터 **3개** 번호가 필요 (immediate 필요 없음)
- `addi x5,x6,100` → 레지스터 **2개** + **상수 100**
- `lw x5,8(x6)` → 레지스터 2개 + **offset**
- `beq x6,x7,L` → 레지스터 2개 + **분기 거리**

같은 32비트를 **어떻게 쪼개 쓸지**가 명령어마다 다르다. 이 "비트 쪼개는 패턴"을 몇 가지로 표준화한 게 **명령어 타입(instruction format)**. RISC-V는 6가지가 있다: **R, I, S, B, U, J**.

`R`은 **R**egister의 R — 레지스터만 가지고 계산하는 형식.

#### 2. R-type의 정체

**R-type = 레지스터 3개로 계산하는 명령어** (immediate 없음)

```text
add x5, x6, x7     ←  rd=x5,  rs1=x6,  rs2=x7   (레지스터만 3개)
```

비트 배치:

```text
 31      25 24   20 19   15 14  12 11   7 6        0
┌──────────┬───────┬───────┬──────┬──────┬──────────┐
│  funct7  │  rs2  │  rs1  │funct3│  rd  │  opcode  │
└──────────┴───────┴───────┴──────┴──────┴──────────┘
   7비트     5비트   5비트   3비트  5비트    7비트
```

특징:

- **immediate 자리가 아예 없다** → 상수를 안 쓰니까. 그 공간을 `funct7`/`funct3`(연산 종류 구분용)에 더 할당.
- **rs1, rs2, rd 세 레지스터** 다 있음.
- 5비트짜리 레지스터 필드 → 2⁵ = **32개 레지스터**를 가리킬 수 있음 (RISC-V가 레지스터 32개인 이유!).

R-type에 속하는 명령어들: `add`, `sub`, `and`, `or`, `xor`, `sll`(shift), `slt`(비교)... 전부 **"레지스터 두 개 받아서 계산 → 레지스터에 저장"** 형태.

#### 3. 다른 타입과 비교하면 R-type이 뭔지 더 선명해진다

| 타입 | 이름 유래 | 핵심 특징 | 예시 |
|---|---|---|---|
| **R** | **R**egister | 레지스터 3개, immediate 없음 | `add x5,x6,x7` |
| **I** | **I**mmediate | rs2 자리에 12비트 immediate | `addi x5,x6,100`, `lw x5,8(x6)` |
| **S** | **S**tore | 저장용, immediate가 둘로 쪼개짐 | `sw x5,8(x6)` |
| **B** | **B**ranch | 분기용, offset이 흩어져 박힘 | `beq x6,x7,L` |
| **U** | **U**pper | 상위 20비트 큰 상수 | `lui x5,0x12345` |
| **J** | **J**ump | 점프용, 긴 offset | `jal x1,func` |

핵심 대비:

```text
R-type:  funct7 │ rs2 │ rs1 │ funct3 │ rd │ opcode    ← rs2 자리에 "레지스터"
I-type:  imm[11:0]    │ rs1 │ funct3 │ rd │ opcode    ← 같은 자리에 "상수"
         ─────────
         R의 funct7+rs2 자리를 합쳐서 12비트 상수로 씀
```

**R-type을 한 마디로**: "두 번째 입력이 레지스터인 계산 명령어" (I-type은 그 자리가 상수라는 점만 다름).

#### 4. opcode / funct7 / funct3 — 어떻게 add인지 sub인지 구분?

R-type 명령어들은 **opcode가 다 똑같다**(`0110011`). 그럼 add랑 sub을 어떻게 구별?

→ `funct3` + `funct7` 추가 필드로 구분:

```text
add:  opcode=0110011, funct3=000, funct7=0000000
sub:  opcode=0110011, funct3=000, funct7=0100000   ← funct7 한 비트만 다름!
and:  opcode=0110011, funct3=111, funct7=0000000
```

opcode는 "큰 분류(이건 R-type 계산이다)", funct3/funct7은 "세부 연산(그중 add냐 sub냐)". 2단계 분류 체계다.

#### 🔌 DV 메모

instruction format은 검증에서 **decode 단계 coverage의 뼈대**다:

1. **타입별 필드 추출 정확성**: R-type 디코드 시 rs1/rs2/rd를 비트 [19:15]/[24:20]/[11:7]에서 정확히 뽑나? 타입마다 같은 비트 위치가 다른 의미를 가지니까(R의 [24:20]=rs2, I의 [31:20]=imm), **타입 판별이 틀리면 전 필드가 어긋난다**. 1순위 검증.
2. **funct7/funct3 조합 coverage**: 같은 opcode 아래 valid한 funct 조합을 다 디코드하나 + **정의 안 된 조합은 illegal instruction**으로 trap 나나. cross-coverage 대상 (opcode × funct3 × funct7).
3. **타입 경계 corner**: opcode 1비트만 바뀌면 R↔I로 해석이 통째로 바뀐다. mutation/negative test로 "비트 한 개 뒤집었을 때 올바르게 다른 타입(또는 illegal)로 가나" 확인.

패킷으로 비유하면 instruction type = **패킷의 "포맷/버전 필드"** 다. 포맷에 따라 같은 바이트 오프셋이 다른 필드로 해석된다 — RDMA에서 opcode에 따라 헤더 레이아웃(BTH 뒤에 RETH냐 AETH냐)이 달라지는 것과 정확히 같은 구조.

**한 줄 요약**: R-type = RISC-V 명령어 형식 중 **"레지스터 3개로 계산하는 형식"**(immediate 없음). 32비트를 어떻게 쪼갤지 정한 6가지 포맷(R/I/S/B/U/J) 중 하나고, `add`·`sub`·`and` 같은 레지스터-레지스터 연산이 여기 속한다.
