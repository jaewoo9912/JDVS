# Constraint Expression

## 도구 인벤토리

| 도구 | 용도 | 한 줄 정의 |
| --- | --- | --- |
| `inside`         | 집합 멤버십      | "이 값들 / 범위 중 하나" |
| `->`             | 조건부 제약      | "A면 B다" |
| `if-else`        | 다중 분기        | implication의 else 있는 형태 |
| `dist`           | 가중치 분포      | "이 값들을 이 비율로" ([분포 제어](distribution.md)) |
| `foreach`        | 배열 원소 제약   | 각 원소마다 조건 |
| `solve...before` | 분포 조정        | 변수 결정 순서 지정 ([솔버](solver.md)) |

---

## `inside` — 집합/범위 멤버십

```systemverilog
constraint c {
  addr inside {[0:255], 32'h1000, 32'h2000};   // 범위 + 단일값 혼합
  op   inside {READ, WRITE, SEND};             // 열거형
  size !inside {0, 3, 5};                      // 부정
}
```

- 지원: 단일값 `{0,1,2}`, 범위 `{[0:99]}`, 혼합 `{0,[10:20],100}`, 배열 변수 `{my_arr}`
- **안티패턴**: `op == A || op == B || op == C` → **`op inside {A,B,C}`**로 단순화

---

## `->` (implication) — 조건부 제약

### 의미

"A가 참이면 B도 참이어야 한다."
거짓이 되는 케이스는 단 하나: **A 참 + B 거짓**.

### 진리표

| A | B | `A -> B` |
| --- | --- | --- |
| T | T | T (의무 이행) |
| T | F | **F** (의무 위반 — 유일한 거짓) |
| F | T | T (의무 미발동 → 자동 만족) |
| F | F | T (의무 미발동 → 자동 만족) |

### 핵심 — 의무 없음 (vacuous truth)

- A가 거짓이면 **규칙 자체가 발동 안 함**
- 발동 안 한 규칙은 위반도 없음 → 자동 만족
- 비유: *"비 오면 우산 쓴다"* 약속. **비 안 오는 날은 우산 쓰든 말든 약속 위반 아님.**

### 동치 표현

`A -> B` ≡ `!A || B`

### 사용

```systemverilog
constraint c {
  op == READ  -> size <= 64;
  op == WRITE -> addr % 4 == 0;
}
```

### 다중 줄 묶기

```systemverilog
constraint c {
  op == READ -> {
    size <= 64;
    addr < 32'h1000;
  }   // 두 조건 모두 만족해야 함 (AND)
}
```

### 다중 implication은 AND로 결합

```systemverilog
constraint c {
  op == READ -> size <= 64;        // 줄 1
  op == READ -> addr < 32'h1000;   // 줄 2
}
// = op == READ 면 두 조건 모두 만족 (AND)
```

---

## `if-else` — else 있을 때 더 명확

```systemverilog
constraint c {
  if (op == READ) {
    size <= 64;
    addr < 32'h1000;
  } else if (op == WRITE) {
    size <= 128;
    addr % 4 == 0;
  } else {
    size == 0;
  }
}
```

### `->` vs `if-else`

| | implication (`->`) | `if-else` |
| --- | --- | --- |
| else 없는 단일 조건 | ✅ 깔끔        | 장황 |
| else / 다중 분기    | else 표현 어색 | ✅ 깔끔 |
| 솔버 입장 의미      | 동일           | 동일 |

→ **else 없으면 implication, else 있으면 if-else.** 가독성 기준.

---

## `foreach` — 배열 원소 제약

```systemverilog
rand int data[];
constraint c {
  data.size inside {[1:100]};
  foreach (data[i]) {
    data[i] inside {[0:255]};
    if (i > 0) data[i] > data[i-1];   // 단조 증가
  }
}
```

### 규칙

- `foreach` 인덱스는 **정적 표현만** (`i`, `i-1`, `i+1` OK)
- **rand 변수를 인덱스로 사용 금지** (예: `data[n-i-1]` where `n` is rand) → 솔버 처리 불안정
- 인접 원소 참조: `if (i > 0) data[i] vs data[i-1]` 패턴

### 안티패턴 — mirror 비교의 자기모순

```systemverilog
// ❌ 잘못된 코드
foreach (data[i]) data[i] > data[n-i-1];
// n=4 면:
//   i=0: data[0] > data[3]
//   i=3: data[3] > data[0]   ← 모순!
// → 해 없음, randomize 항상 실패
```

모든 mirror 쌍에 *"내가 너보다 크다"*를 동시에 요구 → **거울 보고 자기 자신과 우기기** → 불가능.

수정 (의도에 따라):

- 단조 증가: `if (i > 0) data[i] > data[i-1];`
- 단조 감소: `if (i > 0) data[i] < data[i-1];`
- mirror 비교가 진짜 의도였다면 → 의도 자체 재검토 (수학적으로 불가능)

---

## `->` vs `solve...before` — 개념적 차이

| | `->` (implication) | `solve...before` |
| --- | --- | --- |
| 정체              | 논리적 제약 (값에 대한 법) | 솔버 힌트 (뽑기 습관) |
| 영향              | **유효 해 집합 변경**        | **분포만 변경**, 유효성 무관 |
| 결과만 봐서 검증  | ✅ 가능 (값으로 확인)        | ❌ 불가 (솔버 내부 동작) |
| 비유              | **법** — 무엇이 허용되는가   | **습관** — 허용된 것 중 무엇을 자주 고르나 |

→ 다른 차원의 도구. 실무에선 같이 쓴다:

- **`->`로 유효성 정의** (어떤 op면 어떤 size 가능)
- **`solve before`로 분포 보정** (op 균등 커버리지) — [상세](solver.md)

---

## 리팩토링 패턴 — 자주 쓰는 변환

**Before**

```systemverilog
constraint c {
  op == READ || op == WRITE || op == SEND;
  op == READ -> addr == 0 || addr == 4 || addr == 8;
  op != READ -> addr < 1024 && addr >= 0;
}
```

**After**

```systemverilog
constraint c {
  op  inside {READ, WRITE, SEND};
  op == READ -> addr inside {0, 4, 8};
  op != READ -> addr inside {[0:1023]};
}
```

- OR 체인 → `inside`
- 범위 표현 → `[a:b]`
- 의도가 **한눈에** 들어옴

---

## 흔한 오해

- ❌ `->`와 `if-else`는 솔버에게 다른 제약 → 동일. **가독성 차이뿐**
- ❌ 여러 줄 implication은 **OR**로 묶임 → **AND**. 각 줄 모두 만족 필요
- ❌ `inside`는 `==`의 빠른 버전 → 의미는 비슷, 솔버 입장에서 **집합 처리가 더 효율**
- ❌ `foreach` 안에서 **rand 인덱스** 사용 가능 → **정적 인덱스만** 안전
- ❌ A가 거짓이면 `A -> B`가 거짓 → **참** (의무 미발동, 자동 만족)
