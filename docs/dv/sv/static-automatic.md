# static / automatic (변수 lifetime)

## 핵심 개념 — 수명(lifetime)

변수 메모리가 살아있는 기간.

| 모드 | 메모리 할당 시점 | 메모리 갯수 |
| --- | --- | --- |
| `static`    | 시뮬 시작 시 1회 | 1개 (공유) |
| `automatic` | 스코프 진입마다  | 진입 횟수만큼 |

> 비유: **`static` = 공용 화이트보드**. **`automatic` = 진입할 때마다 받는 일회용 사물함**.

## 디폴트 수명 — 선언 위치별

| 선언 위치 | 디폴트 |
| --- | --- |
| 모듈/인터페이스/패키지/프로그램 변수      | `static` |
| 모듈 안 `task`/`function`의 로컬 변수    | **`static`** ⚠️ |
| 클래스 메서드의 로컬 변수                | `automatic` |
| `fork...join_xxx` 블록 안                | 명시 가능 (관행: 캡처 변수에 `automatic`) |

!!! warning
    **모듈 `task`의 로컬 변수가 디폴트 `static`** — 가장 자주 다치는 부분.
    C 출신은 "함수 로컬은 호출마다 새로"라고 가정하지만 **SV는 그렇지 않다.**

## 명시 키워드

### 변수 단위

```systemverilog
task my_task();
  static int call_count;          // 호출 사이 유지 (C의 static local)
  automatic int local_tmp;        // 호출마다 새로
endtask
```

### task / function 단위

```systemverilog
task automatic safe_task();       // 안의 변수 디폴트 automatic
  int a;                          // automatic (디폴트 변경됨)
  static int call_cnt;            // 명시한 static 은 그대로
endtask
```

## 자주 보는 함정

### ① 모듈 task 동시 호출

```systemverilog
task count_to(int n);             // 디폴트 static
  int i;                          // 공유 i! 동시 호출 시 섞임
  for (i = 0; i < n; i++) ...
endtask
```

→ 해법: `task automatic count_to(...)` 또는 `automatic int i;`

### ② 재귀 함수

```systemverilog
function int factorial(int n);    // 디폴트 static → 재귀 시 덮어씀
  int result;
  if (n <= 1) return 1;
  result = n * factorial(n-1);    // 같은 result 공유 → 결과 잘못
  return result;
endfunction
```

→ 해법: `function automatic int factorial(...)` **필수**

### ③ fork 캡처

```systemverilog
foreach (port[i]) begin
  fork
    begin
      automatic int j = i;        // ← 매 fork 자식마다 새 j + 초기자 평가
      port[j].get(...);
    end
  join_none
end
```

선언만으론 부족. **`= i` 초기자가 fork 시점에 평가되는 게 핵심**이다. ([상세](fork-join.md#foreach-fork-변수-캡처-함정))

---

## `static` 키워드의 위치별 의미 — 세 가지

같은 `static` 키워드가 위치에 따라 의미가 달라진다.

### 1. 변수 수명 (`task`/`function` 본문)

```systemverilog
static int x;       // 시뮬 전체에서 1개 메모리. 호출 사이 유지
automatic int x;    // 스코프 진입마다 새 메모리
```

### 2. 클래스 정적 멤버 변수 — 인스턴스 공유

```systemverilog
class Counter;
  static int total_count;         // 모든 인스턴스가 공유
  int instance_count;             // 인스턴스별
endclass

Counter a = new();
Counter b = new();
// a.total_count, b.total_count, Counter::total_count — 모두 같은 메모리
```

### 3. 클래스 정적 메서드 — 인스턴스 없이 호출

```systemverilog
class Counter;
  static int total_count;

  static function void reset_total();    // ← static method
    total_count = 0;
  endfunction

  static function int get_total();
    return total_count;
  endfunction
endclass

// 인스턴스 없이 호출
Counter::reset_total();
$display(Counter::get_total());
```

#### 제약

- `this` 사용 불가 (특정 인스턴스가 없으므로)
- 인스턴스 멤버 접근 불가 (`this` 없음 → 어느 객체인지 특정 못 함)
- `static` 멤버만 접근 가능
- `virtual`과 함께 못 씀 (`static virtual` = 모순)

#### 호출 방식

- **`ClassName::method()`** — 권장. 정적 호출임이 한눈에 보임
- `instance.method()` — 가능하지만 인스턴스 상태와 무관. 의미는 동일

#### 주요 용도

- **인스턴스 카운터 / 글로벌 상태**: 클래스 차원의 통계
- **Singleton 패턴**: 유일한 인스턴스 접근 (UVM의 `uvm_root::get()` 등)
- **Factory 메서드**: `new()` 대신 클래스 메서드로 인스턴스 생성/획득
- **유틸리티 함수**: 인스턴스와 무관한 헬퍼 (수학 함수 등)

#### Singleton 예

```systemverilog
class Logger;
  local static Logger inst;
  local function new(); endfunction       // 외부 new() 차단

  static function Logger get();
    if (inst == null) inst = new();
    return inst;
  endfunction
endclass

Logger l = Logger::get();
```

---

## 베스트 프랙티스

- **모듈에 `task`/`function` 정의 → 거의 항상 `automatic` 선언** (동시/재귀 안전)
- 클래스 메서드는 디폴트 `automatic` → 그냥 두면 됨
- 호출 사이 **상태 유지 필요할 때만** `static int x;` 명시 (의도 분명)
- fork 자식 캡처 변수는 `automatic int j = i;` 패턴
- 클래스 멤버 중 **인스턴스 공유 카운터/플래그**는 `static`
- `static` 메서드는 `ClassName::method()` 형태로 호출 (가독성)
