# RTL 기초 — 조합/순차 논리 & `=` vs `<=`

> 회로는 **조합(기억 없음) / 순차(기억 있음)** 두 종류. 코드는 `assign` / `always_comb` / `always_ff`로 쓰고, **`always_ff`엔 `<=`, `always_comb`엔 `=`**.

## 1. 두 기준을 먼저 구분하기

"combinational vs procedural"은 비교하는 짝이 아니다. 기준이 서로 다르다.

- **조합(combinational) vs 순차(sequential)** → **회로의 종류**
- **continuous(`assign`) vs procedural(`always` 블록)** → **코드를 쓰는 방식**

| | 회로 종류 | 기억 | 값이 바뀌는 시점 | 비유 |
|---|---|---|---|---|
| 조합 논리 | AND, OR, MUX, 덧셈기 | 없음 | 입력이 바뀌면 **바로** | 계산기 버튼 → 화면 |
| 순차 논리 | 플립플롭, 레지스터, 카운터, FSM | 있음 | **클럭 엣지에서만** | 사진기 셔터 |

두 기준을 합치면:

| 코드 | 쓰는 방식 | 만드는 회로 |
|---|---|---|
| `assign y = a & b;` | continuous (한 줄) | 조합 |
| `always_comb begin ... end` | procedural | 조합 |
| `always_ff @(posedge clk) ...` | procedural | 순차 |

→ procedural은 "**어떻게 쓰느냐**"일 뿐, 그걸로 조합 회로도 순차 회로도 만들 수 있다.

## 2. `assign` vs `always_comb`

**둘 다 조합 회로**를 만든다. 차이는 "얼마나 복잡한 걸 쓸 수 있느냐".

```systemverilog
// assign — 식 하나로 선을 연결
assign y   = a & b;
assign out = sel ? d1 : d0;   // 2:1 MUX
```

```systemverilog
// always_comb — 블록 안에 문장 여러 줄
always_comb begin
  out = d3;                // 기본값 먼저
  case (sel)
    2'd0: out = d0;
    2'd1: out = d1;
    2'd2: out = d2;
  endcase
end
```

| | `assign` | `always_comb` |
|---|---|---|
| 표현 | 식 하나 | `if`, `case`, 중간 변수, 여러 출력 |
| 래치 위험 | 없음 (항상 식이 연결돼 있음) | 모든 경우에 값을 안 주면 생김 |
| 언제 | 식 하나로 끝날 때 | 조건이 여러 개거나 `case`가 필요할 때 |

- 만들어지는 회로는 같다. 2:1 MUX를 `always_comb`에서 `if (sel) out = d1; else out = d0;`로 써도 동일.

## 3. latch (의도치 않은 래치)

래치 = **값을 기억하는 회로**. 조합 회로를 만들려다 실수로 "기억"이 들어간 상황.

```systemverilog
// ❌ sel=0일 때 y 값을 안 정함 → "이전 값 유지" → 래치 추론
always_comb begin
  if (sel)
    y = a;
end
```

```systemverilog
// ✅ 기본값을 먼저 주면 모든 경우에 값이 정해짐
always_comb begin
  y = '0;
  if (sel) y = a;
end
```

- 위험한 이유: 의도치 않은 **이전 값이 남아** 받는 쪽이 틀린 값으로 동작할 수 있고, 더 근본적으로는 **회로 자체가 바뀐다**(기억 소자 추가 → 타이밍 문제, 시뮬레이션과 실제 칩 불일치).
- `assign`에서는 생길 수 없다. `always_comb`에서 `if`의 `else`, `case`의 `default` 누락만 조심.
- 래치 vs 플립플롭, 래치가 실무에서 나쁜 이유(STA, DFT, CDC)는 → [컴퓨터 구조 Unit 8 — Q4, Q5](../../computer-architecture/unit8-pipeline-hazard.md)

## 4. 순차 논리와 `always_ff`

기본 부품은 **D 플립플롭** (입력 `d`, 클럭 `clk`, 출력 `q`).

- `clk`가 0→1로 올라가는 순간(posedge) `d`를 찍어서 `q`에 저장.
- 그 외 시간엔 `d`가 바뀌어도 `q`는 그대로. (셔터를 누른 순간만 저장되는 사진기)

```systemverilog
always_ff @(posedge clk) begin
  q <= d;
end
```

```systemverilog
// 비동기 리셋 — 전원 직후 FF 값은 알 수 없으므로 시작 값을 정해줌
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) q <= '0;
  else        q <= d;
end
```

- "지금 몇 번째인지", "지금 어떤 상태인지"처럼 **과거를 기억해야 하는 건 전부 순차 논리** (카운터, 레지스터, FSM).
- 모든 FF가 같은 클럭에 맞춰 동시에 바뀌므로 회로 전체가 박자를 맞춰 움직인다.

## 5. `always` vs `always_ff` / `always_comb`

만들어지는 회로는 같을 수 있다. 차이는 **의도를 선언하고, 도구가 그걸 검사해 준다**는 것.

```verilog
// 옛 Verilog — always 하나로 FF도, 조합도, 래치도 다 만듦 → 실수해도 조용히 넘어감
always @(posedge clk) q <= d;     // 플립플롭
always @(*)           y = a & b;  // 조합 회로
```

`always_ff`로 쓰면 도구가 잡아주는 것:

- 클럭 엣지(`posedge`/`negedge`) 없이 쓰면 경고/에러
- 블록 안에서 FF가 아닌 것(조합, 래치)이 만들어지면 알림
- 같은 변수를 다른 블록에서도 구동하면 에러

| 블록 | 용도 |
|---|---|
| `always_ff` | 플립플롭 (순차) |
| `always_comb` | 조합 회로 |
| `always` | 회로가 아닌 곳, 예: TB 클럭 생성 `always #5 clk = ~clk;` |

## 6. `=` (blocking) vs `<=` (non-blocking)

### 이름의 뜻

- **blocking `=`**: 값이 바뀔 때까지 **다음 줄을 막고 기다림** → 다음 줄은 **바뀐 값**을 봄. (소프트웨어 변수와 같음)
- **non-blocking `<=`**: 값 넣기는 **나중으로 예약**만 하고 바로 다음 줄로 → 다음 줄은 **바뀌기 전 값**을 봄.

### 비유: 줄 서서 공 넘기기

A=🔴, B=🔵, C=🟢. 규칙: "호루라기(클럭)가 울리면 자기 공을 오른쪽에 넘긴다."

- **`<=` (동시에)**: 세 사람이 **동시에** 직전에 들고 있던 공을 넘김 → B=🔴, C=🔵. 정확히 **한 칸씩** 이동.
- **`=` (한 명씩 차례로)**: A→B 먼저 넘겨서 B=🔴, 그다음 B→C인데 B 손엔 이미 🔴 → C=🔴. 🔵는 사라지고 🔴가 두 칸 이동.

실제 FF들은 같은 클럭 선에 연결돼 있어 **클럭 엣지에서 다 같이** 자기 입력을 찍는다. 누가 먼저/나중이 없다. 이 "동시에"를 흉내 내는 게 `<=`.

```systemverilog
// <= : 시프트 레지스터 (FF 2개)
always_ff @(posedge clk) begin
  B <= A;
  C <= B;
end

// = : 한 칸씩 밀리는 동작이 깨짐
always_ff @(posedge clk) begin
  B = A;
  C = B;
end
```

| 시점 | `<=` 버전 (B, C) | `=` 버전 (B, C) |
|---|---|---|
| 시작 | 🔵, 🟢 | 🔵, 🟢 |
| 1번째 클럭 | 🔴, 🔵 | 🔴, 🔴 |

### 시뮬레이터 안에서 `<=`는 2단계

1. **읽기**: 클럭이 올라가면 모든 `<=`의 오른쪽 값을 먼저 읽어 메모. (모두 공을 꽉 쥐고 준비)
2. **쓰기**: 그 시점 계산이 다 끝나면 메모한 값을 한꺼번에 왼쪽에 넣음. (하나, 둘, 셋에 동시에 넘기기)

### 줄 순서를 바꾸면?

```systemverilog
always_ff @(posedge clk) begin
  C <= B;
  B <= A;
end
```

- `<=`는 줄 순서를 바꿔도 **결과가 같다** (다 읽고 나서 한꺼번에 쓰니까).
- `=`는 줄 순서에 따라 결과가 달라진다.

### 조합 회로에 `<=`를 쓰면?

```systemverilog
always_comb begin
  tmp = a & b;
  y   = tmp | c;   // 방금 계산한 tmp를 바로 써야 함
end
```

여기서 `<=`를 쓰면 `y`가 갱신 전 `tmp`를 읽어 **한 순간 틀린 값**이 나온다 → 조합 회로엔 `=`.

### 하지 말 것

- 한 블록 안에서 `=`와 `<=`를 **섞어 쓰지 않기**. 언제 바뀌는지 헷갈려 버그가 생기고 리뷰도 어렵다.

## 7. 핵심 규칙 요약

- 조합/순차는 **회로 종류**, `assign`/procedural은 **쓰는 방식**.
- 식 하나면 `assign`, 조건이 많으면 `always_comb`.
- `always_comb`에선 **기본값 먼저** → 래치 방지.
- 플립플롭은 `always_ff`, 조합은 `always_comb`, 그냥 `always`는 TB용.
- **`always_ff`엔 `<=`, `always_comb`엔 `=`**, 한 블록에서 섞지 않기.
