# UVM Driver / Monitor에서의 Blocking(`=`) vs Non-blocking(`<=`)

**1. Race condition이 발생하는 이유**
- **핵심**: **Driver에서 DUT로 인가하는 값이랑, DUT가 그 값을 read해 갈 때의 값 사이에서 race condition이 발생해요.**
- 같은 `posedge clk` 순간에 시뮬레이터가 Driver(쓰기)와 DUT(읽기) 중 누구를 먼저 실행할지 정해져 있지 않아서예요.
  - Driver가 먼저 쓰면: DUT는 **새 값(`AA`)**을 읽음 (한 사이클 빨라짐)
  - DUT가 먼저 읽으면: DUT는 **이전 값(`00`)**을 읽음

**2. 시뮬레이터의 처리 순서 (한 시각 안의 두 단계)**
1. **Active 단계**: 신호 읽기(read), `=` 실행 (누가 먼저 실행될지 **순서 랜덤**)
2. **NBA 단계**: Active 단계가 다 끝난 뒤, `<=`로 예약해 둔 값들을 **한꺼번에 쓰기**

**3. 그래서 Driver와 Monitor는 어떻게 쓰나?**

| 구분 | 쓰는 연산자 | 이유 | 반대로 쓰면 생기는 일 |
|---|---|---|---|
| **Driver** | `<=` (non-blocking) | 값 인가를 NBA 단계로 미뤄서, DUT가 Active 단계에서 항상 먼저 read하게 하려고 (race 방지) | `=`를 쓰면 Driver가 인가하는 값과 DUT가 read하는 값 사이에 race가 나서 결과가 매번 달라짐 |
| **Monitor** | `=` (blocking) | DUT 신호를 read만 해서 race가 없고, 읽은 값을 `tr`에 즉시 담아 바로 다음 줄 `ap.write(tr)`로 보내야 해서 | `<=`를 쓰면 값이 담기기 전에 `ap.write(tr)`가 먼저 실행돼서 0(새 객체)이나 이전 값(재사용 시)이 전송됨 |

**한 줄 핵심**
- **Driver**: 내가 인가하는 값과 DUT가 read하는 값이 부딪히지 않게 미루려고 `<=`
- **Monitor**: read한 값을 내 변수에 즉시 담아 바로 다음 줄에 보내려고 `=`
