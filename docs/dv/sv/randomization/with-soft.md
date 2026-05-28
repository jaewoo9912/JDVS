# inline with & soft & std::randomize

## 두 도구

| 도구 | 누가 정의 | 영향 범위 |
| --- | --- | --- |
| `randomize() with { }` | **호출자** (사용자) | 그 호출 1회 |
| `soft constraint`      | **클래스** (정의자) | 모든 `randomize` 호출 (디폴트) |

→ 같이 쓰면 **재사용 + 유연** 둘 다 확보.

---

## inline `randomize() with { }`

호출 시점에 추가 constraint를 부여한다.

```systemverilog
p.randomize() with {
  size == 64;
  addr inside {[0:255]};
};
```

### 동작 원리

- **클래스 constraint 대체 아님 → 추가.** 솔버는 둘 다 동시 만족
- **둘 다 hard인데** 양립 안 되면 → `randomize` 실패
- **외부 변수는 호출 시점 값으로 스냅샷** (상수처럼 솔버에 전달)

### 변수 lookup 규칙 (`with` 블록 내부)

1. **클래스 멤버 우선** (`this.*`)
2. 그 다음 외부 스코프

```systemverilog
int addr = 'h1000;
p.randomize() with {
  addr == addr;          // ❌ 둘 다 p.addr (외부 addr 무시 — 조용한 버그)
  addr == local::addr;   // ✅ 좌 = p.addr, 우 = 외부 addr
};
```

→ **베스트 프랙티스**: 외부 변수에 prefix (`target_`, `req_`) 붙여서 **충돌 자체를 회피**.

### 외부에서 보이는 범위

"호출 위치에서 보이는 모든 이름" = `with` 안에서도 보임:

- 호출자 task/function의 **로컬 변수**
- 호출자가 속한 클래스의 **멤버**
- 보이는 **객체 핸들의 멤버** (`cfg.max_addr` 등)
- import된 패키지 변수, `enum`, `parameter`, 모듈 변수

안 보이는 것: 다른 task의 로컬, 핸들 없는 객체.

---

## soft constraint

클래스 측에서 **"양보 가능한 디폴트"**를 깔아둔다.

```systemverilog
class Packet;
  rand opcode_e op;
  constraint c { soft op == READ; }    // 디폴트
endclass

cmd.randomize();                              // op = READ (디폴트)
cmd.randomize() with { op == WRITE; };        // op = WRITE (soft 양보)
```

### soft가 진짜 의미하는 것

> **"내가 양보할 수 있어요"** 마킹.

- 충돌이 **없으면** → 항상 적용 (그냥 hard처럼 동작)
- 다른 제약과 **충돌하면** → 자동 양보 (실패 안 함)

`soft`가 없었다면 위 예제의 두 번째 호출은 모순 → `randomize` 실패.

---

## 우선순위 — 충돌 시 누가 이기나

> **hard > inline (`with`) > soft**

| 충돌 | 결과 |
| --- | --- |
| hard vs hard      | 솔버 **실패** |
| inline vs hard    | 솔버 **실패** |
| soft vs hard      | soft 양보 → **성공** |
| soft vs inline    | soft 양보 → **성공** |
| soft vs soft      | 시뮬레이터 의존 (보통 둘 다 무시) |

---

## `std::randomize` — 클래스 없는 자유 변수

일회성 변수 몇 개만 randomize할 때.

```systemverilog
int a, b, c;
if (!std::randomize(a, b, c) with { a < b; b < c; c < 100; })
  `uvm_fatal("STD", "randomize failed")
```

### 클래스 vs `std::randomize`

| | 클래스 + constraint | `std::randomize` + with |
| --- | --- | --- |
| 재사용성    | ✅ 객체 여러 개 가능       | ❌ 일회성 |
| 확장성      | 상속 / `soft` / `dist` 등  | `with`만 |
| 객체 수명   | 멤버 변수 (객체 따라)      | 함수 스코프 |
| 적합한 경우 | 반복 사용할 트랜잭션/패킷  | 한 줄짜리 임시 변수 |

> 유효 해 집합과 분포는 동일. 구체적 값은 시뮬레이터의 PRNG 상태 소비에 따라 다를 수 있다.

---

## 디자인 패턴 — `soft` + `with` 조합

가장 강력한 활용:

```systemverilog
// 클래스 측: 합리적 디폴트 깔기
class Command;
  rand sig_e signaled;
  constraint c { soft signaled == SIGNALED; }
endclass

// 사용 측
cmd.randomize();                                   // 평소: SIGNALED
cmd.randomize() with { signaled == UNSIGNALED; };  // 특수 시나리오만 override
```

- 클래스를 새로 안 만들고도 **한 호출만 다르게** 가능
- 디폴트가 **명시적으로 드러나** 의도 파악 쉬움
- 100여 개 command 클래스에 이 패턴 일관 사용 → 사용처 코드가 깔끔

---

## 흔한 오해

- ❌ inline `with`가 클래스 constraint를 "끈다" → **추가됨**. 양립 안 되면 실패
- ❌ `soft`는 약해서 자주 무시됨 → **충돌 없으면 항상 적용**
- ❌ inline `with` 안 외부 변수가 나중에 바뀌면 결과도 바뀜 → **호출 시점 스냅샷**
- ❌ inline 안 변수명이 외부 변수 우선 → **클래스 멤버 우선** (이름 충돌 시 외부는 가려짐)
- ❌ `std::randomize`와 클래스 `randomize`가 같은 seed면 같은 값 → 분포 동일, **구체 값은 다를 수 있음**
