# wire / reg / logic — net vs variable

> **`wire` = 기억 못 하는 전선**(`assign`으로 구동, 드라이버 없으면 `Z`), **`reg` = 값을 들고 있는 시뮬레이터 그릇**(대본 안에서 대입받는 쪽). SV의 **`logic`은 둘 다 대신**할 수 있지만 **드라이버는 하나만**. 드라이버가 여럿인 tri-state / `inout`만은 반드시 `wire`.

---

## 1. 한눈에 비교

| 항목 | `wire` (net) | `reg` (variable) | `logic` (SV) |
| --- | --- | --- | --- |
| **정체** | 기억 못 하는 **전선** | 값을 기억하는 **그릇** (시뮬레이터 변수) | 4값 타입 — `wire` 자리 / `reg` 자리 모두 OK |
| **구동 방법** | `assign`, 모듈 출력 포트 | `always` / `initial` / `always_comb` 안 대입 | 둘 다 가능 |
| **대본 안 왼쪽(대입받는 쪽)** | ❌ 못 씀 (오른쪽에서 읽기는 OK) | ✅ | ✅ |
| **초기값** | 드라이버 없으면 **`Z`** | **`X`** | **`X`** |
| **다중 드라이버** | ✅ 가능 (값을 해석해서 합침) | — | ❌ **컴파일 에러** |
| **값 종류** | 4값 (`0/1/X/Z`) | 4값 | 4값 |

```text
           wire                         reg / logic
  ┌──────┐         ┌──────┐      always @(posedge clk)
  │ 구동 │━━━━━━━━━│ 읽기 │        cnt <= cnt + 1;   ← 실행 후 멈춰 기다리는 동안
  └──────┘  전선   └──────┘                            값을 들고 있을 "그릇" 필요
  (기억 없음: 구동이 끊기면 Z)
```

---

## 2. `wire` — 기억 못 하는 전선

```systemverilog
wire y;
assign y = a & b;           // ✅ assign 으로 구동

always @(*) begin
  y = a & b;                // ❌ 에러: wire 는 대본 안에서 왼쪽에 못 씀
  z = y | c;                // ✅ 오른쪽에서 읽는 건 OK
end
```

- 선 자체는 값을 기억하지 않는다. 누군가 계속 구동해 줘야 값이 있고, **드라이버가 없으면 `Z`**(아무도 안 잡은 선).
- `always` / `initial` / `always_comb` 안에서 **대입받는 쪽(왼쪽)으로 못 쓴다**.

---

## 3. `reg` — 값을 들고 있는 그릇

대본(`always` / `initial` / `always_comb`)은 실행한 뒤 **멈춰서 다음 이벤트를 기다린다**. 그동안 마지막 값을 들고 있을 **그릇**이 필요하므로, 대본 안에서 대입받는 쪽은 `reg` / `logic`이어야 한다.

```systemverilog
reg [7:0] cnt;              // 초기값 X
reg [7:0] mem [0:255];      // 벡터 / 메모리 배열 가능

always @(posedge clk)
  cnt <= cnt + 1;           // ⚠️ 리셋이 없으면 X + 1 = X → 영원히 X
```

- **초기값은 `X`** → 리셋이 없으면 `cnt <= cnt + 1`은 영원히 `X`다 ([X propagation](../rtl/x-propagation.md)).
- (Verilog) **`input` 포트로는 못 쓴다** — 입력은 밖에서 구동되는 선이므로 net이어야 한다.
- 벡터(`reg [7:0]`), 메모리 배열(`reg [7:0] mem [0:255]`) 선언 가능.

!!! warning "함정 — `reg` ≠ 레지스터(플립플롭)"
    "그릇"은 **시뮬레이터 문법 규칙**일 뿐이고, 실제 **합성 결과는 블록 형태가 결정**한다.

    | 코드 | 합성 결과 |
    | --- | --- |
    | `always @(posedge clk) q <= d;` (`reg q`) | 플립플롭 |
    | `always @(*) y = a & b;` (`reg y`) | **AND 게이트 출력** (FF 아님!) |

---

## 4. `logic` — SV의 기본 타입 (단, 드라이버는 하나)

```systemverilog
logic y1, y2;

assign y1 = a & b;          // ✅ wire 자리
always_comb y2 = a | b;     // ✅ reg 자리

// ❌ 컴파일 에러: logic 에 드라이버 2개
assign y1 = c;
```

- `wire` 자리 / `reg` 자리 어디든 쓸 수 있는 **4값(`0/1/X/Z`) 타입**이라 SV RTL / TB에서는 기본으로 `logic`을 쓴다.
- 단 **드라이버는 하나만** 허용된다. `assign`을 2개 걸면 **컴파일 에러** → 실수로 한 신호를 두 곳에서 구동하는 버그를 **컴파일 시점에 잡아 준다** (장점).

!!! warning "자주 틀리는 포인트 — `logic`에 `assign` 2개"
    `logic`에 `assign`을 두 번 걸면 **컴파일 에러**다. 의도적으로 여러 드라이버가 필요한 선(tri-state 버스, `inout`)이라면 **`wire`로 고쳐야** 한다. 핵심: **`logic`은 드라이버 하나만.**

### 그럼 `wire`는 언제 쓰나?

| 상황 | 타입 |
| --- | --- |
| **다중 드라이버** (tri-state 버스, `inout` 포트) | **`wire` 필수** |
| 모듈 간 연결만 하는 선 | 팀 스타일에 따라 `wire` (`logic`도 동작 동일) |
| 옛 Verilog 코드 / 합성 넷리스트 읽기 | `wire` / `reg`가 그대로 나옴 |
| 그 외 RTL / TB | `logic` |

---

## 5. tri-state & `inout` — `wire`가 꼭 필요한 곳

### tri-state (3상태 출력)

출력에 **스위치(`en`)**가 달려 있다. `en = 1`이면 값을 내보내고, `en = 0`이면 `Z`(선에서 손을 뗌).

```systemverilog
assign out = en ? data : 'z;    // en=0 → Z (손 뗌)
```

- 칩 **내부**에서는 tri-state 대신 **MUX**를 쓴다. tri-state는 주로 **외부 I/O 핀**에 쓴다.

### `inout` — 같은 핀으로 보내고 받기

하나의 핀으로 보내기도 하고 받기도 하는 **양방향 포트**다 (예: I2C `SDA`).

```systemverilog
module i2c_io (
  inout  wire  sda,             // ✅ 드라이버가 둘(나 + 상대) → 반드시 wire
  input  logic sda_oe,          // 1이면 내가 구동
  input  logic sda_out,
  output logic sda_in
);
  assign sda    = sda_oe ? sda_out : 'z;   // 보낼 때만 구동, 아니면 손 뗌
  assign sda_in = sda;                     // 받을 땐 sda 를 읽음
endmodule
```

### `wire` 다중 드라이버 해석

여러 드라이버가 한 `wire`를 구동하면 시뮬레이터가 값을 합쳐서 정한다.

| 드라이버 A | 드라이버 B | `wire` 결과 | 의미 |
| --- | --- | --- | --- |
| `1` | `Z` | **`1`** | 한쪽만 구동 → 그 값 |
| `Z` | `Z` | **`Z`** | 아무도 구동 안 함 |
| `1` | `0` | **`X`** | **충돌** (버스 contention) ⚠️ |

!!! tip "TB에서 보면"
    `inout` 버스에서 `X`가 보이면 **양쪽이 동시에 구동(충돌)**한 것이고, `Z`가 보이면 **아무도 구동하지 않는 구간**이다. `X` / `Z` 비교·체크 방법은 → [X vs Z, `==` vs `===`](../rtl/x-vs-z.md)

---

## 6. 핵심 규칙 요약

- `wire` = 전선(기억 X, 드라이버 없으면 `Z`), `assign`으로 구동, 대본 안 왼쪽 불가.
- `reg` = 그릇(초기값 `X`), 대본 안에서 대입받는 쪽. **`reg` ≠ 플립플롭**.
- `logic` = 둘 다 대신 가능, **드라이버는 하나만** (2개면 컴파일 에러).
- **tri-state / `inout`처럼 드라이버가 여럿이면 `wire` 필수.**
- 대본(`initial` / `always` / `always_comb`)의 동작은 → [절차 블록](../rtl/procedural-blocks.md)
