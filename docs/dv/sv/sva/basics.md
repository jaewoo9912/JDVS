# Assertion 기본 — Immediate vs Concurrent & `|->` / `|=>`

> Assertion의 **기본 뼈대**(클럭·`disable iff`·방아쇠→결과), **Immediate vs Concurrent** 구분, 그리고 결과 확인 시점을 정하는 두 화살표 **`|->`(0칸) / `|=>`(1칸)** 정리.

---

## 1. 핵심 개념 & 기본 뼈대

- **Scoreboard vs Assertion**: Scoreboard가 최종 **결과값**을 비교한다면, Assertion은 그 사이의 **프로토콜·타이밍 규칙**(handshake, FSM 전이, 신호 안정성)을 신호 레벨에서 직접 감시한다.
- **목적**: 버그가 뒷단으로 퍼지기 전에 **발생 지점·클럭에서 즉시** 잡는다.

```systemverilog
// 기본 뼈대: 클럭마다 감시하되, 리셋 중엔 끄고, [방아쇠]가 맞으면 [결과]를 확인!
assert property (@(posedge clk) disable iff (!rst_n)
  (state == IDLE && start) |=> (state == BUSY)
) else $error("IDLE에서 start 후 BUSY 전이 실패!");
```

| 구성 요소 | 역할 |
| --- | --- |
| **`@(posedge clk)`** | 감시 카메라가 사진을 찍을 기준 클럭 |
| **`disable iff (!rst_n)`** | 리셋(`rst_n == 0`) 중에는 감시를 꺼서 가짜 에러(헛발) 방지 |
| **왼쪽 (`state == IDLE && start`)** | 언제 감시를 시작할지 (**선행조건 / 방아쇠**) |
| **오른쪽 (`state == BUSY`)** | 그때 반드시 일어나야 하는 일 (**후행결과**) |

---

## 2. 두 종류 — Immediate vs Concurrent (`property`의 유무)

비유하면 **그 순간 찍는 사진 한 장(Immediate)**이냐, **매 클럭마다 계속 찍는 CCTV 동영상(Concurrent)**이냐의 차이다. 코드에서 가장 확실한 구분 기준은 **`property` 키워드의 유무**다.

| 구분 | Immediate (`assert (...)`) | Concurrent (`assert property (...)`) |
| --- | --- | --- |
| **비유** | 그 줄을 지나는 순간 찍는 **사진 한 장** | 클럭마다 백그라운드로 계속 찍는 **CCTV 동영상** |
| **문법 구분** | **`property` 없음** (`if`문에서 `if`만 `assert`로 바꾼 모양) | **`property` 있음** (`@(posedge clk)`, `disable iff` 포함) |
| **시간 기호 (`##`, `\|->`, `\|=>`, `[*]`)** | **사용 불가** (현재 순간의 참/거짓 식만 가능) | **사용 가능** (여러 클럭에 걸친 시간 순서·반복 표현) |
| **적는 위치** | `always_comb`, `initial`, `task/function` 블록 **안** | `module`, `interface` **안** (절차 블록 바깥) |
| **글리치 영향** | 그대로 받음 (과도기 가짜 에러 가능 → `assert final`로 보완) | 안 받음 (클럭 엣지의 안정된 값만 샘플링) |

```systemverilog
// ① Immediate (property 없음) — 블록 안에서 "지금 당장 이 값이 맞나"만 체크
always_comb begin
  assert (!(a && b)) else $error("a와 b가 동시에 1임!");
end

// ② Concurrent (property 있음) — 한 줄로 쓰거나, property에 이름을 붙여 두 줄로 분리
assert property (@(posedge clk) disable iff (!rst_n)
  req |-> ##[1:5] ack
);

// (실무에서 자주 쓰는 두 줄 분리형 — assert property가 있으면 무조건 Concurrent!)
property p_handshake;
  @(posedge clk) disable iff (!rst_n)
  valid |-> ##[1:3] ready;
endproperty
a_handshake: assert property (p_handshake);
```

!!! note "왜 조합 논리 결과를 검사할 때도 `@(posedge clk)`를 쓸까?"
    조합 논리(`assign done_pulse = (state == DONE);`) 자체는 클럭과 무관하게 즉시 바뀌지만, 클럭과 클럭 사이(과도기)에는 **글리치**가 튀거나 시뮬레이터 내부 실행 순서 차이로 찰나의 불일치가 생길 수 있다.

    따라서 **"계산과 글리치가 다 가라앉아 조용해진 `posedge clk` 정각에만 사진을 찍되, 같은 사진 안에 두 조건이 함께 맞는지(`|->`) 확인하라"**는 뜻으로 `@(posedge clk)`를 쓴다.

---

## 3. 화살표 두 개: `|->` (0칸 이동) vs `|=>` (1칸 이동)

| 화살표 | 이름 | 보드게임 칸 이동 | 결과 확인 시점 | 주로 쓰는 곳 |
| --- | --- | --- | --- | --- |
| **`\|->`** | overlapped implication | **0칸 이동** (`\|-> ##0`과 동일) | 조건이 맞은 **바로 그 클럭** | 조합 논리 출력처럼 **즉시** 나와야 하는 결과 |
| **`\|=>`** | non-overlapped implication | **1칸 이동** (`\|-> ##1`과 동일) | 조건이 맞은 **다음 클럭** | 플립플롭(`always_ff`, `<=`)을 거쳐 **1클럭 뒤에** 나오는 결과 |

### 뒤에 `##숫자`가 붙을 때 칸 계산법 (덧셈 규칙)

**`|->`는 `0칸`**, **`|=>`는 `1칸`**으로 놓고 뒤에 붙은 `##숫자`를 그대로 더하면 몇 번째 클럭에서 확인하는지 바로 나온다.

```text
클럭 칸 :  [E1] ──1칸──> [E2] ──1칸──> [E3]
req     :   1
|-> ##1 :  (0칸) ──────> E2에서 ack 확인! (0 + 1 = 1칸 뒤)
|=> ##1 :        (|=>로 1칸) ──(##1로 1칸)──> E3에서 ack 확인! (1 + 1 = 2칸 뒤)
```

| 식 | 칸 덧셈 | 의미 |
| --- | --- | --- |
| `req \|-> ##1 ack` | `0 + 1 = 1칸 뒤` | `req |=> ack`와 완전히 동일 (다음 클럭 E2에서 확인) |
| `req \|=> ##1 ack` | `1 + 1 = 2칸 뒤` | 다다음 클럭(E3)에서 확인 |
| `req \|-> ##[1:10] ack` | `0 + (1~10)` | **1~10클럭 이내**에 `ack` 확인 (숫자가 직관적이라 실무 권장) |
| `req \|=> ##[1:10] ack` | `1 + (1~10)` | **2~11클럭 이내**에 `ack` 확인 |
