# uvm_pool

## 개념

**key→value 쌍을 담는 범용 컨테이너 클래스**다. 본질은 **연관 배열(associative array)을 객체로 감싼 것**.

```systemverilog
uvm_pool #(KEY, T)   // KEY 로 찾고, T 를 저장
```

- 클래스(uvm_object 계열)라 **핸들(포인터)로 다뤄짐** → `uvm_queue`처럼 넘길 때 복사 부담이 없다.
- 진짜 쓸모는 **전역(global) 풀** — TB 어디서든 **같은 풀을 공유**할 수 있다.

!!! note "global pool은 lazy 싱글톤"
    전역 풀은 `static` 멤버로 클래스 차원에 **1개**만 존재한다.
    **처음 `get_global*()`를 호출하는 쪽**이 그 순간 생성하고, 이후엔 누가 불러도 **같은 인스턴스**를 받는다.
    → 생성 주체나 순서를 신경 쓸 필요가 없다.

## 사용법

```systemverilog
// 일반 풀
uvm_pool #(string, int) p = new();
p.add("a", 10);
if (p.exists("a"))
  int v = p.get("a");          // 10

// 전역 풀 (싱글톤) — 어디서 불러도 같은 풀
uvm_pool #(string, int)::get_global_pool();
```

주요 메서드: `add(key, item)`, `get(key)`, `exists(key)`, `delete(key)`, `num()`, `first()/next()`

## 실제 예제

`uvm_object_string_pool #(T)`는 **string으로 찾고 T(객체)를 저장**하는 풀이다.
`get`할 때 해당 key가 없으면 **객체를 자동 생성**해준다. (`uvm_event_pool`/`uvm_barrier_pool`도 이걸 typedef한 것)

이름만 알면 **계층 연결 없이** 서로 다른 컴포넌트가 같은 객체를 공유한다.

```systemverilog
// my_cfg 객체를 이름으로 전역 공유하는 풀
typedef uvm_object_string_pool #(my_cfg) cfg_pool;

// 컴포넌트 A
my_cfg c = cfg_pool::get_global("shared");   // 없으면 my_cfg 자동 생성
c.mode = 3;

// 컴포넌트 B (직접 핸들 연결 없이 같은 이름으로)
my_cfg c = cfg_pool::get_global("shared");   // 같은 객체 핸들! (c.mode == 3)
```

→ 처음 부른 쪽이 풀+객체를 만들고, 나머지는 그걸 그대로 받는다.

## uvm_pool vs uvm_object_string_pool

`uvm_object_string_pool`은 `uvm_pool #(string, T)`를 **상속**한 특화 버전이다.

| | **uvm_pool #(KEY, T)** | **uvm_object_string_pool #(T)** |
| --- | --- | --- |
| key 타입 | 임의 (`KEY`) | **`string` 고정** |
| value(T) | 임의 타입 (int, 객체 등) | **uvm_object 파생 객체** |
| 없는 key로 `get` | 기본값 반환 (객체면 **`null`**) | **`new()`로 객체 자동 생성** 후 반환 |
| 대표 활용 | 범용 map | `uvm_event_pool`, `uvm_barrier_pool` |

핵심 차이는 **`get`할 때 객체가 없으면**:

- `uvm_pool` → 빈 슬롯에 기본값(객체면 `null`)만 넣고 반환 → 직접 만들어 넣어야 함
- `uvm_object_string_pool` → **알아서 객체를 생성**해 돌려줌 → 그래서 event/barrier 공유에 편함

## uvm_config_db와의 차이

둘 다 **계층 배선 없이 이름(key)으로 데이터를 공유**하는 전역 저장소다. (config_db도 내부는 pool 기반)
차이는 **무게 = 기능량**이다.

| | **uvm_pool** (가벼움) | **uvm_config_db** (무거움) |
| --- | --- | --- |
| 본질 | 단순 연관배열 lookup (key→value) | scope 매칭 + 타입체크 + 우선순위 |
| 하는 일 | 정확한 key로 바로 꺼냄 | ① 계층 경로(wildcard) 매칭<br>② `#(T)` 타입 검사<br>③ 여러 set 간 우선순위 판정 |
| 비용 | 싸다 | 위 처리 때문에 비쌈 |

config_db가 무거운 건 **일을 더 많이 하기 때문**이다 — scope(누가 보나) · type-safe · precedence(override).
`uvm_pool`은 이런 걸 안 따지고 **그냥 map에서 꺼내기**만 하니 가볍다.

**선택 기준**

- **설정값**처럼 계층·타입·우선순위가 중요 → `uvm_config_db`
- **named 객체(event/barrier 등)** 단순 전역 공유 → `uvm_pool` / `uvm_object_string_pool`
