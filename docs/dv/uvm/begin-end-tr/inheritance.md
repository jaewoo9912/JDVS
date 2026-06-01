# `begin_tr`는 누구 것인가 — 상속 관계

## 핵심

- `begin_tr` / `end_tr` / `accept_tr`는 **`uvm_transaction`에 정의**돼 있다.
- `uvm_sequence_item`은 `uvm_transaction`을 상속 → 우리가 만든 모든 item(예: `vcrc_axis_item`, `vmmu_ptw_item`)이 **공짜로 물려받는다.**
- 따라서 클래스에 한 줄도 안 써도 `item.begin_tr()`를 **바로 호출**할 수 있다. 새 메서드를 만들 필요가 없다.

## UVM 객체 족보

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

## `uvm_transaction` vs `uvm_sequence_item`

| | `uvm_transaction` | `uvm_sequence_item` |
|---|---|---|
| 핵심 능력 | **시간 기록** (begin_tr/end_tr/accept_tr, timestamp, events) | 시간 기록 **+** 시퀀스/시퀀서 연동 |
| 실무에서 | 직접 상속하는 일은 드묾 | **거의 항상 이걸 상속** (이 프로젝트도 전부 이것) |

## 흔한 오해

- ❌ "`begin_tr`를 쓰려면 item을 `uvm_transaction`으로 바꿔 상속해야 한다" → **아니다.** `uvm_sequence_item`이 이미 자손이라 그대로 된다. 상속을 바꾸면 시퀀서 연동이 깨진다.
- ❌ "`begin_tr`는 driver가 가진 메서드다" → **아니다.** **item(트랜잭션)이** 가진 메서드이고, driver는 그걸 받아 `item.begin_tr()`로 **호출하는 쪽**일 뿐이다.

## 기억할 점

- `begin_tr`의 반환 타입은 **`integer`(핸들)** — "막대를 시작했다"는 영수증 번호표를 돌려준다.

## 이 프로젝트 코드

```systemverilog
// lib/submodule/metadata/mmu/agent/ptw/vmmu_ptw_item.svh
class vmmu_ptw_item extends uvm_sequence_item;  // ← uvm_transaction의 자손
  // ... 필드들 ...
endclass
// → 지금 당장 ptw_item.begin_tr() 호출 가능. 코드 한 줄 안 고쳐도 됨.
```
