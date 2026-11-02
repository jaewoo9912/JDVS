# `property` & `assert` / `cover` / `assume`

> 규칙(`property`)을 분리해 정의하고 **`assert`(단속) / `cover`(출석 도장) / `assume`(입력 전제)**로 용도를 나누는 실무 표준, **Vacuous Pass 함정**, 그리고 실전 해석 Q&A.

---

## 1. `property` 분리 문법 & `assert` / `cover` / `assume` 3총사

### 1) 한 줄 작성 vs `property` 분리 작성 (실무 표준)

실무에서는 타이밍 규칙(`property`)을 먼저 정의해 두고, 그 아래에서 용도(`assert` / `cover` / `assume`)를 정해 끼워 넣는 **2단 분리 스타일**을 많이 쓴다. 같은 규칙 하나를 `assert`와 `cover`에 동시에 재사용할 수 있기 때문이다.

```systemverilog
// 스타일 1: 한 줄로 합쳐 쓰기
// [이름]: assert property ( @[클럭] disable iff ([리셋]) [알맹이 식] );
a_req_ack: assert property (@(posedge clk) disable iff (!rst_n) req |=> ack);

// 스타일 2: property(규칙 내용물)를 먼저 정의하고, 아래에서 용도(assert/cover) 지정하기
property p_req_ack;
  @(posedge clk) disable iff (!rst_n)
  req |=> ack;
endproperty

a_req_ack: assert property (p_req_ack);   // 에러 감시용으로 사용
c_req_ack: cover  property (p_req_ack);   // 출석 체크용으로 재사용!
```

---

### 2) `assert` / `cover` / `assume` 차이 (신호등 단속 카메라 비유)

안쪽 `property` 식은 똑같고, 맨 앞 키워드로 **"이 식을 왜 적어놨는지(목적)"**만 구분한다.

| 지시어 | 비유 | 역할 | 좋은 결과 기준 |
| --- | --- | --- | --- |
| **`assert property`** | **과속·신호위반 단속 카메라** | 규칙을 어기는 순간 즉시 `$error` 출력 | **Fail `0회`**여야 좋음 |
| **`cover property`** | **교통량 체크 카운터 (출석 도장)** | 그 상황이 실제로 몇 번 일어났는지 카운트 | **Hit `1회 이상`**이어야 좋음 |
| **`assume property`** | **"운전자는 면허가 있다"는 전제** | 입력 신호가 이 규칙을 지킨다고 가정 (Formal은 입력 범위 한정, 시뮬레이션은 TB 입력 감시) | 위반 `0회` |

!!! warning "왜 `assert` 옆에 반드시 `cover`를 짝으로 달아야 할까? (Vacuous Pass 함정)"
    도로에 단속 카메라(`assert`)를 달았는데 **새벽이라 차(`req`)가 한 대도 안 지나갔다면?** 위반 건수는 `0건`으로 뜨지만, 차가 아예 안 다녔으니 신호등을 진짜로 검증한 것이 아니다(**Vacuous Pass, 가짜 통과**).

    그래서 옆에 통행량 카운터(`cover`)를 함께 달아 **`Hit 0회`면 "에러는 안 났지만 아직 이 상황을 테스트조차 안 해봤구나!"** 하고 즉시 잡아낸다.

---

### 3) 실제 코드 & 시뮬레이션 리포트 4가지 상황

```systemverilog
module dut_checker (
  input logic clk, rst_n,
  input logic req,   // TB가 DUT에 넣는 입력
  input logic ack    // DUT가 내보내는 출력
);
  // ① assert (단속 카메라): req가 오면 다음 클럭에 무조건 ack가 와야 함
  a_req_ack: assert property (@(posedge clk) disable iff (!rst_n)
    req |=> ack
  ) else $error("위반! req 다음 클럭에 ack 없음!");

  // ② cover (통행량 카운터): req 다음 클럭에 ack가 오는 장면이 실제로 몇 번 나왔나?
  c_req_ack: cover property (@(posedge clk) disable iff (!rst_n)
    req ##1 ack
  );

  // ③ assume (입력 전제조건): TB는 ack 전에 req를 2클럭 연속 안 보낸다고 가정
  m_no_b2b_req: assume property (@(posedge clk) disable iff (!rst_n)
    req |=> !req
  );
endmodule
```

| 시뮬레이션 상황 | `a_req_ack` (`assert`) | `c_req_ack` (`cover`) | 판정 |
| --- | --- | --- | --- |
| **① TB 고장으로 `req`를 한 번도 안 보냄** | Fail `0회` (통과처럼 보임) | **Hit `0회` 🚨** | `cover` 덕분에 `req` 미인가 즉시 발각! |
| **② `req` 10번 전송 & 10번 모두 다음 클럭 `ack` 응답** | **Fail `0회` ✅** | **Hit `10회` ✅** | 진짜로 10번 시험했고 모두 통과 확신 |
| **③ `req` 보냈는데 DUT 버그로 다음 클럭 `ack=0`** | **즉시 `$error` (Fail `1회`) 🚨** | Hit `0회` | DUT 버그 발생 즉시 검출 |
| **④ TB 실수로 `req`를 2클럭 연속(`1→1`) 전송** | — | — | `m_no_b2b_req` (`assume`)가 TB 입력 약속 위반 알림 |

---

## 2. 실전 코드 해석 점검 Q&A (3문제)

???+ question "Q1. `$rose` + `|->` + `##[1:3]` 해석하기"
    ```systemverilog
    property p1;
      @(posedge clk) disable iff (!rst_n)
      $rose(cmd_valid) |-> ##[1:3] cmd_ack;
    endproperty
    a1: assert property (p1);
    ```

    - **해석**: 리셋 상태가 아닐 때, `posedge clk`에서 `cmd_valid`가 `0 → 1`로 올라간 **바로 그 클럭(`|->`, 0칸)을 기준으로 1~3클럭 이내**에 `cmd_ack`가 `1`로 떠야 한다.
    - **주의**: 화살표가 `|=>`가 아니라 **`|->`**이므로 "다음 클럭부터 1~3클럭 뒤(=2~4클럭)"가 아니라 **"올라간 그 클럭 기준 1~3클럭 뒤"**다.

???+ question "Q2. 대기 중 신호·주소 유지 감시 (`|=>` + `$stable`)"
    ```systemverilog
    property p2;
      @(posedge clk) disable iff (!rst_n)
      (req && !gnt) |=> req && $stable(addr);
    endproperty
    a2: assert property (p2);
    ```

    - **해석**: 리셋이 아닐 때, 이번 클럭에 `req == 1`이고 `gnt == 0`(아직 허락 못 받음)이면, **다음 클럭(`|=>`)에도 `req`는 `1`을 유지하고 `addr`은 이전 클럭의 값과 같아야(`$stable`)** 한다.

???+ question "Q3. 연속 유지 후 완료 시나리오 출석 체크 (`[*4]` + `##1` + `cover`)"
    ```systemverilog
    property p3;
      @(posedge clk) disable iff (!rst_n)
      start |=> run[*4] ##1 done;
    endproperty
    c3: cover property (p3);
    ```

    - **해석**: `start == 1`이 된 **다음 클럭(`|=>`)부터 `run`이 4클럭 연속 `1`로 유지**되고, 그 **바로 다음 클럭(`##1`)에 `done == 1`**이 발생해야 통과한다.
    - **왜 `cover`인가?**: 에러를 잡으려는 것이 아니라, **이 시나리오가 시뮬레이션 중 실제로 최소 1번 이상 일어났는지(출석 도장)** 확인하기 위해서다.

---

- **어디에 적나**: 포트 신호는 주로 **`interface`** 안에 적고, 포트로 나와 있지 않은 DUT 내부 신호(FSM `state`, Arbiter `req`/`gnt` 등)는 원본 수정 없이 **[`bind`로 외부에서 꽂아 넣어 감시](bind.md)**한다.
