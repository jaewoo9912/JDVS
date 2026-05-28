# 동적 제어 (rand_mode / constraint_mode / pre·post_randomize)

## 4 도구 한눈에

| 도구 | 단위 | 호출 | 용도 |
| --- | --- | --- | --- |
| `rand_mode(0/1)`       | 필드 1개       | `obj.field.rand_mode(0)`              | 그 필드만 randomize ON/OFF |
| `constraint_mode(0/1)` | constraint 1개 | `obj.block_name.constraint_mode(0)`   | 그 블록만 ON/OFF |
| `pre_randomize()`      | 객체 전체      | 자동 (randomize 직전)                 | 사전 상태 조정 |
| `post_randomize()`     | 객체 전체      | 자동 (randomize 직후)                 | 사후 derived 계산 |

### `randomize()` 호출 흐름

```text
p.randomize() 호출
    ↓
1. pre_randomize()       ← rand_mode / constraint_mode 동적 조정 자리
    ↓
2. 솔버 동작             ← 활성화된 constraint, rand_mode(1) 필드만
    ↓
3. rand 필드에 값 할당   (성공 시)
    ↓
4. post_randomize()      ← derived 필드 계산 자리
    ↓
5. randomize() 1 반환    (실패 시 0 반환, post_randomize 호출 안 됨)
```

---

## `rand_mode(0/1)` — 필드 ON/OFF

```systemverilog
p.addr = 32'h1000;
p.addr.rand_mode(0);     // 다음 randomize 에서 addr 는 입력 (값 유지)
p.randomize();           // addr = 0x1000 고정, 나머지만 무작위
p.addr.rand_mode(1);     // 다시 켜기
```

### 핵심

- **값을 고정하지 않음** → 단지 randomize **대상에서 빼는** 것
- 그래서 보통 `obj.field = value;` + `obj.field.rand_mode(0);` **짝**으로
- 다른 constraint들은 그 **(고정된) 값을 보고** 동작

### `with`와 비교

- `with`: **한 호출만**
- `rand_mode(0)`: 다음 `rand_mode(1)`까지 **계속 유지**

→ 여러 호출에 걸쳐 같은 필드 고정하려면 **`rand_mode`**.

---

## `constraint_mode(0/1)` — constraint 블록 ON/OFF

```systemverilog
p.aligned_c.constraint_mode(0);   // 그 블록 임시 비활성화
p.randomize();                    // aligned_c 무시, 나머지만 적용

// 객체 전체 끄기:
p.constraint_mode(0);             // 모든 블록 OFF (rand_mode 영향 X)
```

### 핵심

- **"그 블록이 코드에 없는 것처럼"** 동작
- 다시 `(1)`로 켤 수 있음
- 객체에 직접 호출 → **모든 블록 한 번에 OFF** (디버깅 유용)

### 활용

- **부정 테스트** (정렬/범위 위반 등으로 DUT 에러 처리 검증)
- **디버깅** (자유로운 값으로 솔버 동작 확인)

---

## `pre_randomize()` — 사전 훅

```systemverilog
function void pre_randomize();
  if (use_dma_mode) addr.rand_mode(0);
  else              addr.rand_mode(1);
endfunction
```

### 핵심

- `randomize` **직전 자동 호출** (수동 호출 X)
- 이 시점엔 **rand 변수가 아직 미정** (이전 값)
- **객체 상태에 따라 `rand_mode` / `constraint_mode` 동적 조정** 자리

### 상속 시

- `super.pre_randomize()` 명시 호출 컨벤션

---

## `post_randomize()` — 사후 훅

```systemverilog
function void post_randomize();
  super.post_randomize();              // 상속 시
  checksum = addr ^ data;              // derived 필드 계산
endfunction
```

### 핵심

- `randomize` **성공 직후 자동 호출** (**실패 시 호출 안 됨**)
- **rand 변수 값 사용 가능** (이미 결정됨)
- **derived / 계산 필드** 채우는 자리 — 가장 흔한 용도

### 전형 패턴

```systemverilog
class C;
  rand int low, high;
  int      mid;                        // non-rand
  constraint c { low <= high; }
  function void post_randomize();
    mid = (low + high) / 2;            // 계산
  endfunction
endclass
```

---

## 도구 선택 가이드 (전체)

| 상황 | 도구 |
| --- | --- |
| 한 호출만 다르게         | [`with { }`](with-soft.md) |
| 여러 호출에 필드 고정    | `field.rand_mode(0)` |
| 디폴트 + 가끔 덮기       | [`soft`](with-soft.md#soft-constraint) |
| 블록 잠깐 끄기           | `constraint_mode(0)` |
| 객체 상태 기반 조정      | `pre_randomize()` |
| derived 값 계산          | `post_randomize()` |

---

## 흔한 오해

- ❌ `rand_mode(0)`이 값을 0으로 세팅 → 단지 randomize **제외**. 값은 이전 값 유지
- ❌ `constraint_mode(0)`이 constraint 삭제 → **임시 비활성화**. 다시 켤 수 있음
- ❌ `post_randomize`가 실패 시에도 호출됨 → **성공할 때만**
- ❌ `pre_randomize`에서 rand 변수 값 참조 → 아직 미정. **상태 조정 용도만**
- ❌ `pre/post_randomize` 수동 호출 필요 → 자동. `randomize()`가 호출
