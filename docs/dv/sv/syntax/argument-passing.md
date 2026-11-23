# function / task 인자 전달 (원본 vs 복사본)

> **핵심 질문: "내가 고친 게 원본이냐, 복사본이냐?"** 객체(handle)를 통해 고치거나 `ref` / `output` / `inout`으로 받으면 원본이 바뀌고, 값 타입(int · struct · queue · 배열)을 `input`으로 받아 고치면 복사본만 바뀐다.

---

## 1. 원본을 직접 만지면 적용

| 방법 | 예 | 원본 적용 |
| --- | --- | --- |
| 메서드 안에서 멤버 수정 | `this.q.push_back(0);` | ✓ |
| handle로 멤버 수정 | `obj.q[0] = 99;` / `obj.id = 3;` | ✓ |

---

## 2. 인자 방향

| 방향 | 동작 | 원본 적용 |
| --- | --- | --- |
| `input` (기본) | stack에 복사 | [3번](#3-input) 참고 |
| `ref` | 원본을 빌려줌 | ✓ 즉시 |
| `const ref` | 원본을 빌리되 읽기만 | 수정 불가 (큰 데이터 읽기용, 복사 비용 없음) |
| `output` | 빈 값으로 시작, 끝날 때 덮어씀 | ✓ 끝날 때 (원래 값 사라짐) |
| `inout` | 원래 값 받고, 끝날 때 덮어씀 | ✓ 끝날 때 |

```text
input  : 호출 시 복사 ──▶ [복사본 수정] ──▶ 함수 종료, 복사본 소멸   (원본 그대로)
ref    : 원본 참조   ──▶ [원본 수정]   ──▶ 수정 즉시 원본에 반영
output : 빈 값 시작  ──▶ [로컬 수정]   ──▶ 함수 종료 시 원본을 덮어씀
inout  : 원래 값 복사 ─▶ [로컬 수정]   ──▶ 함수 종료 시 원본을 덮어씀
```

!!! tip "방향이 타입보다 우선"
    `inout` / `output` / `ref`는 **타입과 상관없이** 원본에 적용된다. 단 `output` / `inout`은 함수가 끝날 때, `ref`는 즉시 적용된다.

---

## 3. input일 때 타입별

| 타입 | 복사되는 것 | 안을 고치면 |
| --- | --- | --- |
| int, struct, queue, 배열 | 값 / 내용 전체 | ✗ 복사본만 바뀌고 함수 끝나면 stack에서 사라짐 |
| class handle | 주소만 | ✓ `it.id = 3` → 같은 객체라 적용 |
| handle 자체 교체 (`it = null`, `it = new()`) | 주소만 | ✗ 바깥 handle은 그대로 |

```text
input class handle:

  바깥 c  ──┐
            ├──▶ [ my_cls 객체 ]   it.id = 3  → 같은 객체 수정 ✓
  안쪽 it ──┘

  it = new();  →  안쪽 it ──▶ [ 새 객체 ]   바깥 c는 기존 객체 그대로 ✗
```

!!! warning "기준은 '넘긴 게 class handle인지'"
    'class 멤버인지'가 기준이 아니다. `sum(c)`는 handle 전달이라 적용되지만, `sum(c.q)`처럼 멤버 queue만 `input`으로 떼서 넘기면 복사라 적용되지 않는다.

---

## 4. 예시

```systemverilog
class my_cls; int q [$] = '{1,2,3}; endclass
my_cls c = new();

c.q[0] = 99;   // ✓ 원본 직접
f(c);          // f(my_cls o) 안에서 o.q[0]=99     ✓ handle로 원본
g(c.q);        // g(int a[$]) 안에서 a[0]=99       ✗ 복사본
h(c.q);        // h(ref int a[$]) 안에서 a[0]=99   ✓ ref

function automatic void sum(my_cls a);
  a.q.push_back(0);   // 원본 객체의 q에 추가
endfunction
sum(c);        // c.q = {...,0} ✓  (단, 함수 안에서 a = new() 후 push하면 c에는 적용 안 됨)

function automatic void f_out(output int a [$]); a.push_back(7); endfunction
f_out(c.q);    // 함수 끝 → c.q = {7} (원래 값 덮어씀)
```

| 호출 | 넘긴 것 | 방향 | 원본 `c.q` 적용 |
| --- | --- | --- | --- |
| `f(c)` | class handle | input | ✓ |
| `g(c.q)` | queue | input | ✗ |
| `h(c.q)` | queue | ref | ✓ 즉시 |
| `sum(c)` | class handle | input | ✓ (`a = new()` 후엔 ✗) |
| `f_out(c.q)` | queue | output | ✓ 끝날 때 덮어씀 |

---

## 5. ref 주의점

!!! warning "ref 사용 조건"
    - **automatic 함수 / task에서만** 사용 가능하다. class 메서드는 기본 automatic이고, module 함수는 `function automatic`으로 선언해야 한다. ([static / automatic](static-automatic.md) 참고)
    - 상수나 식은 넘길 수 없다. **실제 변수만** 넘길 수 있다.
