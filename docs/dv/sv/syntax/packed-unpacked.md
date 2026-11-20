# packed vs unpacked (struct & 배열)

> **packed**는 빈틈없이 이어 붙인 **하나의 비트 벡터**이고, **unpacked**는 원소·필드를 **각각 따로 보관**하는 구조다. struct와 배열 모두 같은 개념이다.

---

## 1. 핵심 개념 (struct·배열 공통)

| | packed | unpacked |
|---|---|---|
| 저장 방식 | 하나의 연속된 비트 벡터 (줄자) | 원소/필드를 따로 보관 (서랍장) |
| 통째 대입·연산·비교 | 숫자처럼 가능 | 불가, `'{...}`로 필드/원소별 대입 (예: `'{id:1, len:5}`) |
| 넣을 수 있는 타입 | 비트 타입만 (`logic` / `bit` / `int` / 다른 packed 타입) | 아무 타입 (`string`, `real`, class handle, 동적 배열 등) |

---

## 2. struct

```systemverilog
typedef struct packed { logic [3:0] id; logic [7:0] len; } pk_t; // 12bit 한 줄, 첫 필드가 MSB 쪽
typedef struct        { logic [3:0] id; logic [7:0] len; } upk_t; // 따로 보관
```

```
pk_t  :  [11 ... 8][7 ...... 0]
          id        len           ← 한 줄로 이어진 12bit (pk_t p; p = 12'hA05; 가능)

upk_t :  id  → [3:0]
         len → [7:0]              ← 필드마다 따로 (upk_t u; u = '{id:1, len:5};)
```

!!! tip "용도"
    RTL 버스/레지스터 필드 분할은 **packed**, TB에서 여러 타입이 섞인 정보 묶음은 **unpacked**.

---

## 3. 배열

이름 **앞** 대괄호는 packed, 이름 **뒤** 대괄호는 unpacked다 (표준 문법).

```systemverilog
logic [3:0][7:0] p;     // packed: 32bit 한 줄
logic [7:0]      u [4]; // unpacked: 8bit 칸 4개
```

- 인덱싱(`p[2]`, `u[2]`, `p[2][5]`)은 같게 동작한다.
- 예시 값: `p[0]=8'h11, p[1]=8'h22, p[2]=8'h3C, p[3]=8'h44` 이면 `p = 32'h443C2211` (0번이 오른쪽 끝).

```
p = 32'h 44 | 3C | 22 | 11
         [3]  [2]  [1]  [0]   ← 0번이 LSB 쪽
```

### 차이점 (모두 '한 줄이냐'에서 나옴)

| # | 항목 | packed `p` | unpacked `u` |
|---|------|-----------|--------------|
| 1 | 통째 숫자 대입·연산 | 가능 (`32'h443C2211`) | 불가 |
| 2 | 범위 선택 `[a:b]` | 다차원에서는 비트가 아니라 **원소** 범위 (`p[2:1] = 16'h3C22`) | 원소 범위 (slice) |
| 3 | 0번 위치 | `[3:0]`이면 0번이 LSB 쪽 | `[4]`(=`[0:3]`)이면 0번이 첫 칸 |
| 4 | 원소 타입 | 비트 타입만 | 아무 타입 |
| 5 | 동적 배열 / 큐 / 연관 배열 | 불가 | unpacked 계열만 가능 |

!!! warning "원소 경계를 넘어 비트로 자르기"
    `p[a:b]`는 원소 단위로 잘린다. 경계를 넘어 비트로 자르려면 평탄화한 뒤 자른다.
    ```systemverilog
    logic [31:0] flat = p;   // 같은 32bit라 그대로 대입 가능
    // flat[15:4] → 원소 경계와 상관없이 비트 15~4
    ```

!!! warning "출력 순서 주의"
    packed는 0번이 오른쪽(LSB), unpacked는 0번이 첫 칸이라 통째로 출력하면 순서가 헷갈리기 쉽다.

---

## 4. 차원 순서 & 원소 개수 (표준 규칙)

번호는 **이름 뒤(unpacked)를 왼쪽부터 먼저**, 그다음 **이름 앞(packed)을 왼쪽부터** 매긴다.

```
logic [3:0][7:0] x [2][5];
        ③    ④    ①  ②
```

`x`는 32bit packed 값(8bit 원소 4개)을 2×5 = 10칸에 담은 배열이다.

- 인덱싱도 같은 순서다: `x[1][4][3][7]` = ① 1번 → ② 4번 → ③ 3번 원소 → ④ 7번 비트.

`x[1][4][3][7]`을 그림으로 따라가면 다음과 같다.

```
① [1]  2행 중 1번 행        ② [4]  5칸 중 4번 칸

        [0]   [1]   [2]   [3]   [4]
 [0]   ┌─────┬─────┬─────┬─────┬─────┐
       │     │     │     │     │     │
 [1]   ├─────┼─────┼─────┼─────┼─────┤
       │     │     │     │     │  ★  │  ← x[1][4] : 32bit packed 값 하나
       └─────┴─────┴─────┴─────┴─────┘

③ [3]  ★ 안의 8bit 원소 4개 중 3번 (0번이 LSB 쪽)

   비트:  31....24  23....16  15.....8  7......0
   원소:    [3]       [2]       [1]       [0]
             ▲
          x[1][4][3] : 8bit

④ [7]  그 8bit 중 7번 비트

   비트:  7 6 5 4 3 2 1 0
          ▲
          x[1][4][3][7]  →  ★ 전체 32bit로 보면 31번 비트(MSB)
```
- **원소 개수 = 가장 바깥(첫 번째) 차원.** unpacked가 있으면 이름 바로 뒤 첫 대괄호, packed만 있으면 앞쪽 맨 왼쪽 대괄호다.
- `[7:0]`의 7은 개수가 아니라 마지막 인덱스다 (`[7:0]` = 8개).

3번의 예시 배열 `p`, `u`로 보면 다음과 같다.

```systemverilog
logic [3:0][7:0] p;     // packed: 8bit 원소 4개 (32bit 한 줄)
logic [7:0]      u [4]; // unpacked: 8bit 칸 4개
```

| 함수 | 의미 | `p` | `u` |
|------|------|-----|-----|
| `$size(x)` | 첫 차원 개수 | 4 | 4 |
| `$size(x, n)` | n번째 차원 개수 | `$size(p,2)` = 8 | `$size(u,2)` = 8 |
| `$bits(x)` | 전체 비트 수 | 32 | 32 (비트 수 합계일 뿐, 한 줄 벡터는 아님) |

---

## 5. 다차원 unpacked 예시

```systemverilog
logic [7:0] m [2][5];  // 8bit가 2행×5열 = 10개
m[1][3] = 8'h3C;       // 0011_1100
// m[1][3][5] = 1      (1번 행 → 3번 열 → 5번 비트)
```

- `$size(m)=2`, `$size(m,2)=5`, `$size(m,3)=8`
- `m` 전체는 unpacked(따로 떨어진 10칸)라서 통째 숫자 연산이 불가하고, 한 칸 `m[1][3]`은 packed 8bit라서 숫자 연산이 가능하다.

---

## 6. 컴파일 규칙: packed struct 안에는 packed만

> packed struct는 전체가 **하나의 비트 벡터**여야 하므로, 멤버도 전부 packed(비트 타입)여야 한다. unpacked 멤버가 하나라도 있으면 **컴파일 에러**다.

| 멤버 | packed struct 안에 | 이유 |
|------|------------------|------|
| `logic [7:0] a` / `bit` / `int` | ✅ 가능 | 비트 타입 (`int`는 32bit) |
| 다른 **packed** struct | ✅ 가능 | 비트 벡터 안에 비트 벡터 |
| `T [N-1:0] arr` (이름 **앞** 차원) | ✅ 가능 | packed 배열 |
| `T arr [N]` (이름 **뒤** 차원) | ❌ 에러 | unpacked 배열 |
| unpacked struct | ❌ 에러 | 필드를 따로 보관하는 타입 |
| `real` / `string` / class handle | ❌ 에러 | 비트 타입이 아님 |
| 동적 배열 / 큐 / 연관 배열 | ❌ 에러 | unpacked 계열 |

표에서 `T`는 임의의 packed 타입(예: `logic [7:0]`, packed struct), `N`은 원소 개수, `arr`은 멤버 이름이다.

반대 방향은 문제없다. unpacked 안에 packed를 넣는 것(`pk_t arr [4];`, 2번의 12bit `pk_t` 4개를 칸마다 보관)은 가능하다.

!!! tip "한 줄 규칙"
    이름 **앞**에 쓰면 packed, **뒤**에 쓰면 unpacked, **packed 안에는 packed만** 들어간다. package 안이든 module 안이든 같다.

---

## 7. 실제 사례 (jaxi, `jaxi_defines.svh`)

`JaxiSysParam_t`는 시스템 파라미터 묶음, `JaxiPortParam_t`는 포트 하나의 파라미터 struct다.

컴파일 에러 원인:

```systemverilog
typedef struct packed {
  int num_mst; int num_slv;
  JaxiPortParam_t mst_port_param[16]; // ✗ 이름 뒤 [16] = unpacked → packed struct 안에 못 들어감
} JaxiSysParam_t;
```

수정: 이름 앞에 차원을 두어 packed 배열로 바꾼다.

```systemverilog
JaxiPortParam_t [JAXI_MAX_NUM_MST-1:0] mst_port_param;  // JAXI_MAX_NUM_MST: 최대 master 수 매크로
```

!!! tip "기억할 점"
    - `JaxiPortParam_t`도 packed여야 한다.
    - `[N-1:0]`이라 `[0]`이 LSB 쪽이다.
    - 대안은 struct에서 `packed`를 빼는 것이다 (대신 통째 대입/비교 불가).
    - 규칙은 package / module 어디서든 같다.
