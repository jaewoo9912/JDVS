# `accept_tr`와 트랜잭션 3단계 생명주기

## 3단계 생명주기

```text
accept_tr        begin_tr              end_tr
   │                │                    │
   ▼                ▼                    ▼
 [접수] ────대기──── [처리 시작] ──처리── [처리 끝]
```

| 단계 | 메서드 | 의미 | AXI read 예 |
|---|---|---|---|
| 1. 접수 | `accept_tr()` | 요청을 받았다 / 큐에 들어왔다 | AR 핸드셰이크 |
| 2. 시작 | `begin_tr()` | 실제로 일을 시작한다 | 첫 R 데이터 beat |
| 3. 끝 | `end_tr()` | 일이 끝났다 | RLAST |

- `accept`~`begin` = **대기 시간**(latency), `begin`~`end` = **처리 시간**
- 비유: 식당 — 주문 접수(accept) → 조리 시작(begin) → 완성(end). 접수~조리 사이가 대기.

## 호출 위치/기준은 전부 user가 정한다

UVM은 "빈 영수증 양식과 도장"만 준다. 언제 무슨 도장을 찍을지는 TB 작성자가 코드로 정한다. 자동으로 신호에서 찍어주지 않는다.

지켜야 할 룰 2가지:

```text
1. 시각 순서:   accept_tr ≤ begin_tr ≤ end_tr
2. begin/end는 짝:  begin_tr 했으면 반드시 end_tr (안 닫으면 막대가 끝까지 늘어짐)
```

## AXI에서 accept 기준 — 보통 핸드셰이크

AXI는 `valid && ready`가 둘 다 1일 때만 정보 전달이 "실제로" 일어난다. 그래서 기본 권장은 **핸드셰이크 기준**.

| 시점 | 의미 | 사용 |
|---|---|---|
| `arvalid && arready` | 실제로 접수/전송됨 | **기본 (권장)** |
| `arvalid == 1` | 요청 올려놓고 ready 기다리는 중 | AR backpressure latency를 따로 볼 때만 |

> 헷갈리면 accept·begin·end 전부 핸드셰이크(`valid && ready`) 엣지 기준으로 찍는 게 가장 안전.

## 파형에서 어떻게 보이나

- 눈에 보이는 **막대(bar)** = `begin_tr`~`end_tr` 구간뿐.
- `accept_tr` 시각은 막대 **속성(`accept_time` 필드)** 으로만 저장됨 → 막대 클릭 시 값으로 확인. 길이로는 안 그려짐.
- 대기를 *막대로* 보고 싶으면 user가 추가 작업: 막대 2개로 분리하거나 `begin_child_tr`로 중첩.

```text
 rdma_read   ─────▓▓▓▓▓▓▓▓▓▓▓──────   ← 막대 = begin~end
 [클릭 시]
   accept_time : 1000 ns   ← 필드로만 보임
   begin_time  : 1300 ns
   end_time    : 1500 ns
```

## `begin_tr` 위치만 옮기면 안 되나? — accept_tr가 존재하는 이유

`begin_tr` 하나는 **시각 1개**만 찍는다. 위치를 옮기면 "접수 시각"과 "처리 시작 시각" 중 **하나만** 갖고 다른 하나는 버린다.

`accept_tr`는 **같은 트랜잭션에 시각 슬롯을 하나 더** 달아준다 → 막대는 처리 구간(begin~end)으로 깔끔히 두면서 **접수 시각도 동시에 보존**. 이건 begin_tr 위치 조정으로 대체 불가.

존재 이유 3가지:

1. **시각 슬롯 추가** — 접수 시각을 막대를 안 건드리고 보존
2. **`accept_event` 발생** — 다른 컴포넌트가 "접수됨" 순간에 동기화(`wait`) 가능 (begin_event와 별개)
3. **의미 명확** — 코드에서 접수/처리시작 의도가 드러남

> 실무: 대기 latency가 검증 포인트가 아니면 accept_tr는 거의 안 쓴다. begin/end만으로 충분한 경우가 대부분이고, accept_tr는 옵션 도구다.
