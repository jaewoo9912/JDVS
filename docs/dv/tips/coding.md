# 코딩 Tips — 개념을 코드로 옮기기 (WSTRB 예제)

> 개념을 코드로 옮길 때는 **입출력 → 손으로 풀기 → 반복 찾기 → if로 일단 동작 → 공통 규칙으로 if 제거 → 손 풀이로 검증** 순서로 간다. 예제는 AXI VIP의 **WSTRB 생성**(`gen_strb()`)이다.

---

## 0. 6단계 한눈에

| 단계 | 할 일 |
| --- | --- |
| 1 | 입력과 출력부터 적기 |
| 2 | 종이에 예제를 표로 직접 풀기 |
| 3 | 매 줄마다 반복한 계산 찾기 |
| 4 | 특수 케이스를 `if`로 나눠 **일단 동작**하게 짜기 |
| 5 | 경우들을 나란히 놓고 **공통 규칙**을 찾아 `if` 없애기 |
| 6 | 손으로 푼 표를 **기대값**으로 두고 검증하기 |

---

## 1. 입력과 출력부터 적기

**"뭘 받아서 뭘 내놓지?"**를 먼저 적는다.

| 구분 | 값 | 의미 |
| --- | --- | --- |
| 입력 | `addr` = 3 | 첫 바이트가 놓이는 주소 |
| 입력 | `data_len` = 63B | 실제로 쓸 총 바이트 수 |
| 입력 | `size` = 4 | beat 하나가 2^4 = **16B** |
| 입력 | `bus` = 64B | 버스 폭 (lane 개수) |
| 출력 | `q_strb[$]` | beat마다 strb 하나씩 담긴 큐 |

```systemverilog
// 입력: addr, data_len, size, bus → 출력: q_strb[$]
function void gen_strb();
```

---

## 2. 종이에 예제를 표로 풀기

아직 코드는 생각하지 말고 **숫자만** 본다.

- 전체에서 쓸 범위: 주소 3 ~ 65, 끝 미포함으로 **`[3, 66)`**
- beat 하나의 크기: **16B**
- 첫 beat는 3이 들어있는 16B 칸(0 ~ 15)부터 시작

| beat | 담당 주소 | 실제 쓰는 주소 | 켜질 lane (주소 % 64) | 비고 |
| --- | --- | --- | --- | --- |
| 0 | 0 ~ 15 | 3 ~ 15 | 3 ~ 15 | 앞 3바이트 잘림 |
| 1 | 16 ~ 31 | 16 ~ 31 | 16 ~ 31 | |
| 2 | 32 ~ 47 | 32 ~ 47 | 32 ~ 47 | |
| 3 | 48 ~ 63 | 48 ~ 63 | 48 ~ 63 | |
| 4 | 64 ~ 79 | 64 ~ 65 | 0 ~ 1 | 뒤가 잘리고, lane이 0으로 돌아감 |

- 총 beat는 5개 → `AWLEN = 4`

!!! warning "lane vs beat"
    - **lane**: bus의 바이트 칸 수. 64B bus면 항상 **64개** (WSTRB도 64비트)
    - **beat**: 몇 번에 나눠 보내냐. 이번 트랜잭션은 **5번**
    - size=4라 한 beat에 최대 16개 lane만 켜진다. 64개 lane이 16개씩 4묶음으로 나뉘고, 5번째 beat에서 다시 첫 묶음으로 돌아온다.

### 결과물보다 주소를 먼저 그리기

WSTRB는 **결과물**이라 WSTRB부터 보면 막힌다. **주소를 먼저 그리면 WSTRB는 저절로 따라 나온다.**

| 순서 | 하는 일 |
| --- | --- |
| 칠하기 | 메모리를 자로 그리고 전체 구간 칠하기 (3 ~ 65) |
| 자르기 | `size`(16B)마다 칸막이 긋기 → 칸 하나 = beat 하나 |
| 겹치기 | 칸마다 칠해진 부분만 남기기 → 그 beat가 실제로 쓰는 주소 |
| 접기 | 주소를 bus(64)로 나눈 나머지 = lane → 64번지가 다시 lane 0 |

### 일반 틀

"칠하고, 자르고, 겹치고, 접기"는 WSTRB 전용이 아니라 **주소·데이터를 다루는 거의 모든 VIP 로직**에 쓰는 틀이다.

1. **전체 구간** `[lo, hi)`를 정한다.
2. **단위 구간**으로 자른다 (beat, 버스 한 줄, 4KB 페이지, wrap 경계 등).
3. 단위마다 **교집합** `max(lo)`, `min(hi)`를 구한다.
4. 필요하면 **좌표를 변환**한다 (주소 % bus = lane, 주소 / 4096 = page 번호).

| 적용 예 | 구간 / 단위 |
| --- | --- |
| 4KB 경계 체크 | 전체 구간이 4KB 칸 2개에 걸치면 에러 |
| WRAP 주소 계산 | 단위 = wrap 경계 한 칸, 넘어가면 칸의 시작으로 |
| slave 메모리 write | beat 구간을 버스 한 줄로 접어서 lane마다 기록 |
| scoreboard 비교 | 기대 구간과 실제 구간의 교집합만 비교 |
| burst 쪼개기 (DMA) | 4KB나 max len 단위로 자르고 각 교집합을 새 transaction으로 |

!!! tip "새 문제를 만나면 세 가지를 묻기"
    무슨 **구간**인가? 무슨 **단위**로 자르나? 결과를 무슨 **좌표**로 바꾸나?

!!! tip "구간은 끝 미포함 `[lo, hi)`"
    `hi - lo`가 바로 바이트 수가 되어 경계 계산이 깔끔해진다.

---

## 3. 매 줄마다 반복한 계산 찾기

표의 한 줄을 만들 때 **머릿속에서 한 일**을 적는다.

1. 담당 주소의 **시작**: 0, 16, 32, 48, 64 (16씩 증가)
2. 담당 주소의 **끝**: 시작 + 16
3. **실제 쓰는 주소**: 담당 주소와 전체 범위(3 ~ 65)의 겹치는 부분
4. **lane**: 실제 쓰는 주소 % 64

| 구분 | 값 | 코드에서 |
| --- | --- | --- |
| 매 줄마다 한 일 | 위 1 ~ 4 | **루프 안 코드** (beat 개수만큼 반복) |
| 매번 바뀐 값 | beat 번호, 담당 시작/끝, 실제 시작/끝 | **루프 안 지역 변수** (`beat_lo`, `beat_hi`, `vld_lo`, `vld_hi`) |
| 안 바뀐 값 | 전체 범위, beat 크기, bus | **루프 밖에서 한 번만** (`total_lo`, `total_hi`, `nbytes`, `bus`) |

---

## 4. if로 나눠 일단 동작하게 짜기

깔끔함은 신경 쓰지 말고 3번의 손 계산을 **그대로** 옮긴다.

```systemverilog
// ① 루프 밖: 안 바뀌는 값
bus      = 64;                                          // lane 개수
nbytes   = 1 << size;                                   // 16 (beat 크기)
total_lo = addr;                                        // 3
total_hi = addr + data_len;                             // 66 (끝 미포함)
aligned  = (addr >> size) << size;                      // 0 (첫 beat 담당 시작)
n_beats  = (total_hi - aligned + nbytes - 1) / nbytes;  // 5 (올림)

for (int i = 0; i < n_beats; i++) begin
  // ② beat마다 담당 구간
  beat_lo = aligned + i * nbytes;   // 0, 16, 32, 48, 64
  beat_hi = beat_lo + nbytes;       // 16, 32, 48, 64, 80

  // ③ 실제 쓰는 구간을 if로 나누기
  if (i == 0) begin                 // 첫 beat: 앞이 잘림
    vld_lo = total_lo;
    vld_hi = beat_hi;
  end
  else if (i == n_beats - 1) begin  // 마지막 beat: 뒤가 잘림
    vld_lo = beat_lo;
    vld_hi = total_hi;
  end
  else begin                        // 중간 beat: 통째로
    vld_lo = beat_lo;
    vld_hi = beat_hi;
  end

  // ④ 주소 → lane으로 바꿔 켜고 저장
  strb = '0;
  for (int j = vld_lo; j < vld_hi; j++)
    strb[j % bus] = 1;
  q_strb.push_back(strb);
end
```

- beat0은 첫 번째 if에서 `[3, 16)`, beat1 ~ 3은 else에서 통째로, beat4는 두 번째 if에서 `[64, 66)`

---

## 5. 공통 규칙을 찾아 if 없애기

!!! warning "4번 코드의 구멍: beat가 1개일 때"
    addr=3, data_len=5면 범위는 `[3, 8)`, beat는 하나다. `i == 0`이 먼저 걸려 `vld_hi = beat_hi = 16`이 되고, lane 3 ~ 15가 켜져 **8 ~ 15를 잘못 쓴다.** 첫 beat이면서 마지막 beat라 앞뒤를 둘 다 잘라야 하는데 if 하나만 타서 생기는 문제다.

세 경우를 나란히 놓고 본다.

| 경우 | `vld_lo` | `vld_hi` |
| --- | --- | --- |
| 첫 beat | `total_lo` (3) | `beat_hi` (16) |
| 중간 beat | `beat_lo` | `beat_hi` |
| 마지막 beat | `beat_lo` (64) | `total_hi` (66) |

- `vld_lo`는 항상 **`beat_lo`와 `total_lo` 중 큰 값** (max)
- `vld_hi`는 항상 **`beat_hi`와 `total_hi` 중 작은 값** (min)

```systemverilog
for (int i = 0; i < n_beats; i++) begin
  beat_lo = aligned + i * nbytes;
  beat_hi = beat_lo + nbytes;
  vld_lo  = (beat_lo > total_lo) ? beat_lo : total_lo;   // max
  vld_hi  = (beat_hi < total_hi) ? beat_hi : total_hi;   // min

  strb = '0;
  for (int j = vld_lo; j < vld_hi; j++)
    strb[j % bus] = 1;
  q_strb.push_back(strb);
end
```

- beat가 1개여도 `max(0, 3) = 3`, `min(16, 8) = 8` → `[3, 8)`로 **구멍이 저절로 막힌다.**

---

## 6. 손으로 푼 표를 기대값으로 검증하기

2번 표가 그대로 **정답지**가 된다. lane a ~ b가 켜진 마스크는 `((1 << (b-a+1)) - 1) << a`.

```systemverilog
JaxiStrb_t exp[5];
exp[0] = ((64'h1 << 13) - 1) << 3;   // lane 3~15
exp[1] = 64'hFFFF << 16;             // lane 16~31
exp[2] = 64'hFFFF << 32;             // lane 32~47
exp[3] = 64'hFFFF << 48;             // lane 48~63
exp[4] = 64'h3;                      // lane 0~1

initial begin
  item = new();
  item.addr = 3; item.size = 4; item.data_len = 63;
  item.gen_strb();

  if (item.q_strb.size() != 5)
    $error("beat 수 틀림: %0d", item.q_strb.size());

  foreach (item.q_strb[i]) begin
    if (item.q_strb[i] !== exp[i])
      $error("beat%0d 틀림: got=%h exp=%h", i, item.q_strb[i], exp[i]);
    else
      $display("beat%0d OK: %h", i, item.q_strb[i]);
  end
end
```

- **beat 수부터** 확인한다. 개수가 틀리면 뒤 비교는 의미가 없다.
- 비교는 **`!==`** 로 한다 (X를 놓치지 않게).
- 틀리면 몇 번째 beat인지 바로 보여서, 앞 자르기 / 뒤 자르기 / lane 되돌아가기 중 어느 규칙이 틀렸는지 알 수 있다.

| 경우 | 입력 | 기대 결과 |
| --- | --- | --- |
| aligned, full | addr=0, size=6, data_len=128 | beat 2개, 전부 1 |
| beat 1개 | addr=3, data_len=5 | lane 3 ~ 7만 (5번에서 막은 구멍) |
| narrow | addr=0, size=2, data_len=16 | lane 0~3, 4~7, 8~11, 12~15 |
| lane 되돌아감 | 위 예제 | beat4가 lane 0 ~ 1 |

---

## 7. 문법 팁

| 표현 | 가능? | 이유 |
| --- | --- | --- |
| `strb[j % bus]` | O | 식을 계산한 값 **하나**로 비트 하나를 고르는 bit-select |
| `strb[vld_hi-1 : vld_lo]` | X | 양쪽 끝이 다 변수라 폭이 컴파일 때 고정되지 않음 |
| `strb[lo +: 4]`, `wdata[b*8 +: 8]` | O | 폭이 상수면 `[lo +: N]` 사용 |

!!! tip
    켤 비트 개수가 beat마다 달라지는 WSTRB는 `for` 루프로 **비트 하나씩** 켜는 게 가장 안전하다.

---

## 8. 관련 개념 — byte lane은 주소에 고정

- narrow / unaligned에서도 **byte lane은 주소에 고정**(`주소 % bus`)이다.
- lane을 맞추는 건 **master 책임**이고, slave는 데이터를 옮겨주지 않는다. 그래서 `gen_strb()`가 `j % bus`로 lane 위치를 계산한다.
