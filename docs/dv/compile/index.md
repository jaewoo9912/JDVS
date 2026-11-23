# 컴파일 & 시뮬레이션

> 시뮬레이션 전후로 쓰는 **컴파일 옵션**과 **정적 검사(lint)** 정리.

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [+incdir+](incdir.md) | `` `include``할 파일이 있는 디렉토리를 알려주는 옵션 (interface 같은 src 파일은 해당 없음) |
| [`include / import / export](include-import.md) | 복붙(`` `include``) vs 이름 빌려 쓰기(`import`), import 범위 규칙과 `export`, include guard |
| [RTL lint](lint.md) | 시뮬레이션 전 RTL을 정적으로 검사해 latch·multiple driver 등 위험한 코딩을 찾는 작업 |
