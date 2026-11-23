# typedef로 queue / 배열 타입 선언

> **"typedef + 변수 선언 그대로, 이름 자리에 타입명"**: 변수를 선언하던 문장에서 변수 이름 자리에 타입 이름을 넣고 앞에 `typedef`를 붙이면, queue나 배열도 하나의 **타입**이 된다.

---

## 1. 기본 규칙

```text
변수 선언 :          logic [7:0]  q        [$];
                                  ▲ 변수 이름
타입 선언 :  typedef logic [7:0]  byte_q_t [$];
                                  ▲ 타입 이름 (같은 자리)
```

| 종류 | 변수 선언 | 타입 선언 |
| --- | --- | --- |
| queue | `logic [7:0] q [$];` | `typedef logic [7:0] byte_q_t [$];` |
| dynamic array | `logic [7:0] d [];` | `typedef logic [7:0] byte_da_t [];` |
| associative array | `logic [7:0] a [int];` | `typedef logic [7:0] byte_aa_t [int];` |
| fixed unpacked | `logic [7:0] f [4];` | `typedef logic [7:0] byte4_t [4];` |
| packed | `logic [3:0][7:0] p;` | `typedef logic [3:0][7:0] word_t;` |

선언한 타입은 일반 타입처럼 변수 선언에 쓴다.

```systemverilog
byte_q_t  q;           // logic [7:0] q [$]; 와 같음
byte_da_t d;           // logic [7:0] d [];  와 같음
d = new[4];            // dynamic array는 크기를 new[]로 할당
```

!!! tip "packed / unpacked 차원 위치"
    이름 앞 차원(`[3:0][7:0]`)은 packed, 이름 뒤 차원(`[$]`, `[]`, `[int]`, `[4]`)은 unpacked다. typedef에서도 **이름 자리만 바뀔 뿐** 이 규칙은 그대로다. 자세한 내용은 [packed / unpacked](packed-unpacked.md) 참고.

---

## 2. typedef가 꼭 필요한 경우

### 2.1 함수 리턴 타입이 queue / 배열일 때

리턴 타입 자리에 `[$]` 같은 unpacked 차원을 바로 쓸 수 없으므로 typedef가 **필수**다.

```systemverilog
function logic [7:0] get_data() [$];   // ✗ 문법 에러
function byte_q_t    get_data();       // ✓ typedef로 선언한 타입 사용
```

### 2.2 unpacked 배열끼리 대입할 때

unpacked 배열끼리 대입하려면 **모양(타입)이 같아야** 한다. 양쪽을 같은 typedef로 선언하면 이것이 자동으로 보장된다.

```systemverilog
byte4_t a, b;
a = b;                 // 같은 typedef → 모양 일치 보장
```

### 2.3 중첩 타입

단계별로 이름을 붙이면 중첩 구조가 읽기 쉬워진다.

```systemverilog
typedef logic [31:0] beat_q_t [$];  // beat 리스트 (32-bit beat의 queue)
beat_q_t txn_list [int];            // id별 beat 리스트 (int key 연관 배열)
txn_list[3].push_back(32'hAABB);    // id 3번 리스트에 beat 추가
```

```text
txn_list  (associative array, key = int id)
 ├─ [3] → beat_q_t : { 32'hAABB, ... }
 ├─ [7] → beat_q_t : { ... }
 └─ ...
```

!!! warning "typedef 없이 한 줄로 쓰면"
    ```systemverilog
    logic [31:0] by_id [int][$];     // 가능은 하지만 차원 순서 읽기 어려움
    ```
    문법상 가능하지만 `[int]`와 `[$]` 중 어느 게 바깥인지 헷갈린다. [차원 순서](packed-unpacked.md) 규칙대로 **이름 바로 뒤의 `[int]`가 바깥**이다. typedef로 나누면 "beat 리스트를 ID별로 모았다"는 의도가 바로 읽힌다.

---

## 3. 정리

| 상황 | typedef |
| --- | --- |
| 단순 변수 선언 | 선택 (가독성) |
| 함수 리턴이 queue / 배열 | **필수** |
| unpacked 배열끼리 대입 | 권장 (모양 일치 보장) |
| 중첩 컨테이너 | 권장 (단계별 이름) |
