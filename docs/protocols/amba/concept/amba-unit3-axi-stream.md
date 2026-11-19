# Unit 3 — AXI-Stream (주소를 버린 버스)

> 핵심 질문: AXI는 "어디에(주소) 읽고 쓰나"를 말하는 버스였다. 그런데 **비디오 픽셀, 오디오 샘플, 네트워크 패킷, DSP 데이터**처럼 *주소가 없고 그냥 순서대로 흘러가는* 데이터엔 그게 다 과잉이다. AXI-Stream은 AXI에서 **주소를 통째로 떼어낸** 순수 "데이터 흐름" 프로토콜이다. 그럼 주소를 버리면 무엇이 사라지고(read/write·응답·랜덤접근), 무엇으로 대체되나(packet·TLAST·TID/TDEST 라우팅)?
>
> ※ 이 단원을 읽으며 나온 세부 질문(픽셀이 주소 없이 어떻게 흐르나, AXI는 왜 응답이 필요한가·BRESP vs RRESP, interleave 단위, in-order/out-of-order 개념, TKEEP vs TSTRB)은 별도 페이지 **`amba-unit3-qa.md`** 에 던진 순서대로 정리돼 있다.

## 0. 핵심 한 문장

> **AXI-Stream = "AXI의 데이터 채널 하나만 떼어내, 주소·응답 없이 한 방향으로 데이터를 흘리는" 점대점(point-to-point) 스트리밍 프로토콜.** memory-mapped(어디에)가 아니라 dataflow(무엇을, 순서대로)다. VALID/READY 핸드셰이크는 AXI에서 그대로 가져오고, 버스트(주소 기반 beat) 대신 **TLAST로 끊는 packet** 개념이 들어온다.

---

## 1. 왜 AXI가 아니라 AXI-Stream인가

Unit 2에서 AXI의 강력함은 전부 **"주소"** 위에 세워졌다 — 5채널, ID ordering, outstanding, out-of-order. 이 모든 기계장치는 **"어디에(address)"가 의미 있을 때만** 값을 한다.

스트리밍 데이터는 그렇지 않다:

```text
픽셀·샘플·패킷 byte는 "몇 번지"가 없다. 오직 "다음 것, 그 다음 것" — 순서가 전부.
랜덤 접근 안 함. 한 번 흐르면 끝. 되돌아가 읽지 않음.
```

여기에 AXI를 붙이면 안 쓰는 기능에 면적·전력·검증비용만 낸다:

| AXI 기능 | 스트리밍에서 | |
|---|---|---|
| 주소 디코더 | 주소가 없으니 | **불필요** |
| read/write 양방향 | 한 방향으로만 흐름 | **불필요** |
| ID ordering / OoO | 그냥 순서대로 | **불필요** |
| outstanding 버퍼 | 응답 기다릴 게 없음 | **불필요** |
| B/R 응답 채널 | 성공/실패 응답 안 씀 | **불필요** |

> ARM은 "주소를 통째로 떼고, 데이터 채널 하나만 남긴" 별도 프로토콜을 만들었다. **AXI-Stream = AXI에서 W(또는 R) 데이터 채널 하나를 독립시킨 것.** Unit 1의 "트래픽에 맞는 최소한의 버스" 철학이 여기도 그대로 — 스트리밍엔 스트리밍용 최소 버스. (픽셀이 주소 없이 실제로 어떻게 흐르나 → Q&A Q1)

---

## 2. 왜 이렇게 설계되었는가 (각 결정의 이유)

AXI-Stream의 설계는 "버릴 건 버리고, 검증된 건 재사용하고, 꼭 필요한 것만 더한다"의 모범 사례다.

### 2-1. VALID/READY를 그대로 가져왔다 — 재발명 안 함

```text
TVALID (source→sink): "내 데이터 유효"
TREADY (sink→source): "받을 준비됨"
전송 성립 = 에지에서 TVALID=1 AND TREADY=1
```

Unit 2의 비대칭 규칙(**TVALID는 TREADY를 안 기다린다**)도, backpressure도, READY 구현 자유(Unit 2 Q7)도 전부 동일. 검증된 핸드셰이크를 그대로 써서 데드락-안전을 공짜로 얻었다.

### 2-2. byte 지향(TDATA는 byte의 배수) — 폭 변환이 공짜

`TDATA` 폭은 **항상 8의 배수**(byte 단위). 스트림은 폭이 다른 블록끼리 연결되기 때문(8비트 센서 → 32비트 필터 → 64비트 DMA). byte 단위면 **폭 변환이 그냥 byte 재포장**이 된다.

```text
32bit 스트림(4 byte) → 64bit 스트림(8 byte): 2 transfer를 1 transfer로 묶기만
                                              (byte 경계가 안 깨지니 단순)
```

### 2-3. 응답 채널을 안 만들었다 — flow control은 backpressure뿐

스트림엔 B/R 같은 응답이 없다. sink가 못 따라가면 **TREADY=0으로 source를 멈출** 뿐(backpressure). AXI가 응답을 둔 진짜 이유는 "데이터 받음 확인"이 아니라 **"주소 접근의 결과(성공/실패/유효)"** 를 알리기 위해서인데, AXI-Stream은 주소 접근 자체가 없어 보고할 결과가 없다. 앱 레벨 에러(CRC 등)는 `TUSER` 사이드밴드로 싣는 게 관례. (왜 AXI는 응답이 필요한가·BRESP는 버스트당 1번인데 RRESP는 beat마다인 비대칭 → Q&A Q2)

### 2-4. 꼭 필요한 것만 사이드밴드로 더했다

```text
packet 경계      → TLAST       (영상 한 줄/프레임 끝, 패킷 끝)
부분/빈 byte      → TKEEP/TSTRB (마지막 transfer가 lane을 다 못 채울 때)
여러 스트림 구분   → TID         (어느 source인가)
라우팅 목적지     → TDEST       (어디로 보낼까)
확장 여지         → TUSER       (사용자 정의)
```

> **한 줄:** AXI-Stream의 설계 = **VALID/READY는 재사용(데드락-안전 공짜), byte 지향(폭 변환 단순), 응답은 버림(backpressure만), 스트리밍 고유 필요만 사이드밴드로 추가.** AXI처럼 "값진 자유는 풀고 안 쓰는 건 닫는다"의 또 다른 적용.

---

## 3. AXI vs AXI-Stream (깊게)

| 측면 | AXI (memory-mapped) | AXI-Stream |
|---|---|---|
| 모델 | "어디에(주소)" 읽고 쓴다 | "무엇을" 순서대로 흘린다 |
| 채널 | 5 (AW/W/B/AR/R) | **1** (단방향 데이터) |
| 주소 | `AxADDR` 필수 | **없음** |
| 방향 | read + write | source → sink **단방향** |
| 연결 | interconnect로 N:M | 기본 **점대점**(라우팅은 TDEST) |
| 응답 | `BRESP`/`RRESP` | **없음** (backpressure만) |
| 묶음 | 버스트 `AxLEN` (주소 기반 beat) | **packet** (`TLAST`로 구분) |
| 순서 | 같은 ID in-order, 다른 ID reorder | 스트림 내 **항상 in-order** |
| 식별 | `AxID` (ordering 용도) | `TID`/`TDEST` (**식별·라우팅** 용도) |
| 부분 데이터 | `WSTRB` (write byte enable) | `TKEEP`/`TSTRB` (null·position byte) |
| 4KB 경계 | 있음 | **없음** (주소가 없으니) |
| 핸드셰이크 | VALID/READY | VALID/READY (동일) |

**핵심 차이 3개:**

1. **주소 → packet.** AXI는 주소+길이로 묶음을 정의(`AxADDR`+`AxLEN`). AXI-Stream은 주소가 없으니 **`TLAST`로 "여기까지가 한 묶음"** 을 표시.
2. **ID의 의미가 다르다.** AXI의 `AxID`는 *순서 제어*(같은 ID in-order). AXI-Stream의 `TID`는 *순서가 아니라 식별*(어느 스트림인지 구분). → §9.
3. **WSTRB → TKEEP+TSTRB.** AXI는 "이 byte 쓸까 말까"(write enable) 하나면 충분. 스트림은 "이 byte가 진짜인가/위치만인가/없는가" **3종 구분**이 필요 → §7.

---

## 4. AXI-Stream Timeline (AMBA 족보 속 위치)

```text
AMBA 2 (1999):  AHB, APB
AMBA 3 (2003):  AXI3, AHB-Lite, APB3, ATB(trace)
AMBA 4 (2010):  AXI4, AXI4-Lite, ★ AXI4-Stream ★, ACE/ACE-Lite
AMBA 5 (2013~): CHI, AXI5/ACE5, AHB5
                AXI4-Stream 후속 개정에서 TWAKEUP(저전력 wakeup) 등 추가
```

- **AXI-Stream은 AMBA 4(2010)에서 AXI4와 함께 태어난 형제다.** AXI3 시절엔 없었다.
- **"AXI3-Stream"은 없다.** 스트림은 AXI4 세대에서 처음 표준화됐고, 버전 넘버링이 AXI처럼 3/4/5로 갈리지 않는다 — 그냥 "AXI4-Stream"(흔히 AXIS).
- 그 전엔 벤더별 임시 스트리밍 규격(예: Xilinx LocalLink, Altera Avalon-ST)이 난립했는데, ARM이 AMBA 4에서 표준으로 통일했다. 그래서 요즘 FPGA IP의 데이터 흐름은 거의 다 AXI4-Stream.

---

## 5. 핸드셰이크 + Packet (TLAST)

### 5-1. 핸드셰이크 — AXI에서 그대로

```text
전송 1건 성립 = 클럭 상승 에지에서  TVALID=1 AND TREADY=1
```

Unit 2의 그 비대칭 규칙(**TVALID는 TREADY를 기다려 올리면 안 됨**, 데드락 방지)도 동일. `TREADY`로 **backpressure**(역압) — sink가 느리면 `TREADY=0`으로 source를 멈춘다. 이게 응답 없는 스트림의 유일한 flow control.

### 5-2. Packet과 TLAST — 버스트를 대신하는 "묶음"

주소 기반 버스트가 없으니 "여기까지가 한 덩어리"를 `TLAST`로 알린다.

```text
TVALID  /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\
TDATA   <P0><P1><P2><P3><P4><P5><P6>
TLAST    0   0   0   1   0   0   1
                     ↑            ↑
                  packet A 끝   packet B 끝
```

- `TLAST=1`인 전송이 **packet의 마지막**. 비디오면 "한 라인 끝", 네트워크면 "프레임 끝".
- 비디오 관례: `TUSER` bit0 = SOF(Start of Frame, 첫 픽셀), `TLAST` = EOL(End of Line). 2D 영상을 1D 흐름으로 보내고 받는 쪽이 개수를 세서 (x,y)를 복원한다 — 픽셀에 주소를 붙이지 않는다. (구체 동작 → Q&A Q1)

---

## 6. 필수 / 선택 시그널

```text
필수(2개):   TVALID, TREADY      ← 이것만 있으면 프로토콜 성립
나머지 전부 선택: TDATA, TLAST, TKEEP, TSTRB, TID, TDEST, TUSER
```

- **TDATA조차 선택이다.** 데이터 없는 순수 "이벤트/펄스 스트림"(핸드셰이크만)도 합법.
- 신호를 생략하면 **기본값으로 해석**:

| 생략한 신호 | 기본 해석 |
|---|---|
| `TKEEP` 없음 | 모든 byte가 **data byte** (전부 유효) |
| `TSTRB` 없음 | `TKEEP`을 따름 (kept byte = data byte) |
| `TLAST` 없음 | packet 경계 없음 — **연속 스트림**으로 간주 |
| `TID`/`TDEST` 없음 | 단일 스트림, 라우팅 정보 없음 |

> **실무 감각:** 대부분의 단순 스트림은 `TDATA + TVALID + TREADY + TLAST`만 쓴다. `TKEEP/TSTRB`는 "마지막 transfer가 lane을 다 못 채우거나 sparse일 때"만, `TID/TDEST`는 "여러 스트림이 한 fabric을 공유할 때"만 등장. 핵심은 항상 그 4개.

---

## 7. TKEEP / TSTRB — 조합과 차이

스트림의 한 transfer는 여러 byte lane을 싣는다(예: 32bit = 4 lane). 각 lane의 byte가 **세 종류 중 하나**다.

### 7-1. 두 신호는 다른 질문을 한다

```text
TKEEP : "이 byte를 버려도 돼?"   → 1 = 유지(버리면 안 됨)   0 = 버려도 됨
TSTRB : "이 byte에 값이 있어?"   → 1 = 데이터(값 있음)      0 = 위치만(값 없음)
```

`TKEEP`은 **존재** 여부(남길 byte냐 버릴 쓰레기냐), `TSTRB`는 그 남긴 byte가 **값이 있냐 자리만 차지하냐**. 층이 다르다.

### 7-2. 세 가지 byte type

| `TKEEP` | `TSTRB` | byte 종류 | 의미 |
|:---:|:---:|---|---|
| 1 | 1 | **Data byte** | 진짜 데이터. 보존 O. |
| 1 | 0 | **Position byte** | 값은 없지만 **자리는 보존해야 함**(gap 유지). sparse용. |
| 0 | 0 | **Null byte** | 데이터도 자리도 없음. **제거 가능**. |
| 0 | 1 | ❌ **불법** | "버려도 되는데 값이 있다" = 모순 (TSTRB=1이려면 TKEEP=1) |

### 7-3. 핵심은 Null vs Position 차이

`TKEEP`만으로는 "남길 byte / 버릴 byte" 2가지뿐. 스트림엔 3번째 — "값은 없지만 버리면 안 되는 빈자리" — 가 필요해서 `TSTRB`가 추가된다.

```text
Null byte    (TKEEP=0)        : 인터커넥트가 빼버려도 됨. 빼도 의미 안 변함.
Position byte (TKEEP=1,TSTRB=0): 빼면 안 됨! 빼면 뒤가 당겨져 정렬이 깨짐.
```

```text
책장 비유:
  TKEEP=1,TSTRB=1 : 책이 꽂혀 있음           (데이터)
  TKEEP=1,TSTRB=0 : 일부러 비워둔 예약석       (position — 비운 채 유지)
  TKEEP=0         : 책장 끝 여분 공간          (null — 잘라내도 그만)
```

### 7-4. 4가지 스트림 타입

```text
① Continuous aligned   : TKEEP=TSTRB=전부 1. null·position 없음. (제일 단순)
② Continuous unaligned : 앞/뒤에 null byte 허용 (데이터가 lane0부터 안 시작/끝 안 맞음)
③ Sparse              : position byte로 중간 구멍 표현
④ Byte stream         : transfer마다 byte 수가 가변
```

> **한 줄:** `TKEEP`=실재 여부(없애도 되나), `TSTRB`=데이터냐 위치냐. 조합으로 **Data(11)/Position(10)/Null(00)** 3종, **01은 불법**. byte 하나로는 못 하는 "지워도 되는 빈칸(null) vs 지우면 안 되는 구멍(position)" 구분을 위해 신호가 둘. 단순 스트림은 둘 다 전부 1이라 신경 안 써도 되고, 자투리(null)·구멍(position)에서만 갈린다. (자세히 → Q&A Q6)

---

## 8. TKEEP 검산 (구체 숫자로)

`TKEEP`가 헷갈리는 건 마지막 transfer다.

### 8-1. 기본 예 — 10 byte 패킷, 32bit(4 byte) 스트림

```text
패킷 길이 N = 10 byte,  스트림 폭 W = 4 byte

transfer 수 = ceil(N / W) = ceil(10/4) = 3
마지막 transfer의 유효 byte = N mod W = 10 mod 4 = 2  (0이면 W로 꽉 참)
마지막 transfer의 null byte = W - (N mod W) = 4 - 2 = 2
```

```text
            lane:  3 2 1 0
transfer0  TKEEP:  1 1 1 1   (byte 0~3)   TLAST=0
transfer1  TKEEP:  1 1 1 1   (byte 4~7)   TLAST=0
transfer2  TKEEP:  0 0 1 1   (byte 8,9 + null 2개)  TLAST=1
                   └null┘ └data┘
```

continuous 스트림이면 kept byte = data byte라서 `TSTRB = TKEEP` (둘 다 `0011`).

### 8-2. 검산 공식 — 합이 맞아야 한다

```text
Σ (각 transfer의 TKEEP에서 1의 개수)  =  패킷 총 byte 수
위 예: 4 + 4 + 2 = 10  ✓  (= N)
```

- 어긋나면 → packet 길이 계산 오류 or TKEEP 생성 버그.
- sparse 스트림이면 "데이터 byte"는 `TSTRB=1`만 세야 함: `Σ popcount(TSTRB) = 실제 데이터 byte`, `Σ popcount(TKEEP) = 데이터+위치 byte`.

### 8-3. 딱 떨어질 때 (함정)

```text
N = 8 byte, W = 4 byte → transfer 수 = 2, N mod W = 0 → 마지막도 꽉 참(null 없음)
transfer0 TKEEP: 1111  TLAST=0
transfer1 TKEEP: 1111  TLAST=1   ← null byte 0개
검산: 4 + 4 = 8 ✓
```

→ `N mod W == 0`이면 마지막 transfer에 null이 **하나도 없다.** "마지막엔 항상 null이 있다"고 착각하면 틀림. 검증 단골 코너.

---

## 9. TID / TDEST — 차이와 멀티스트림 라우팅

### 9-1. 둘의 차이 (그리고 AXI의 ID와도 다름)

```text
TID   = "누가 보냈나 / 어느 흐름인가"  (source 식별자, 송신자 라벨)
TDEST = "어디로 가나"                 (목적지, 라우팅 주소 — coarse)
```

```text
네트워크 비유:  TID  ≈ 발신지/flow ID (섞였을 때 되돌리기용)
              TDEST ≈ 목적지 포트번호 (라우터가 어디로 보낼지)
```

**AXI의 `AxID`와 결정적으로 다름:** AXI `AxID`는 순서 제어용(같은 ID in-order, 다른 ID reorder). AXIS `TID`는 순서 제어가 아니라 **식별 전용**(스트림 내엔 늘 in-order라 순서를 풀고 말고 할 게 없음). AXI ID = "추월 허가증", AXIS TID = "소속 라벨".

### 9-2. 라우팅 — TDEST로 보내고, TID로 되돌린다

```text
              ┌─────────── Stream Switch (인터커넥트) ───────────┐
 src A ─stream─┤ TDEST 보고 라우팅                                │─► dst 0
 src B ─stream─┤ TID 로 출처 보존                                 │─► dst 1
 src C ─stream─┤                                                 │─► dst 2
              └──────────────────────────────────────────────────┘
```

- **Demux (1:N):** 한 입력을 `TDEST` 값에 따라 여러 출력으로 분배.
- **Mux (N:1):** 여러 입력을 합칠 때 각 스트림에 `TID`를 부여/매핑해서 나중에 demux로 되돌릴 수 있게.

### 9-3. interleave 규칙 (같은 TID는 연속, 다른 TID는 섞기 허용)

```text
같은 TID  : 한 packet은 TLAST까지 연속 → 전환은 packet 경계에서만 (beat interleave 금지)
다른 TID  : beat 단위로 섞어도 됨 → sink가 TID로 분리·재조립 (허용)
```

다만 beat interleave는 sink에 TID별 재조립 버퍼가 필요해 비용이 크다 — 그래서 실제 인터커넥트는 보통 **packet 단위로 스위칭**. (interleave가 packet 단위냐 beat 단위냐 → Q&A Q3, in-order vs out-of-order 개념 → Q&A Q4·Q5)

> **한 줄:** `TDEST`=목적지(라우터가 어디로), `TID`=출처/흐름 라벨(섞였을 때 되돌리기). AXI의 `AxID`(순서 제어)와 달리 식별 전용. 멀티스트림은 **TDEST로 demux, TID로 mux 후 복원**, **한 packet은 TLAST까지 연속** 유지가 핵심.

---

## 10. 어디 쓰나 — memory-mapped ↔ stream

```text
비디오:  카메라 ─stream─► [스케일러] ─stream─► [색변환] ─stream─► HDMI
DSP:    ADC ─stream─► [FIR] ─stream─► [FFT] ─stream─► ...
네트워크: MAC ─stream─► [파서] ─stream─► [체크섬] ─► ...
```

핵심 만남: **memory-mapped(AXI) ↔ stream(AXI-Stream) 다리**.

```text
DRAM ◄──AXI(주소 있음)──► [DMA 엔진] ──AXI-Stream(주소 없음)──► [가속기]
                          └ "AXI DMA / Datamover": 카운터로 주소 생성
                            addr = base + (세어둔 데이터 번호)×크기
```

가속기는 주소를 신경 안 쓰고 데이터만 빨아들이고(stream), DRAM은 주소가 필요하다(AXI). DMA가 **순서(스트림) → 주소(메모리)** 변환을 경계에서 한 번 해준다. Unit 2의 AXI와 Unit 3의 AXI-Stream이 실무에서 붙는 지점. (픽셀 → 프레임버퍼 저장 흐름 → Q&A Q1)

---

## 핵심 정리

- **왜 AXI-Stream:** 픽셀·샘플·패킷처럼 주소가 없는 순차 데이터엔 AXI의 주소·5채널·ID·outstanding이 전부 과잉. 데이터 채널 하나만 떼어낸 게 AXI-Stream.
- **설계:** VALID/READY 재사용(데드락-안전 공짜) + byte 지향(폭 변환 단순) + 응답 버림(backpressure만) + 스트리밍 고유 필요만 사이드밴드.
- **AXI와 3대 차이:** 주소→packet(`TLAST`), `AxID`(순서)→`TID`(식별), `WSTRB`→`TKEEP`+`TSTRB`.
- **순서:** 한 스트림(같은 TID/TDEST) 안은 **항상 in-order**. out-of-order는 없다. 다른 TID/TDEST는 "재정렬"이 아니라 "독립"(상대 순서 미정의).
- **필수 신호는 `TVALID`/`TREADY` 둘뿐**, 나머지는 선택. 단순 스트림은 +`TDATA`+`TLAST`.
- **TKEEP/TSTRB:** Data(11)/Position(10)/Null(00). `TKEEP`=버려도 되나, `TSTRB`=값 있나. null(제거 가능) vs position(보존) 구분이 핵심. 검산: `Σ TKEEP의 1 = 패킷 byte 수`.
- **TID/TDEST:** TDEST로 라우팅, TID로 출처 보존. 같은 TID packet은 연속, 다른 TID는 beat interleave 허용(실무는 packet 단위 스위칭).
- **memory-mapped ↔ stream:** DMA가 카운터로 주소를 만들어 두 세계를 잇는다.

---

## 🔌 검증 관점

- **핸드셰이크:** `TVALID` 올린 뒤 핸드셰이크 전 내림/`TDATA` 변경, `TVALID`가 `TREADY` 기다림(데드락), backpressure 중 데이터 유지.
- **TLAST:** packet 길이와 `TLAST` 위치 불일치, `TLAST` 누락(packet 안 끝남)/과다, 연속 스트림인데 엉뚱한 `TLAST`.
- **TKEEP/TSTRB:** 불법 조합(`TKEEP=0,TSTRB=1`), 마지막 transfer null 계산 오류, `N mod W==0`인데 null 넣음, `Σ TKEEP = N` 검산 실패, sparse position byte 오용.
- **폭 변환:** 32→64bit 등에서 byte 재포장 시 null/position 보존, packet 경계(`TLAST`) 보존.
- **TID/TDEST 라우팅:** 잘못된 `TDEST`로 오라우팅, mux 후 `TID` 복원 실패, packet 중간에 다른 packet beat 끼어듦(연속성 위반), `TID/TDEST`가 packet 도중 바뀜.
- **공통:** reset 직후 첫 transfer, 데이터 없는 스트림(`TDATA` 생략) 거동, 선택 신호 생략 시 기본값 처리.

---

→ 이 단원을 보며 나온 모든 세부 질문과 답은 **`amba-unit3-qa.md`** 참고.
