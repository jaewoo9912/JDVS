# 솔버 멘탈 모델 & solve before

## constraint 솔버 멘탈 모델

### 한 줄 정의

**constraint = 동시에 만족해야 하는 조건 목록(set)**.
솔버는 그 목록 전체를 만족하는 (변수 튜플) 중 하나를 균등하게 뽑는다.

### 핵심 원리 — 절차적 코드가 아니다

```systemverilog
constraint c {
  a < b;
  b < c;
  c < 100;
}
```

- 위에서 아래로 실행 ❌
- 솔버는 `{ a<b, b<c, c<100 }`이라는 **set**으로 본다
- 줄 순서·블록 위치 모두 **무관** — 같은 set이면 같은 결과
- 비유: **연립방정식**. 어느 식 먼저 보냐 묻지 않는다. 동시에 만족하는 해 찾기.

### 양방향 관계 (bidirectional)

```systemverilog
constraint c { a == b * 2; }
```

- C의 **대입 아님**. **관계 선언**.
- a가 먼저 정해지든 b가 먼저 정해지든 **솔버가 둘 다 동시 결정**.

### 솔버의 일 — 두 단계

1. **유효 조합 찾기** — constraint 다 만족하는 (변수 튜플) 모두 나열
2. **하나 뽑기** — 디폴트는 **joint uniform** (유효 조합 통에서 균등 추출)

→ 결과: 각 변수만 따로 보면 분포가 **휠 수 있음** (marginal 분포).

### Joint vs Marginal 분포

- **Joint** = `(a, b, c, ...)` 튜플 자체의 분포 → 솔버가 균등하게 만드는 대상
- **Marginal** = **한 변수만** 떼서 본 분포 (다른 변수 무시) → 사용자가 보통 보는 것
- **둘은 다를 수 있다.** 한 변수에 호환되는 다른 변수의 개수가 다르면 marginal이 휜다.

### Marginal이 휘는 예

```systemverilog
rand bit [1:0] a;     // 0~3
rand bit       b;     // 0/1
constraint c { a > 0 -> b == 1; }
```

유효 `(a, b)` 쌍: `(0,0), (0,1), (1,1), (2,1), (3,1)` — **5개**

`a`의 marginal 분포 (`solve before` 없을 때):

- a=0 → 두 쌍 → **40%**
- a=1, 2, 3 → 각 한 쌍 → 각 **20%**

→ a=0이 의도와 달리 **두 배 자주** 나온다.

---

## `solve ... before` — 변수 결정 순서 지정

```systemverilog
constraint c {
  a > 0 -> b == 1;
  solve a before b;
}
```

### 의미와 동작

> "솔버야, **`a`부터 먼저 균등하게 정하고**, 그 다음 **`b`를 `a`에 맞춰서** 정해라."

1. `a`를 가능한 값 중에서 균등 추출
2. 뽑힌 `a`에 맞춰 `b`를 (가능한 값 중에서) 균등 추출

### 결과 (위 예 기준)

- `a` 분포: **25%씩 균등**
- `b` 분포: `a` 값에 종속 (`a=0`이면 50/50, `a≥1`이면 100% `b=1`)

### 무엇이 바뀌고, 무엇이 안 바뀌나

| | 변함 |
| --- | --- |
| 유효 `(a, b)` 쌍 집합 | ❌ 그대로 |
| `(a, b)` 쌍 뽑기 방식 | ✅ joint uniform → a 먼저 균등 후 b |
| `a`의 marginal 분포   | ✅ 균등해짐 |
| `b`의 marginal 분포   | ✅ a에 종속된 형태로 바뀜 |

### 언제 쓰나 — 실무 휴리스틱

#### 시그널 1: 카테고리 변수가 implication의 LHS

```systemverilog
constraint c {
  op == READ  -> burst_len inside {[1:16]};
  op == WRITE -> burst_len inside {[1:32]};
  op == RECV  -> burst_len == 1;
  // solve op before burst_len;  ← 거의 필수
}
```

`op` 종류별 호환 `burst_len` 개수가 달라 → `op`의 marginal 휨 → opcode 균등 커버리지 망가짐.
→ **`solve op before burst_len`**으로 카테고리 균등 강제.

#### 시그널 2: alignment / divisibility가 두 변수를 묶음

```systemverilog
constraint c {
  addr % size == 0;
  // solve size before addr;  ← size 균등 보고 싶을 때
}
```

`size=1`이면 호환 `addr` 수가 가장 많아 → `size=1`이 압도적으로 자주.
→ **`solve size before addr`**로 size 균등 강제.

#### 시그널 3: dynamic array size를 다른 변수가 결정

```systemverilog
rand int n;
rand int data[];
constraint c {
  data.size == n;
  // solve n before data;  ← n 균등 보고 싶을 때
}
```

#### 시그널 4: 분포 통계 찍어봤더니 특정 값이 압도적

→ 그 값이 속한 변수에 `solve before` 후보.

### 멘탈 모델

- constraint 그래프에서 **"카테고리 → 좁힘" 구조의 카테고리 쪽**을 `solve before` 위에 올린다.
- 가장 흔한 패턴: **`solve type/opcode/category before <details>`**

### 안 써야 할 때

- 분포가 휘는 게 **의도**일 때 (이땐 [`dist`로 명시적 가중치](distribution.md))
- constraint가 거의 **fully-determined** (해가 1개 또는 매우 적음)
- 대규모 constraint set에서 **미세한 성능 저하** 우려

---

## 흔한 오해

- ❌ constraint 줄을 **위에서 아래로** 평가 → 아님. **동시 set**
- ❌ `a == b*2`는 b → a **대입** → 아님. **양방향 관계**
- ❌ `solve before`가 **새 제약을 추가** → 아님. 유효 해 집합 그대로, **분포만 변경**
- ❌ 제약 없는 변수는 항상 균등 → 아님. **다른 변수와의 결합으로 marginal 휠 수 있음**
