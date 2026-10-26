# assertion (SVA — SystemVerilog Assertions)

> "이 조건은 **항상 참이어야 한다**"를 회로 옆 **자동 감시 카메라(CCTV)**처럼 코드로 박아두고, 깨지는 순간 시뮬레이터가 **시각·위치까지 짚어** 알려주는 기능.

## 핵심

- 검증은 보통 **scoreboard가 결과값**을 비교한다. assertion은 그 사이의 **프로토콜·타이밍 규칙**(handshake, FSM 상태 전이, 순서, 안정성 등)을 신호 레벨에서 직접 감시한다.
- 규칙이 깨지면 그 **클럭·신호·위치**를 즉시 출력 → 로그를 거슬러 추적할 필요가 없다.
- "버그가 **퍼지기 전에**, 발생 지점에서" 잡는 게 목적. (scoreboard는 멀리 떨어진 결과에서 잡힘)

```systemverilog
// FSM 감시 예: 지금 IDLE이고 start==1이면, 다음 클럭엔 무조건 BUSY여야 한다!
assert property (@(posedge clk)
  (state == IDLE && start) |=> (state == BUSY)
);
```

- 왼쪽(`state == IDLE && start`): **언제 감시를 시작할지(방아쇠)**
- 오른쪽(`state == BUSY`): **그때 반드시 일어나야 하는 결과**

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

### 왜 조합 논리 결과를 검사할 때도 `@(posedge clk)`를 쓸까?

조합 논리(`assign done_pulse = (state == DONE);`) 자체는 클럭과 무관하게 입력이 바뀌면 즉시 바뀐다. 그럼에도 concurrent assertion에 `@(posedge clk)`를 적는 이유는 **감시 카메라가 사진을 찍을 안전한 기준 시점**이 필요하기 때문이다.

- 클럭과 클럭 사이(과도기)에는 조합 회로에 **글리치**가 튀거나, 시뮬레이터 안에서 `state`가 먼저 `DONE`으로 바뀌고 아직 `assign`이 실행되기 직전(`done_pulse == 0`)인 찰나가 존재한다.
- 클럭 없이 매 순간 감시하면 신호가 바뀌는 중간 과정을 찍어 **억울한 가짜 에러(오경보)**가 터진다.
- 따라서 **"계산과 글리치가 다 가라앉아 조용해진 `posedge clk` 정각에만 사진을 찍되, 같은 사진 안에 두 조건이 함께 맞는지(`|->`) 확인하라"**는 뜻으로 `@(posedge clk)`를 쓴다.

## 화살표 두 개: `|->` (바로 그때) vs `|=>` (다음 클럭에)

| 화살표 | 이름 | 결과 확인 시점 | 주로 쓰는 곳 |
|---|---|---|---|
| **`\|->`** | overlapped implication | 조건이 맞은 **바로 그 클럭**에 확인 | 조합 논리 출력처럼 **즉시** 나와야 하는 결과 |
| **`\|=>`** | non-overlapped implication | 조건이 맞은 **다음 클럭(`##1`)**에 확인 | 플립플롭(`always_ff`, `<=`)을 거쳐 **1클럭 뒤에** 나오는 결과 |

```systemverilog
// 1) |-> : DONE 상태인 바로 그 클럭에 done_pulse도 1이어야 함 (조합 출력)
assert property (@(posedge clk)
  (state == DONE) |-> (done_pulse == 1)
);

// 2) |=> : 지금 DONE 상태면 다음 클럭에는 IDLE로 돌아가야 함 (순차 전이, |-> ##1 과 동일)
assert property (@(posedge clk)
  (state == DONE) |=> (state == IDLE)
);
```

```text
클럭          E1 (지금)          E2 (다음 클럭)
조건 확인     state == DONE 참!
  |-> 결과    done_pulse == 1 ?  (E1에서 바로 체크)
  |=> 결과                       state == IDLE ? (E2에서 체크)
```

## SVA 시퀀스 기본 공식 (IEEE 1800 표준 문법)

SVA의 시퀀스 표현은 정규표현식(Regex)에서 기호를 따온 레고 블록 구조로, 아래 **한 가지 공식**이 반복된다.

> **`[신호A][몇 클럭 유지할지]   ##[몇 클럭 뒤로 갈지]   [신호B][몇 클럭 유지할지]`**

즉 **"신호(얼마나 연속 high로 유지)"** 블록들을 **"시간 이동(`##`)"**으로 이어 붙이는 구조다.

### 1. 신호 뒤에 붙는 `[...]` — 몇 클럭 연속 유지할까? (반복)

- 생략 (`A`) : `A`가 **1클럭** 동안 참 (`A[*1]`과 같음)
- `A[*3]` : `A`가 쉬지 않고 **3클럭 연속** 참 (`A ##1 A ##1 A`를 줄여 쓴 것)
- `A[*1:4]` : `A`가 **1~4클럭 연속** 참
- `A[*1:$]` : `A`가 **1클럭부터 무한대(`$`, 끝이 정해지지 않음)까지 연속** 참
- 0(low) 유지를 보고 싶으면 `(!A)[*3]`처럼 부정해서 쓴다.

### 2. 신호 사이에 넣는 `##...` — 다음 신호를 몇 클럭 뒤에 볼까? (시간 이동)

- `##1` : 앞 구간이 끝난 뒤 **1클럭 뒤(다음 클럭)**로 이동
- `##N` : 정확히 **N클럭 뒤**로 이동
- `##[1:4]` : **1~4클럭 뒤 사이 어딘가**에 한 번이라도 참이면 합격
- **`##0` : 0클럭 이동 = 다음 클럭으로 넘어가지 않고, 앞 구간이 끝나는 바로 그 클럭에서 겹쳐서(동시에) 확인!**

```text
[##3 (3클럭 뒤에 한 번) vs [*3] (3클럭 내내 연속)]
클럭              E1   E2   E3   E4
req |-> ##3 ack : req  X    X    ack   (E4에만 1이면 합격)
req |-> busy[*3]: req  busy busy busy  (E1~E3 3클럭 연속 1이어야 합격)

[valid[*3] ##1 ready (다음 칸) vs valid[*3] ##0 ready (마지막 칸 겹침)]
valid[*3] ##1 ready : E1(valid=1) → E2(valid=1) → E3(valid=1) → E4(ready=1)
valid[*3] ##0 ready : E1(valid=1) → E2(valid=1) → E3(valid=1 이면서 동시에 ready=1!)
```

### 3. 실전 조합 예시 (`until_with` vs `[*1:$] ##0`)

"상대방이 `ready`를 줄 때까지 몇 클럭이든 `valid`를 계속 1로 유지해야 한다(핸드셰이크)"는 두 가지로 쓸 수 있다.

```systemverilog
// 방법 1: 원조 시퀀스 공식 — valid가 1로 쭉 이어지다가([*1:$]), 끝나는 바로 그 클럭에(##0) ready==1
assert property (@(posedge clk) disable iff (!rst_n)
  valid |-> (valid[*1:$] ##0 ready)
);

// 방법 2: until_with 키워드 — ready가 1이 되는 그 클럭까지 포함해 valid 유지
// (참고: 그냥 until은 ready가 1이 되기 '직전 클럭까지'만 확인)
assert property (@(posedge clk) disable iff (!rst_n)
  valid |-> (valid until_with ready)
);
```

## 빌딩 블록: property / sequence / implication

```text
sequence  : 시간에 걸친 신호 패턴       (예: a ##1 b ##2 c)
property  : sequence + 함의/부정 등 규칙 (예: a |-> b)
assert    : property가 참인지 검사
```

```systemverilog
// req가 올라간 다음 클럭부터, 1~5클럭 내 ack
property p_req_ack;
  @(posedge clk) disable iff (!rst_n)
  req |=> ##[0:4] ack;
endproperty
assert property (p_req_ack) else $error("req→ack timeout");
```

## 자주 쓰는 연산자 요약

| 연산자 | 의미 | 예 |
|---|---|---|
| `\|->` / `\|=>` | 함의 (같은 클럭 / 다음 클럭 `\|-> ##1`) | `valid \|-> ready` |
| `##0` | 앞 구간이 끝나는 **바로 그 클럭에 겹쳐서** | `valid[*1:$] ##0 ready` |
| `##N` / `##[m:n]` | 지연 / 지연 범위 | `a ##2 b`, `a ##[1:4] b` |
| `[*N]` / `[*m:n]` / `[*1:$]` | 연속 반복 (`$`는 무한대) | `busy[*3]`, `valid[*1:$]` |
| `until` / `until_with` | 조건까지 계속 유지 (미포함 / 해당 클럭 포함) | `valid until_with ready` |
| `[->N]` | go-to 반복 (N번째 발생까지) | `ack[->1]` |
| `$rose` / `$fell` | 상승/하강 엣지 | `$rose(req)` |
| `$stable` / `$past` | 값 유지 / 과거값 | `$stable(addr)`, `$past(data)` |
| `throughout` | 구간 내내 유지 | `(en) throughout (a ##1 b)` |
| `within` | 포함 | `s1 within s2` |

## disable iff — 리셋 중엔 검사 끄기

```systemverilog
assert property (@(posedge clk) disable iff (!rst_n)
  req |-> ##[1:4] ack);
```

> 리셋(`rst_n == 0`)이 걸리면 회로가 작업을 멈추고 초기화하므로 `ack`가 안 나오는 게 정상이다. `disable iff (!rst_n)`는 **리셋·예외 구간**에서 감시 카메라를 꺼서 가짜 에러(헛발)가 나지 않게 한다. 실무 SVA에서 거의 필수 세트.

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
