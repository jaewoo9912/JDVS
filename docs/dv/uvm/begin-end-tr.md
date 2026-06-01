# UVM Transaction Recording — `begin_tr` / `end_tr`

> 여러 신호에 흩어진 한 트랜잭션을 **시작~끝 경계를 가진 "막대(bar)" 하나**로 파형에 묶어 그려주는 UVM 기능.

## 핵심

- 파형의 신호(`valid`, `data`, `addr`…)는 **byte 수준**이라 "어디부터 어디까지가 한 트랜잭션인지" 경계와 의미가 안 보인다.
- `begin_tr` = 트랜잭션 **시작 시각 도장**, `end_tr` = **종료 시각 도장**. 그 사이의 모든 필드를 한 건으로 묶어 시뮬레이터 transaction DB에 등록 → 파형에 색깔 **막대**로 표시된다.
- 막대를 클릭하면 그 트랜잭션의 모든 필드(addr, len, data…)가 펼쳐진다.

## Before / After

```text
# recording 없음 — 신호만 보임
valid    ___┌───┐_______┌───┐___________
data     XX<A1><B2>XXXX<C3><D4>XXXXXXXXXX
addr     XX<100><104>XX<200><204>XXXXXXX

# recording 켜면 — 트랜잭션이 "막대"로
rdma_write ▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓
           │WRITE #1 │      │WRITE #2│
           │addr=100 │      │addr=200│   ← 클릭하면 모든 필드 표시
           └─시작 ─끝┘      └시작 ─끝┘
```

## 비유: CCTV 원본 영상 vs 영수증

| 마트 | 검증(파형) |
|---|---|
| **CCTV 원본 영상** — 모든 순간이 다 찍혀 있지만 "누가 뭘 샀다"는 요약이 없음. "3번째 손님 뭐 샀지?"를 알려면 영상을 돌려보며 직접 짜맞춰야 함 | **raw 신호** (`valid`/`data`/`addr`…) — 모든 클럭이 다 찍혀 있지만 "3번째 트랜잭션 뭐였지?"는 눈으로 짜맞춰야 함 |
| **영수증** — "14:32, 사과 3개, 12,000원" 거래 한 건을 시작 시각+내용으로 요약 | **recording된 트랜잭션 막대** — "WRITE #3, addr=200, len=8" 한 건을 요약 |

- `begin_tr` = 영수증의 **시작 시각 도장**, `end_tr` = **종료 시각 도장**.
- 그 사이의 모든 필드를 **영수증 한 장**처럼 묶어준다.

## 규칙

| 규칙 | 설명 |
|---|---|
| begin과 end는 **짝** | `begin_tr` 했으면 반드시 `end_tr` 해야 막대가 닫힘 (mandatory) |
| 시각을 **직접 줄 수 있다** | "지금"이 아니라 "아까 1000ns에 시작"이라고 소급 기록 가능 |
| **공짜가 아니다** | DB에 쓰는 비용 발생 → 보통 디버그 빌드에서만 켬 |
| 무대는 **waveform/DB** | 로그는 별도(`vmg_info`)이며, `begin_tr` 자체가 로그를 찍지는 않음 |

## 왜 중요한가

- recording 없이 디버깅하면 → 로그 grep으로 시간 추측 → 파형에 손으로 점프 → 신호를 눈으로 짜맞춰 트랜잭션 재구성 (수천 개면 지옥).
- 진가는 **scoreboard mismatch 디버깅**: expected/actual 두 트랜잭션 막대를 파형에서 시간 정렬해 나란히 놓으면 원인이 즉시 보인다.

## 이 프로젝트 현황

RDMA TB에는 driver/monitor가 많지만(`vrdma_pkt_monitor.svh`, `agent/driver/` 등) **recording을 전혀 쓰지 않는다** → 현재 RDMA write/read 트랜잭션이 파형에서 막대로 안 보인다.

---

## `begin_tr`는 누구 것인가 — 상속 관계

### 핵심

- `begin_tr` / `end_tr` / `accept_tr`는 **`uvm_transaction`에 정의**돼 있다.
- `uvm_sequence_item`은 `uvm_transaction`을 상속 → 우리가 만든 모든 item(예: `vcrc_axis_item`, `vmmu_ptw_item`)이 **공짜로 물려받는다.**
- 따라서 클래스에 한 줄도 안 써도 `item.begin_tr()`를 **바로 호출**할 수 있다. 새 메서드를 만들 필요가 없다.

### UVM 객체 족보

```text
uvm_object              ← 모든 UVM 데이터의 조상 (copy, compare, print…)
   │
   ▼
uvm_transaction         ← "시간"을 아는 데이터. ★ begin_tr / end_tr / accept_tr 정의 ★
   │
   ▼
uvm_sequence_item       ← 시퀀스가 다룰 수 있는 데이터 (sequencer/driver 핸드셰이크)
   │
   ▼
vmmu_ptw_item 등        ← 프로젝트의 실제 item (이미 begin_tr를 물려받은 상태)
```

### `uvm_transaction` vs `uvm_sequence_item`

| | `uvm_transaction` | `uvm_sequence_item` |
|---|---|---|
| 핵심 능력 | **시간 기록** (begin_tr/end_tr/accept_tr, timestamp, events) | 시간 기록 **+** 시퀀스/시퀀서 연동 |
| 실무에서 | 직접 상속하는 일은 드묾 | **거의 항상 이걸 상속** (이 프로젝트도 전부 이것) |

### 흔한 오해

- ❌ "`begin_tr`를 쓰려면 item을 `uvm_transaction`으로 바꿔 상속해야 한다" → **아니다.** `uvm_sequence_item`이 이미 자손이라 그대로 된다. 상속을 바꾸면 시퀀서 연동이 깨진다.
- ❌ "`begin_tr`는 driver가 가진 메서드다" → **아니다.** **item(트랜잭션)이** 가진 메서드이고, driver는 그걸 받아 `item.begin_tr()`로 **호출하는 쪽**일 뿐이다.

### 기억할 점

- `begin_tr`의 반환 타입은 **`integer`(핸들)** — "막대를 시작했다"는 영수증 번호표를 돌려준다.

### 이 프로젝트 코드

```systemverilog
// lib/submodule/metadata/mmu/agent/ptw/vmmu_ptw_item.svh
class vmmu_ptw_item extends uvm_sequence_item;  // ← uvm_transaction의 자손
  // ... 필드들 ...
endclass
// → 지금 당장 ptw_item.begin_tr() 호출 가능. 코드 한 줄 안 고쳐도 됨.
```

---

## `begin_tr`/`end_tr`를 어디서 호출하는가 — driver vs monitor

### 핵심 한 문장

> **driver는 "지금 시작!"을 실시간으로 알지만, monitor는 끝난 뒤에야 알아서 시작 시각을 거꾸로 적어야 할 수도 있다.**

### 비유: 요리사 vs 맛보는 사람

| | 누구 | 시작 시각 |
|---|---|---|
| **driver** | 직접 요리하는 사람 (직접 구동) | "지금"으로 찍으면 됨 → `begin_tr()` |
| **monitor** | 옆에서 맛만 보는 사람 (관찰) | 정체를 끝나고 알면 "아까 그때"로 소급 → `begin_tr(t_start)` |

### driver 예제 (요리사 — "지금" 찍기)

이 프로젝트 `lib/base/component/env/agent/driver/vrdma_driver.svh`의 실제 루프에 2줄 추가:

```systemverilog
forever begin
  this.seq_item_port.get_next_item(req);

  void'(req.begin_tr());   // ★ req 받자마자 "지금" 시작 도장 (handle 안 받으면 void')
  this.EntryPoint(req);    //   이 task 도는 동안 막대가 그려짐
  req.end_tr();            // ★ 구동 끝나면 "지금" 끝 도장

  this.seq_item_port.item_done();
end
```

### monitor 예제 (맛보기 — 정체를 나중에 알면 "과거로 소급")

```systemverilog
time t_start;
forever begin
  wait (vif.valid === 1'b1);
  t_start = $realtime;        // ★ 시작 시각을 박제 (예: 2000ns)
  collect_packet(tr);         // 다 관찰 (예: 2300ns까지)
  tr.begin_tr(t_start);       // ★ 시작은 "아까 2000ns"로 소급
  tr.end_tr($realtime);       // ★ 끝은 "지금 2300ns"
  ap.write(tr);
end
```

> ⚠️  monitor에서 인자 없이 `begin_tr()`를 쓰면 시작이 "지금"으로 찍혀 막대가 트랜잭션 뒤에 찌그러지거나 길이 0이 된다.

### 예외: AXI read처럼 "시작 때 정체를 아는" 프로토콜은 소급 불필요

AR이 오는 순간 이미 "read다, 주소는 이거다"를 알기 때문에 monitor라도 실시간 `begin_tr()`로 충분하다.

```systemverilog
forever begin
  @(posedge clk iff (arvalid && arready));   // AR 핸드셰이크 = 시작
  axi_rd = axi_read_item::type_id::create("axi_rd");
  axi_rd.addr = araddr; axi_rd.len = arlen;
  void'(axi_rd.begin_tr());                  // ★ AR 수락 → 시작 (소급 불필요)

  do @(posedge clk iff (rvalid && rready));
  while (!rlast);                            // 마지막 데이터 beat까지
  axi_rd.end_tr();                           // ★ rlast → 끝
  ap.write(axi_rd);
end
```

| 상황 | 시작 때 정체를 아는가 | begin_tr |
|---|---|---|
| AXI read | ✅ AR 보면 바로 앎 | `begin_tr()` 실시간 OK |
| 헤더 파싱 후에야 타입 판명 | ❌ 다 받아야 앎 | `begin_tr(t_start)` 소급 |

### 정밀 포인트

- "AR이 왔을 때"의 정확한 시점은 **AR 핸드셰이크 완료**(`arvalid && arready` 둘 다 1)인 클럭이다. arvalid만으로는 시작이 아니다.
- "요청 접수(AR)" vs "데이터 구동 시작"을 구분하고 싶으면 `begin_tr` 외에 **`accept_tr`** 를 쓴다 (→ 다음 주제).

---

## `accept_tr`와 트랜잭션 3단계 생명주기

### 3단계 생명주기

```text
accept_tr        begin_tr              end_tr
   │                │                    │
   ▼                ▼                    ▼
 [접수] ────대기──── [처리 시작] ──처리── [처리 끝]
```

| 단계 | 메서드 | 의미 | AXI read 예 |
|---|---|---|---|
| 1. 접수 | `accept_tr()` | 요청을 받았다 / 큐에 들어왔다 | AR 핸드셰이크 |
| 2. 시작 | `begin_tr()` | 실제로 일을 시작한다 | 첫 R 데이터 beat |
| 3. 끝 | `end_tr()` | 일이 끝났다 | RLAST |

- `accept`~`begin` = **대기 시간**(latency), `begin`~`end` = **처리 시간**
- 비유: 식당 — 주문 접수(accept) → 조리 시작(begin) → 완성(end). 접수~조리 사이가 대기.

### 호출 위치/기준은 전부 user가 정한다

UVM은 "빈 영수증 양식과 도장"만 준다. 언제 무슨 도장을 찍을지는 TB 작성자가 코드로 정한다. 자동으로 신호에서 찍어주지 않는다.

지켜야 할 룰 2가지:

```text
1. 시각 순서:   accept_tr ≤ begin_tr ≤ end_tr
2. begin/end는 짝:  begin_tr 했으면 반드시 end_tr (안 닫으면 막대가 끝까지 늘어짐)
```

### AXI에서 accept 기준 — 보통 핸드셰이크

AXI는 `valid && ready`가 둘 다 1일 때만 정보 전달이 "실제로" 일어난다. 그래서 기본 권장은 **핸드셰이크 기준**.

| 시점 | 의미 | 사용 |
|---|---|---|
| `arvalid && arready` | 실제로 접수/전송됨 | **기본 (권장)** |
| `arvalid == 1` | 요청 올려놓고 ready 기다리는 중 | AR backpressure latency를 따로 볼 때만 |

> 헷갈리면 accept·begin·end 전부 핸드셰이크(`valid && ready`) 엣지 기준으로 찍는 게 가장 안전.

### 파형에서 어떻게 보이나

- 눈에 보이는 **막대(bar)** = `begin_tr`~`end_tr` 구간뿐.
- `accept_tr` 시각은 막대 **속성(`accept_time` 필드)** 으로만 저장됨 → 막대 클릭 시 값으로 확인. 길이로는 안 그려짐.
- 대기를 *막대로* 보고 싶으면 user가 추가 작업: 막대 2개로 분리하거나 `begin_child_tr`로 중첩.

```text
 rdma_read   ─────▓▓▓▓▓▓▓▓▓▓▓──────   ← 막대 = begin~end
 [클릭 시]
   accept_time : 1000 ns   ← 필드로만 보임
   begin_time  : 1300 ns
   end_time    : 1500 ns
```

### `begin_tr` 위치만 옮기면 안 되나? — accept_tr가 존재하는 이유

`begin_tr` 하나는 **시각 1개**만 찍는다. 위치를 옮기면 "접수 시각"과 "처리 시작 시각" 중 **하나만** 갖고 다른 하나는 버린다.

`accept_tr`는 **같은 트랜잭션에 시각 슬롯을 하나 더** 달아준다 → 막대는 처리 구간(begin~end)으로 깔끔히 두면서 **접수 시각도 동시에 보존**. 이건 begin_tr 위치 조정으로 대체 불가.

존재 이유 3가지:

1. **시각 슬롯 추가** — 접수 시각을 막대를 안 건드리고 보존
2. **`accept_event` 발생** — 다른 컴포넌트가 "접수됨" 순간에 동기화(`wait`) 가능 (begin_event와 별개)
3. **의미 명확** — 코드에서 접수/처리시작 의도가 드러남

> 실무: 대기 latency가 검증 포인트가 아니면 accept_tr는 거의 안 쓴다. begin/end만으로 충분한 경우가 대부분이고, accept_tr는 옵션 도구다.
