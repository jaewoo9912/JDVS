# 기본 — rand / randomize() / randc

## rand & randomize() 기본

### 두 축의 역할

- **`rand`** : "이 필드는 무작위화 **대상**"이라는 **마킹**
- **`randomize()`** : "지금 그 필드들에 새 값 뽑아"라는 **명령**

→ 마킹과 실행이 분리되어 있다. **`new()` 한다고 자동 무작위 아님** — `randomize()` 명시 호출 필요.

### 골격

```systemverilog
class Packet;
  rand bit [7:0]  addr;
  rand bit [31:0] data;
       bit        valid = 1;   // rand 없음 → 무작위화 안 됨
endclass

Packet p = new();
if (!p.randomize()) `uvm_fatal("PKT", "randomize failed")
```

### 핵심 규칙

- **R1**: `rand` 마킹된 필드만 새 값. 안 붙은 필드는 그대로
- **R2**: `randomize()` 반환값 `1`(성공) / `0`(실패). **반드시 체크**
- **R3**: 실패 시 rand 필드는 **이전 값 그대로** → 안 체크하면 조용한 버그
- **R4**: 여러 번 호출 가능. 매번 새 값
- **R5**: 모든 class에 **자동 제공**됨 (built-in)

### `rand` 가능 타입

- ✅ `bit` / `logic` / `int` / `byte` / `shortint` / `longint` / `integer`, packed `struct` / `union`, dynamic array(크기+원소), associative array, queue, class handle(재귀)
- ❌ `real` / `realtime` / `string` / `event` / `chandle`

### `randomize()` 세 형태

- `p.randomize();` — **모든** rand 필드
- `p.randomize(addr);` — **지정 필드만**
- `p.randomize() with { ... };` — **inline constraint** ([상세](with-soft.md))

### 호출 컨벤션

```systemverilog
if (!handle.randomize()) `uvm_fatal("TAG", "msg")
// 또는
assert(handle.randomize());
```

---

## rand vs randc

| | 의미 | 분포 보장 |
| --- | --- | --- |
| **`rand`**  | 매 호출 **독립 추출**                  | 평균적 균등 (단기 편차 큼) |
| **`randc`** | 사이클 안에서 모든 값을 **1번씩 (순열)** | **사이클 단위 결정적 균등** |

### randc 핵심 — "덱 뽑기" 비유

`randc` 변수의 도메인을 **카드 한 벌**이라 생각하자:

- 카드 = 도메인의 가능한 값 전체 (예: `bit [1:0]` → `{0,1,2,3}` 4장)
- `randomize()` 한 번 호출 = **카드 한 장 뽑기**
- 덱이 비면 → **다시 채우고 셔플**해서 새로 시작
- **1 사이클** = 덱을 다 뽑아 비우는 1바퀴

### 사이클 동작 예 (`randc bit [1:0]`, 8번 호출)

```text
[사이클 1 — 덱 셔플 예: 2, 0, 3, 1]
call 1 → 2
call 2 → 0
call 3 → 3
call 4 → 1    (덱 빔)

[사이클 2 — 덱 재충전 + 셔플 예: 1, 3, 0, 2]
call 5 → 1
call 6 → 3
call 7 → 0
call 8 → 2
```

→ 8번 호출 = **정확히 2 사이클** = 각 값이 **정확히 2번씩 (편차 0)**.

### 사이클 안과 밖

- **사이클 안**: 같은 값 **절대 두 번 안 나옴** (뽑힌 카드 빠지니까)
- **사이클 경계** 넘으면 가능 (`call 4 = 1`, `call 5 = 1` 처럼 연달아도 가능)

### randc가 빛나는 경우

- **작은 도메인**을 빠짐없이 한 번씩 훑고 싶을 때
- 예: opcode 4종, 채널 ID 0~7, 시나리오 0~9
- **"모든 값 커버 보장"**이 필요한 시나리오

### randc가 무의미한 경우

- 큰 도메인 (`randc int x` 등) → 사이클 자체가 우주적 크기, **오버헤드만**
- → `randc`는 **비트폭 작은 변수 전용**

---

## 흔한 오해

- ❌ `new()`만 해도 rand 필드에 값 들어있음 → 아님. **`randomize()` 필요**
- ❌ `randomize()`는 항상 성공 → 아님. **모순/실패 가능**
- ❌ `randc`가 "통계적 균등" → 아님. **사이클 단위 순열** (모든 값 정확히 1번씩, 순서만 무작위)
