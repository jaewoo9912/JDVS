# `bind` & 내부 신호(Arbiter / FSM) 검증

> **설계자의 RTL 원본 파일은 한 글자도 건드리지 않고**, 밖(`tb_top.sv` 등)에서 감시용 모듈(Assertion CCTV)을 DUT 내부에 찰싹 꽂아 넣는 기능.

---

## 1. `bind`란 무엇이고 왜 필요한가?

- DUT 내부 신호(예: FSM의 `state`, 버스 Arbiter의 `req`·`gnt`)는 바깥 포트(`input`/`output`)로 나와 있지 않고 **DUT 안쪽에만 숨어 있는 선**이다.
- 그렇다고 검증 엔지니어가 설계자의 RTL 원본(`my_dut.sv`)을 직접 열어 Assertion 코드를 적어 넣으면 원본이 더러워지고 합성(Synthesis) 시 문제가 생길 수 있다.
- **해결책 (`bind`)**: 검증 엔지니어가 **내 파일(`tb_top.sv`)에서 `bind` 한 줄만 적으면**, 시뮬레이터가 마치 처음부터 `my_dut.sv` 방 안쪽에 감시 모듈이 들어있었던 것처럼 연결해 준다.

```text
[원본 my_dut.sv] (절대 수정 안 함!)        [tb_top.sv에서 bind 1줄 실행!]
┌─────────────────────────┐              ┌───────────────────────────────┐
│ module my_dut           │              │ module my_dut                 │
│   logic [1:0] state;    │   =======>   │   logic [1:0] state;          │
│   logic       req, gnt; │              │   logic       req, gnt;       │
│                         │              │   ┌─────────────────────────┐ │
└─────────────────────────┘              │   │ my_checker u_chk (CCTV) │ │
                                         │   │  → state, req, gnt 감시 │ │
                                         │   └─────────────────────────┘ │
                                         └───────────────────────────────┘
```

---

## 2. `bind` 문법 공식과 파일 3개 구조

### 문법 공식

일반 모듈 인스턴스 생성 문법(`모듈이름 인스턴스이름 (.포트(신호));`) 맨 앞에 **`bind [붙일 대상(DUT)]`**만 붙이면 된다.

> **`bind [붙일 대상(DUT)]  [끼워 넣을 감시 모듈]  [인스턴스 이름] ( .감시모듈_포트(DUT_내부신호) );`**

---

### 실제 파일 3개 작성 예시

```systemverilog
// ① 설계자의 원본 파일 (my_dut.sv) — 우린 절대 수정하지 않음!
module my_dut (input logic clk, rst_n);
  logic [1:0] state;     // 내부 신호 (바깥 포트로 안 나와 있음)
  logic       req, gnt;  // 내부 신호
  // ... 설계 코드 ...
endmodule
```

```systemverilog
// ② 내가 만든 감시 모듈 파일 (my_checker.sv) — 감시할 신호만 input으로 선언
module my_checker (
  input logic       clk, rst_n,
  input logic [1:0] state,
  input logic       req, gnt
);
  property p_req_gnt;
    @(posedge clk) disable iff (!rst_n)
    req |=> gnt;
  endproperty
  a_req_gnt: assert property (p_req_gnt);
endmodule
```

```systemverilog
// ③ 테스트벤치 파일 (tb_top.sv) — 여기서 bind 한 줄로 장착!
module tb_top;
  logic clk, rst_n;

  my_dut u_dut (.clk(clk), .rst_n(rst_n));

  // ★ my_dut 방 안에 my_checker를 u_chk라는 이름으로 꽂아 넣어라!
  bind my_dut my_checker u_chk (
    .clk   (clk),
    .rst_n (rst_n),
    .state (state),   // u_dut.state가 아니라 my_dut 안의 신호 이름 그대로 적음!
    .req   (req),
    .gnt   (gnt)
  );
endmodule
```

---

### `bind` 사용 시 꼭 알아야 할 핵심 3가지

| 질문 | 정답 및 이유 |
| --- | --- |
| **① `.clk(clk)`에서 누가 감시 모듈 포트고 누가 DUT 신호인가?** | **점(`.`)이 붙은 쪽이 감시 모듈(`u_chk`)의 `input` 포트**이고, **괄호 `()` 안이 `my_dut`의 내부 신호**다 (`.chk_clk(dut_clk)`). `bind my_dut`를 적는 순간 `my_dut` 방 안으로 들어간 셈이다. |
| **② DUT 내부 신호 1,000개를 다 적어야 하나?** | **아니다!** `my_checker`에는 내가 감시할 신호 3~4개만 `input`으로 선언해 연결하면 된다. 포트 이름을 DUT 내부 신호 이름과 똑같이 맞췄다면 **`bind my_dut my_checker u_chk (.*);`** 한 줄로 끝난다. |
| **③ `bind` 모듈에 `output` 포트가 있을 수 있나?** | **없다 (100% `input` 전용)!** 감시만 해야지 DUT 내부 신호를 구동(`output`)하면 안 되므로 문법적으로도 금지된 **읽기 전용 CCTV**다. |

---

## 3. 실전 예제: 2x2 AXI Bus Round-Robin Arbitration 감시

**상황**: Master 0(`m0_req`)과 Master 1(`m1_req`)이 동시에 Slave 하나를 쓰려고 경쟁할 때, **Round-Robin(번갈아 양보하기: 이번에 M0이 이겼으면 다음 동시 요청 때는 무조건 M1이 이겨야 함)** 규칙이 지켜지는지 `bind`로 검증해 보자.

```systemverilog
// 설계자의 2x2 AXI 버스 내부 (axi_2x2_bus.sv)
module axi_2x2_bus (input logic aclk, aresetn);
  logic m0_req, m1_req;  // Master 0, Master 1의 요청 (내부 신호)
  logic m0_gnt, m1_gnt;  // Arbiter의 허락(grant) 결과 (내부 신호)
endmodule
```

---

### 1단계 시도: `##1`로 바로 다음 클럭만 확인했을 때의 한계

```systemverilog
// ⚠️ 한계가 있는 코드: 바로 다음 클럭(##1)에 연달아 동시 요청할 때만 잡힘!
(m0_req && m1_req && m0_gnt) ##1 (m0_req && m1_req) |-> m1_gnt;
```

- **문제점**: 위 식은 `##1` 때문에 **바로 다음 클럭**에 연달아 요청할 때만 검사한다. 만약 M0이 이긴 뒤 **2클럭이나 10클럭 쉬었다가** 다시 동시 요청이 들어오면, 1초 전에 누가 이겼었는지 까먹어버려 검사하지 못한다.

---

### 2단계 실무 정석: 감시 모듈 안에 "마지막 승자 수첩(`last_win`)" 두기

몇 클럭 뒤에 동시 요청이 오든 상관없이 잡으려면, 감시 모듈 안에 **"마지막에 누가 이겼는지 적어두는 1비트 플립플롭 수첩(`last_win`, Auxiliary Code)"**을 하나 둔다.

```text
클럭        :  E1 (M0 승!)    E2 (조용)     E3 (조용)     E4 (둘 다 동시에 손듦!)
수첩 기록   :  last_win = 0 ──(0 유지)───────(0 유지)────> 수첩이 0(M0)이니 이번엔 무조건 M1 승(m1_gnt=1)이어야 함!
```

```systemverilog
// 감시 모듈 (rr_checker.sv)
module rr_checker (
  input logic aclk, aresetn,
  input logic m0_req, m1_req,
  input logic m0_gnt, m1_gnt
);
  logic last_win;  // 마지막 승자 수첩 (0: 마지막에 M0 승, 1: 마지막에 M1 승)

  // ① 누군가 이길 때마다 수첩에 적어둠 (몇 클럭이 지나도 계속 기억!)
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn)     last_win <= 1'b1;
    else if (m0_gnt)  last_win <= 1'b0;  // 마지막 승자 = M0 기록
    else if (m1_gnt)  last_win <= 1'b1;  // 마지막 승자 = M1 기록
  end

  // ② 언제든 둘이 동시에 요청하면, 수첩에 적힌 마지막 승자의 반대쪽이 이겨야 함!
  property p_rr_m1_turn;
    @(posedge aclk) disable iff (!aresetn)
    (m0_req && m1_req && last_win == 1'b0) |-> m1_gnt;
  endproperty
  a_rr_m1_turn: assert property (p_rr_m1_turn);
  c_rr_m1_turn: cover  property (p_rr_m1_turn);

  property p_rr_m0_turn;
    @(posedge aclk) disable iff (!aresetn)
    (m0_req && m1_req && last_win == 1'b1) |-> m0_gnt;
  endproperty
  a_rr_m0_turn: assert property (p_rr_m0_turn);
  c_rr_m0_turn: cover  property (p_rr_m0_turn);
endmodule

// 테스트벤치 (tb_top.sv)에서 한 줄로 장착!
bind axi_2x2_bus rr_checker u_rr_chk (.*);
```

!!! tip "핵심 포인트: 보조 코드 (Auxiliary Code)"
    Assertion 식 안에서 몇 클럭 뒤인지(`##2`, `##10`...)를 힘들게 세지 않고, 감시 모듈 안에 간단한 **`always_ff` 수첩 변수(`last_win`)**를 하나 두면 아무리 긴 시간이 지난 뒤의 이벤트라도 현재 클럭(`|->`)에서 깔끔하게 검사할 수 있다.
