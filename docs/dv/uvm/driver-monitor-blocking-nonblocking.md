# UVM Driver / Monitor에서의 Blocking(`=`) vs Non-blocking(`<=`)

> **Driver는 `<=`**로 값 인가를 한 템포 미뤄 DUT와의 race를 피하고, **Monitor는 `=`**로 읽은 값을 즉시 변수에 담아 바로 전송한다.

---

## 1. Race Condition이 발생하는 이유

**Driver에서 DUT로 인가하는 값**과, **DUT가 그 값을 read해 갈 때의 값** 사이에서 race condition이 발생한다.

같은 `posedge clk` 순간에 시뮬레이터가 **Driver(쓰기)**와 **DUT(읽기)** 중 누구를 먼저 실행할지 정해져 있지 않기 때문이다.

```text
@(posedge clk) 순간 — Driver가 data에 'hAA를 쓰려고 할 때 (이전 값 'h00)

  경우 A: Driver(쓰기) 먼저 실행 ──> DUT(읽기) 실행  ⇒  DUT는 새 값('hAA)을 읽음 (1사이클 빨라짐!)
  경우 B: DUT(읽기) 먼저 실행    ──> Driver(쓰기) 실행  ⇒  DUT는 이전 값('h00)을 읽음
```

| 실행 순서 (랜덤) | DUT가 읽는 값 | 결과 |
| --- | --- | --- |
| **Driver 먼저** → DUT 나중 | **새 값 (`AA`)** | 의도보다 **한 사이클 빨라짐** ⚠️ |
| **DUT 먼저** → Driver 나중 | **이전 값 (`00`)** | 정상 타이밍 |

---

## 2. 시뮬레이터의 처리 순서 (한 시각 안의 두 단계)

시뮬레이터는 같은 `posedge clk` 시각 안을 **Active → NBA** 두 단계로 나누어 처리한다.

```text
같은 @(posedge clk) 시각 내부
┌─────────────────────────────────────────┐      ┌─────────────────────────────────────────┐
│ 1단계: Active 영역                      │      │ 2단계: NBA (Non-Blocking) 영역          │
│  • 신호 읽기 (DUT read, Monitor read)   │ ───> │  • Active가 다 끝난 뒤,                 │
│  • Blocking 대입 (=) 즉시 실행          │      │    <= 로 예약해 둔 값들을 한꺼번에 쓰기 │
│  ⚠️ 누가 먼저 실행될지 순서 랜덤        │      │  ✅ 읽기가 모두 끝난 뒤라 충돌 없음     │
└─────────────────────────────────────────┘      └─────────────────────────────────────────┘
```

- **1단계 — Active 영역**: 신호 읽기(`read`)와 `=`(blocking) 실행 (누가 먼저 실행될지 **순서 랜덤**)
- **2단계 — NBA 영역**: Active 단계가 다 끝난 뒤, `<=`(non-blocking)로 예약해 둔 값들을 **한꺼번에 쓰기**

---

## 3. 그래서 Driver와 Monitor는 어떻게 쓰나?

| 구분 | 쓰는 연산자 | 이유 | 반대로 쓰면 생기는 일 |
| --- | --- | --- | --- |
| **Driver** | **`<=`** (non-blocking) | 값 인가를 **NBA 단계**로 미뤄서, DUT가 Active 단계에서 항상 먼저 read하게 하려고 (race 방지) | `=`를 쓰면 Driver가 인가하는 값과 DUT가 read하는 값 사이에 race가 나서 결과가 매번 달라짐 |
| **Monitor** | **`=`** (blocking) | DUT 신호를 **read만** 해서 race가 없고, 읽은 값을 `tr`에 즉시 담아 바로 다음 줄 `ap.write(tr)`로 보내야 해서 | `<=`를 쓰면 값이 담기기 전에 `ap.write(tr)`가 먼저 실행돼서 `0`(새 객체)이나 이전 값(재사용 시)이 전송됨 |

### 코드 비교

```systemverilog
// ✅ Driver: <= 로 NBA 영역에 예약 (DUT가 Active에서 안전하게 먼저 읽음)
@(posedge vif.clk);
vif.valid <= 1'b1;
vif.data  <= tr.data;
```

```systemverilog
// ✅ Monitor: = 로 즉시 담아서 바로 다음 줄 ap.write(tr)로 전송
@(posedge vif.clk);
if (vif.valid && vif.ready) begin
  tr.data = vif.data;   // 즉시 대입 완료
  ap.write(tr);         // 방금 읽은 값이 정상 전송됨
end
```

!!! tip "한 줄 핵심"
    - **Driver (`<=`)**: 내가 인가하는 값과 DUT가 read하는 값이 부딪히지 않게 미루려고 **`<=`**
    - **Monitor (`=`)**: read한 값을 내 변수에 즉시 담아 바로 다음 줄에 보내려고 **`=`**
