# AXI WSTRB 기본 개념 & lane 계산

> AXI는 데이터 선(lane)마다 메모리 주소가 고정 연결돼 있어서, master가 처음부터 주소에 맞는 lane에 데이터를 싣고 WSTRB로 표시한다. 그 lane 구간은 `[lo, hi)`로 구하고, `aligned % BUS`가 칸(lane 덩어리)의 시작을 알려준다.

---

## 1. lane과 WSTRB 기본 개념

8B 버스 기준으로, 데이터 선(lane)은 메모리 한 줄(row)의 바이트에 고정 연결돼 있다.

```text
           lane:   7    6    5    4    3    2    1    0
WDATA 선:       [B7] [B6] [B5] [B4] [B3] [B2] [B1] [B0]
                  │    │    │    │    │    │    │    │   ← 선이 고정 연결
메모리 한 줄:    0x0F 0x0E 0x0D 0x0C 0x0B 0x0A 0x09 0x08
```

| 항목 | 식 | 의미 |
|---|---|---|
| lane 번호 | `addr % BUS` | strb의 몇 번 비트인가 |
| row 번호 | `addr / BUS` | 메모리 몇 번째 줄인가 (slave가 쓸 때만 필요) |

- 예: BUS 64B일 때 addr 127은 row 1의 63번 lane이다.
- WSTRB를 구할 때 row 번호는 필요 없고, row 안에서의 위치인 lane(`% BUS`)만 있으면 된다.

---

## 2. 왜 master가 lane을 정해주는가

0x0C에 4바이트를 쓰는 narrow write(size=2)를 보자.

**AXI 방식: master가 주소에 맞는 lane에 싣는다**

```text
lane:     7    6    5    4  │  3    2    1    0
WDATA:  [D3] [D2] [D1] [D0] │ [ -] [ -] [ -] [ -]
WSTRB:    1    1    1    1  │  0    0    0    0    = 0xF0
           ↓    ↓    ↓    ↓
메모리:  0x0F 0x0E 0x0D 0x0C   ← 선 따라 그대로 떨어진다
```

**만약 아래 lane 0~3에 몰아서 보내면**

```text
WDATA:  [ -] [ -] [ -] [ -]  [D3] [D2] [D1] [D0]   ← lane 0~3에 실림
                                │    │    │    │
                                ▼    ▼    ▼    ▼
                    "주소가 0x0C니까 4칸 밀어야지" ← shifter 필요
메모리:  0x0F 0x0E 0x0D 0x0C
```

| | master가 lane에 맞춰 전송 (AXI) | 아래 lane에 몰아서 전송 |
|---|---|---|
| slave | strb가 1인 lane만 그 자리에 쓰면 끝 | 주소를 보고 shift하는 로직 필요 |
| interconnect | WDATA/WSTRB를 그대로 넘기기만 함 | 경로마다 shifter(큰 mux) 필요 |
| width converter | 64→32는 lane 4~7(위쪽 반)만 잘라 보내면 됨 | 복잡 |

!!! tip "AXI의 설계 철학"
    어느 lane인지 정하는 계산은 출발지인 master가 한 번만 하고, 나머지는 그대로 통과시킨다. VIP에서 그 계산을 하는 것이 `gen_strb`다.

---

## 3. size에 따른 WDATA/WSTRB 위치

한 beat에 보내는 바이트 수는 `nbytes = 1 << size`이다. 8B 버스를 `nbytes`짜리 칸으로 나누면 다음과 같다.

| size | nbytes | 칸 수 (BUS 8) | 칸 구성 |
|---|---|---|---|
| 3 | 8 | 1 | `[7~0]` (버스 폭과 같음, narrow 아님) |
| 2 | 4 | 2 | `[7~4]`, `[3~0]` |

한 beat에 최대 `nbytes`개 lane을 쓰고, **어느 칸을 쓸지는 주소가 정한다.**

!!! warning "narrow는 아래 lane 고정이 아니다"
    size=2에서 4B 데이터를 항상 lane 0~3에 싣는 게 아니다. 주소가 가리키는 칸에 싣는다. 그래서 위 칸과 아래 칸을 번갈아 쓴다.

---

## 4. unaligned 시작 주소 예제

### 4.1 addr 3, len 1, size 3, BUS 8 (WSTRB `0xF8`, `0xFF`)

size=3이라 beat가 8B, 버스도 8B라 narrow는 아니고 시작 주소만 unaligned다.

```text
lane:          7  6  5  4  3  2  1  0
beat0 (0x03~0x07)
  WSTRB:       1  1  1  1  1  0  0  0   = 0xF8   ← lane 0~2는 쓰는 범위 밖
beat1 (0x08~0x0F)
  WSTRB:       1  1  1  1  1  1  1  1   = 0xFF   ← 정렬된 주소부터는 꽉 참
```

- beat0: 주소 3을 내림 정렬한 0부터 0x07까지가 칸이고, 실제 쓰는 건 3~7이다.
- beat1: `aligned(0) + 8 = 0x08`에서 시작한다.
- 총 전송량은 16B가 아니라 5 + 8 = 13B다.

### 4.2 addr 3, len 1, size 2, BUS 8 (WSTRB `0x08`, `0xF0`)

size=2라 beat당 4B이고 버스는 8B이므로 narrow 전송이다.

```text
lane:          7  6  5  4  3  2  1  0
beat0 (0x03)
  WSTRB:       0  0  0  0  1  0  0  0   = 0x08
beat1 (0x04~0x07)
  WSTRB:       1  1  1  1  0  0  0  0   = 0xF0
```

- beat0: 주소 3을 4B 단위로 내림하면 0이라 칸은 0x00~0x03이다. 실제로 쓰는 건 0x03 하나뿐이라 lane 3만 1이다.
- beat1: 다음 주소는 `aligned(0) + 4 = 0x04`이고, lane은 `addr % 8`로 정해져 4~7(위쪽 반)이다. 그래서 `0x0F`가 아니라 `0xF0`이다.
- 총 전송량은 1 + 4 = 5B다.

!!! warning "beat1을 0x0F로 쓰기 쉽다"
    4B 데이터를 아래 lane에 고정으로 싣는 것이 아니라, 주소가 가리키는 lane에 싣는다.

### 4.3 위·아래 칸이 번갈아 가는 모양 (addr 3, size 2, BUS 8)

```text
8 lane을 4 lane짜리 두 칸으로 나누면:  [lane 7~4 | lane 3~0]

beat0  주소 0x03  →  아래 칸(lane 3~0)인데 3부터 시작이라   0x08
beat1  주소 0x04  →  위 칸(lane 7~4) 전체                    0xF0
beat2  주소 0x08  →  다시 아래 칸 전체                       0x0F
beat3  주소 0x0C  →  위 칸 전체                              0xF0
```

첫 beat만 unaligned라서 일부가 비고, 그다음부터는 4 lane이 꽉 찬 채로 교대로 간다.

### 4.4 addr 7, len 1, size 2, BUS 8 (WSTRB `0x80`, `0x0F`)

이번엔 위 칸에서 시작해서 아래 칸으로 넘어간다.

```text
lane:               7  6  5  4 | 3  2  1  0
beat0 (0x07)        1  0  0  0 | 0  0  0  0   = 0x80
beat1 (0x08~0x0B)   0  0  0  0 | 1  1  1  1   = 0x0F
```

- beat0: 주소 7을 4B 단위로 내림하면 4라서 0x04~0x07, 즉 위 칸을 맡는다. 실제로 쓰는 건 0x07 하나뿐이라 lane 7만 1이다.
- beat1: `aligned(4) + 4 = 0x08`이고 lane 0~3(아래 칸) 전체이다.

---

## 5. 핵심 공식

위 예제를 한 번에 구하는 식이다.

| 변수 | 식 | 의미 |
|---|---|---|
| `nbytes` | `1 << size` | beat 하나의 바이트 수 |
| `aligned` | `addr / nbytes * nbytes` | beat 칸의 시작 |
| `lo` | `addr % BUS` | 쓰기 시작 lane |
| `hi` | `aligned % BUS + nbytes` | 칸 끝 lane (exclusive) |

```systemverilog
for (j = lo; j < hi; j++) strb[j] = 1;
```

addr 7, size 2, BUS 8로 확인하면 `lo = 7 % 8 = 7`, `aligned = 4`, `hi = 4 + 4 = 8`이라 lane `[7, 8)`만 켜져 `0x80`이다.

!!! warning "aligned는 BUS 기준 정렬이 아니다"
    `aligned`는 `nbytes` 기준으로 내린 값이다. BUS 기준으로 정렬하면 칸이 아니라 row의 시작(lane 0)을 가리킨다.

### 5.1 `% nbytes`와 `% BUS`는 용도가 다르다

addr 7, size 2(nbytes 4), BUS 8일 때:

```text
addr % nbytes = 7 % 4 = 3   → 4B 칸 안에서의 offset
addr % BUS    = 7 % 8 = 7   → lane 번호 (strb 몇 번 비트)

lane:     7  6  5  4 | 3  2  1  0
          └─ 4B 칸 ─┘
           3  2  1  0   ← 칸 안 offset (% nbytes)
```

- `% nbytes`는 `aligned`를 만드는 데 쓴다 (`aligned = addr - addr % nbytes`).
- strb 비트 위치는 항상 `% BUS`로 정한다.
- 칸 시작 lane이 `aligned % BUS = 4`이고 offset이 3이므로 `lo = 4 + 3 = 7`이다. 결국 `addr % BUS`와 같다.

### 5.2 aligned를 BUS 기준으로 하면 틀린다

```text
aligned_bus = 7 & ~(8-1) = 0      ← row 시작으로 가 버림
lo = 7 % 8           = 7
hi = 0 % 8 + 4       = 4          ← 칸 끝이 lane 4?

구간 [7, 4) → lo > hi라 아무것도 안 켜짐 → WSTRB = 0x00 ❌ (정답 0x80)
```

```text
lane:       7  6  5  4 | 3  2  1  0
진짜 칸:    [  4B 칸  ]                ← aligned = 4 (size 기준)
잘못된 칸:              [  4B 칸  ]    ← aligned = 0 (BUS 기준)
쓰는 주소:   ^ lane 7
```

| 정렬 기준 | 의미 | 쓰는 곳 |
|---|---|---|
| size(`nbytes`) 기준 aligned | 이 beat이 맡는 칸의 시작 | strb 계산 |
| BUS 기준 aligned | 메모리 row의 시작 | slave가 row를 정할 때 (`addr / BUS`) |

!!! tip "언제는 괜찮은가"
    `nbytes = BUS`이면 칸 하나가 row 하나라서 두 값이 같다. 4.1의 addr 3, size 3 예제가 그 경우다. 그래서 narrow + unaligned 조합을 꼭 테스트해야 버그가 드러난다.

---

## 6. 16cm 자 비유 (BUS 16, nbytes 4)

`aligned`를 구하는 것은 "내 위치에서 바로 앞의 굵은 눈금으로 돌아가기"이다.

```text
| 0 1 2 3 | 4 5 6 7 | 8 9 10 11 | 12 13 14 15 |
   칸0       칸1        칸2          칸3
```

- 4가 16을 딱 나눠떨어진다(둘 다 2의 거듭제곱).
- 그래서 굵은 눈금(칸 시작)은 자 위에서 0, 4, 8, 12에만 온다.
- 이 네 곳이 곧 lane 시작이다.
- 칸이 자(버스 row) 경계를 걸치는 일이 없다.

!!! warning "눈금이 2의 거듭제곱이 아니면"
    3cm마다 눈금이 있으면 0, 3, 6, 9…처럼 자 끝을 넘어 걸쳐 버려서 이 성질이 깨진다. 1, 2, 4, 8처럼 2의 거듭제곱이라 딱 나눠떨어지는 것이 핵심이다.

BUS 8, nbytes 4로 보면 칸이 한 줄에 딱 2개 들어가서 `aligned % BUS`가 칸이 시작하는 lane을 그대로 알려준다.

| aligned | `aligned % 8` | 칸 |
|---|---|---|
| 4 | 4 | lane 4~7 |
| 8 | 0 | lane 0~3 |
| 12 | 4 | lane 4~7 |

---

## 7. 16cm 자 예제

| 예 | addr | aligned | aligned % BUS | lo | hi | 켜지는 lane |
|---|---|---|---|---|---|---|
| 1 | 10 | 8 | 8 | 10 | 12 | 10, 11 |
| 2 | 23 | 20 | 4 | 7 | 8 | 7 |

- 예1) addr 10: 앞 굵은 눈금 = 8 = `aligned` → lane 8~11 칸. 10부터 칸 끝(12) 전까지 → lane 10, 11 켜짐.
- 예2) addr 23: `23 % 16 = 7` → 두 번째 자의 7cm 위치. 앞 굵은 눈금 20, `20 % 16 = 4` → lane 4~7 칸. `lo = 7`이므로 lane 7만 켜짐.

---

## 8. hi 식 읽는 법과 결론

```text
hi = aligned % BUS + nbytes
     └─① nbytes로 굵은 눈금 찾기 (aligned)
           └─② % BUS로 자 위의 위치로 바꾸기 (칸 시작 lane)
                     └─③ 칸 크기만큼 더하면 칸 끝 lane
```

- `lo`는 내 주소를 그대로 자 위치로 바꾼 값이라 "어디서부터"이다.
- `hi`는 굵은 눈금 + 칸 크기라 "어디까지"이다.

!!! tip "한 줄 정리"
    lane은 주소로 고정되고 그 계산은 master가 한다. 굵은 눈금이 항상 0, 4, 8, 12에만 오니까 `aligned % BUS`를 하면 몇 번째 칸(어느 lane 덩어리)인지 바로 나온다.

---

## 9. 개념 정리: AXI 정렬과 lane

> 여기서 `nbytes`는 `1<<size`이고, `BUS`는 데이터 버스 폭을 바이트로 센 값이에요.

| 단계 | 핵심 |
|---|---|
| 1 | size로 정렬해서 beat 칸을 정해요 |
| 2 | 다음 beat는 칸 시작 + `nbytes` |
| 3 | `addr / BUS`는 버스 기준 줄 |
| 4 | lane은 줄 안의 제자리로 가는 고정 통로 |
| 5 | WSTRB는 칸 안에서 실제로 쓸 바이트 표시 |

### 1. size로 정렬해서 beat 칸을 정해요

size에 따라 beat 하나가 보내는 바이트 수(`nbytes`)가 달라져요. 그래서 칸 경계도 size로 정해지고, 이건 스펙 공식 `Aligned_Address = Start / Number_Bytes × Number_Bytes`로 명시된 규칙이에요.

```
aligned = addr / nbytes * nbytes     // 칸 시작
aligned + nbytes - 1                 // 칸 끝
```

이렇게 하면 beat 하나는 정렬된 메모리 칸 하나만 맡고, 칸 경계를 넘지 않아요.

### 2. 다음 beat는 칸 시작에 nbytes를 더한 곳이에요

`aligned += nbytes`로 넘어가요. 첫 beat만 unaligned일 수 있고, 그다음 beat부터는 칸을 빈틈없이 이어서 채워요. BUS 기준으로 정렬하면 narrow 전송에서 구멍이 생겨요.

### 3. addr / BUS는 버스 기준 줄이에요

W 채널에는 주소가 없어요. 그래서 slave가 AW로 받은 주소를 가지고 beat마다 직접 계산해요. 실제 메모리 줄(예: 64B)이 몇 번째인지, 그 줄 안의 어느 위치인지는 slave나 메모리 컨트롤러가 주소를 보고 알아서 정해요.

### 4. lane은 데이터를 줄 안의 제자리로 바로 보내는 고정 통로예요

lane n은 `WDATA[8n+7 : 8n]`이고, 버스 줄 안의 n번째 바이트 자리와 1:1로 연결돼 있어요. master는 각 바이트를 자기 주소에 맞는 lane에 실어 보내요. 그 lane 번호는 `addr % BUS`이고, 주소의 아래 `log2(BUS)`비트와 같아요. 그래서 slave는 shift나 재배치 없이 그대로 쓸 수 있어요.

### 5. WSTRB는 칸 안에서 실제로 쓸 바이트를 표시해요

```
lo = addr % BUS
hi = aligned % BUS + nbytes     // hi 자리는 포함하지 않아요
```

`lo`부터 `hi` 바로 앞까지 켜요. 첫 beat가 unaligned면 칸의 앞부분이 꺼지고, 나머지 beat는 칸을 꽉 채워요.

### 전체 흐름

1. AW로 주소, size, len을 보내요.
2. master와 slave가 각각 beat마다 aligned를 계산해서 칸과 버스 줄을 정해요.
3. master가 데이터를 lane에 실어서 WSTRB와 함께 보내요.
4. slave는 WSTRB가 켜진 lane의 바이트만 계산한 위치에 그대로 써요.

!!! tip "성립하는 이유"
    size와 BUS가 둘 다 2의 거듭제곱이라, 칸이 버스 줄 경계를 절대 넘지 않아요. 그래서 `aligned % BUS`가 항상 그 칸이 시작하는 lane이 돼요.
