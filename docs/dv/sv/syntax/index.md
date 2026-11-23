# 문법 & 데이터 타입

> SystemVerilog에서 자주 헷갈리는 **문법·데이터 타입 단위의 실무 메모** — 비트 벡터를 안전하게 자르는 indexed part-select, 변수 수명을 정하는 `static` / `automatic`, 신호 타입 `wire` / `reg` / `logic`.

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [인덱스 부분 선택 (`+:` / `-:`)](indexed-part-select.md) | 시작 비트 + 고정 폭으로 연속 비트를 잘라내는 `[start +: width]` |
| [static / automatic (변수 lifetime)](static-automatic.md) | 변수 메모리 수명과 `fork` 안 변수 캡처 함정 |
| [wire / reg / logic (net vs variable)](net-variable.md) | 전선 vs 그릇, `logic`의 단일 드라이버 규칙, tri-state / `inout` |
| [modport](modport.md) | interface 신호의 방향을 역할(master / slave)별로 지정, 방향 실수를 컴파일에서 차단 |
| [packed / unpacked (struct & 배열)](packed-unpacked.md) | 한 줄 비트 벡터 vs 따로 보관, 차원 순서와 `$size` / `$bits` |
| [typedef로 queue / 배열 타입 선언](typedef-array.md) | 변수 선언의 이름 자리에 타입명, 함수 리턴·대입·중첩에서의 활용 |
| [function / task 인자 전달 (원본 vs 복사본)](argument-passing.md) | `input` / `ref` / `output` / `inout` 방향과 타입별(값 vs class handle) 원본 적용 여부 |
