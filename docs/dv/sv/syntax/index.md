# 문법 & 데이터 타입

> SystemVerilog에서 자주 헷갈리는 **문법·데이터 타입 단위의 실무 메모** — 비트 벡터를 안전하게 자르는 indexed part-select, 변수 수명을 정하는 `static` / `automatic`, 신호 타입 `wire` / `reg` / `logic`.

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [인덱스 부분 선택 (`+:` / `-:`)](indexed-part-select.md) | 시작 비트 + 고정 폭으로 연속 비트를 잘라내는 `[start +: width]` |
| [static / automatic (변수 lifetime)](static-automatic.md) | 변수 메모리 수명과 `fork` 안 변수 캡처 함정 |
| [wire / reg / logic (net vs variable)](net-variable.md) | 전선 vs 그릇, `logic`의 단일 드라이버 규칙, tri-state / `inout` |
