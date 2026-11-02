# Assertion (SVA)

> "이 조건은 **항상 참이어야 한다**"를 회로 옆 **자동 감시 카메라(CCTV)**처럼 코드로 박아두고, 깨지는 순간 시뮬레이터가 **시각·위치까지 짚어** 알려주는 기능 (SVA — SystemVerilog Assertions).

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [기본 (Immediate vs Concurrent)](basics.md) | 기본 뼈대, Immediate vs Concurrent, `\|->` / `\|=>` 칸 계산 |
| [시퀀스 & 실무 패턴](sequence.md) | `[*]` / `##` / `##0`, `$rose` / `$fell` / `$stable`, 단어장 7개 & 5대 패턴 |
| [property & assert / cover / assume](property.md) | `property` 분리 스타일, 세 지시어 차이, Vacuous Pass, 해석 Q&A |
| [bind & 내부 신호 검증](bind.md) | RTL 수정 없이 DUT 내부(Arbiter / FSM)에 감시 모듈을 꽂는 `bind` |

!!! tip "읽는 순서"
    기본 → 시퀀스 & 패턴 → property 순서로 읽고, DUT 내부 신호를 감시해야 할 때 `bind`를 본다.
