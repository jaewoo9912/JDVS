# assertion (SVA — SystemVerilog Assertions)

> "이 조건은 **항상 참이어야 한다**"를 코드로 박아두고, 깨지는 순간 시뮬레이터가 **시각·위치까지 짚어** 알려주는 기능.

## 핵심

- 검증은 보통 **scoreboard가 결과값**을 비교한다. assertion은 그 사이의 **프로토콜·타이밍 규칙**(handshake, 순서, 안정성 등)을 신호 레벨에서 직접 감시한다.
- 규칙이 깨지면 그 **클럭·신호·위치**를 즉시 출력 → 로그를 거슬러 추적할 필요가 없다.
- "버그가 **퍼지기 전에**, 발생 지점에서" 잡는 게 목적. (scoreboard는 멀리 떨어진 결과에서 잡힘)

## 비유: 계약서의 "반드시" 조항

| 계약서 | 검증(SVA) |
|---|---|
| "송장을 받으면 **3일 안에** 대금을 지급한다" | "`req`가 뜨면 **5클럭 안에** `ack`가 와야 한다" |
| 위반 시 즉시 분쟁 기록 | 위반 시 즉시 `$error`로 시각·신호 출력 |

## 두 종류 — immediate vs concurrent

| | immediate assertion | concurrent assertion |
|---|---|---|
| 평가 시점 | 절차문 한 줄처럼 **그 순간** | **클럭 엣지마다** 백그라운드로 |
| 위치 | `initial`/`always`/task 내부 | module/interface/program, `always` 밖도 OK |
| 시간 다룸 | 못 함 (현재값만) | **시간에 걸친 시퀀스** 표현 가능 |
| 키워드 | `assert (expr)` | `assert property (...)` |

```systemverilog
// immediate — "지금 이 값이 맞나"
always @(posedge clk)
  assert (state != ILLEGAL) else $error("illegal state!");

// concurrent — "클럭에 걸친 규칙"
assert property (@(posedge clk) req |-> ##[1:5] ack)
  else $error("req 후 5클럭 내 ack 없음");
```

## 빌딩 블록: property / sequence / implication

```text
sequence  : 시간에 걸친 신호 패턴       (예: a ##1 b ##2 c)
property  : sequence + 함의/부정 등 규칙 (예: a |-> b)
assert    : property가 참인지 검사
```

- `##N` : N클럭 뒤. `##[1:5]` : 1~5클럭 사이.
- `|->` (overlapped): 선행조건이 맞은 **그 클럭**부터 후행 검사.
- `|=>` (non-overlapped): 선행조건 맞은 **다음 클럭**부터 후행 검사.

```systemverilog
// req가 올라간 다음 클럭부터, 1~5클럭 내 ack
property p_req_ack;
  @(posedge clk) disable iff (!rst_n)
  req |=> ##[0:4] ack;
endproperty
assert property (p_req_ack) else $error("req→ack timeout");
```

## 자주 쓰는 연산자

| 연산자 | 의미 | 예 |
|---|---|---|
| `|->` / `|=>` | 함의 (overlapped / next-cycle) | `valid |-> ready` |
| `##N` / `##[m:n]` | 지연 / 지연 범위 | `a ##2 b`, `a ##[1:3] b` |
| `[*N]` / `[*m:n]` | 연속 반복 | `gnt[*3]` (3클럭 연속) |
| `[->N]` | go-to 반복 (N번째 발생까지) | `ack[->1]` |
| `$rose` / `$fell` | 상승/하강 엣지 | `$rose(req)` |
| `$stable` / `$past` | 값 유지 / 과거값 | `$stable(addr)`, `$past(data)` |
| `throughout` | 구간 내내 유지 | `(en) throughout (a ##1 b)` |
| `within` | 포함 | `s1 within s2` |

## disable iff — 리셋 중엔 검사 끄기

```systemverilog
assert property (@(posedge clk) disable iff (!rst_n)
  req |-> ##[1:5] ack);
```

> `disable iff`는 **리셋·예외 구간**에서 assertion이 헛발하지 않게 한다. SVA에서 거의 필수.

## assert / assume / cover

| 지시어 | 의미 | 쓰임 |
|---|---|---|
| `assert` | 이 규칙은 **반드시 참** | 위반 시 fail (검증의 핵심) |
| `assume` | 이 규칙을 **참이라 가정** (입력 제약) | formal에서 입력 조건 한정 |
| `cover` | 이 시나리오가 **실제로 일어났나** | 자극이 의도한 경로를 쳤는지 커버리지 |

```systemverilog
// 이 코너케이스가 한 번이라도 발생했는지 측정
cover property (@(posedge clk) $rose(req) ##[1:3] $rose(ack));
```

## 흔한 패턴 모음

```systemverilog
// 1) one-hot: 항상 정확히 한 비트만 1
assert property (@(posedge clk) $onehot(state_oh));

// 2) valid 중 데이터 안정: valid이고 ready 아니면 data 유지
assert property (@(posedge clk) (valid && !ready) |=> $stable(data));

// 3) 요청-응답 짝: req 후 반드시 ack (timeout 포함)
assert property (@(posedge clk) $rose(req) |-> ##[1:8] ack);

// 4) 동시에 둘 다 1이면 안 됨 (mutual exclusion)
assert property (@(posedge clk) !(wr_en && rd_en));

// 5) FIFO: full이면 push 금지
assert property (@(posedge clk) full |-> !push);
```

## 어디에 두나

- **interface**에 넣으면 그 프로토콜을 쓰는 모든 곳에서 재사용된다 (가장 흔한 위치).
- 바인드(`bind`)로 RTL을 안 건드리고 DUT 내부 신호에 assertion을 붙일 수 있다.

```systemverilog
// RTL 수정 없이 외부에서 검사 모듈을 붙임
bind dut_top axi_protocol_checker u_chk (.clk(clk), .rst_n(rst_n), ...);
```

## 흔한 함정

- ❌ **클럭 빠뜨림** — `assert property (req |-> ack)`는 클럭이 없어 모호. 항상 `@(posedge clk)` 명시.
- ❌ **리셋 미처리** — `disable iff (!rst_n)` 없으면 리셋 중 헛발한다.
- ❌ `|->` vs `|=>` 혼동 — 같은 클럭 검사인지 다음 클럭인지에 따라 의미가 달라진다.
- ❌ **vacuous pass 오해** — 선행조건이 한 번도 안 맞으면 assertion은 "통과"로 뜬다. 진짜 검증됐는지는 `cover`로 따로 확인.

## 이 프로젝트 현황

RDMA TB는 scoreboard 기반 결과 비교가 중심이고, 프로토콜 레벨 SVA는 제한적이다. AXI/handshake 신호에 `interface` SVA나 `bind` checker를 더하면 버그를 **발생 지점**에서 더 빨리 잡을 수 있다.
