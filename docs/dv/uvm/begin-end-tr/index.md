# Transaction Recording — `begin_tr` / `end_tr`

> 여러 신호에 흩어진 한 트랜잭션을 **시작~끝 경계를 가진 "막대(bar)" 하나**로 파형에 묶어 그려주는 UVM 기능.

여러 신호에 흩어진 트랜잭션을 파형에 "막대"로 묶는 recording 기능을 단원별로 정리한다.

## 단원

- [개요 — recording이란 / Before·After / 규칙](overview.md)
- [`begin_tr`는 누구 것인가 — 상속 관계](inheritance.md)
- [어디서 호출하는가 — driver vs monitor](driver-monitor.md)
- [`accept_tr`와 트랜잭션 3단계 생명주기](accept-tr.md)
