# MMU

MMU(Memory Management Unit) — 가상→물리 주소 변환, 권한 체크, 캐시 속성 제어를 단원별로 정리한다.

## 단원

- [1. 기본 개념 및 주소 변환](basics.md) — VA→PA 변환 사이클, translation regime, MMU enable 시퀀스
- [2. Page Table Structure](page-table.md) — 다단계(L0~L3) 트리, descriptor 종류, PWC, PTE 필드
- [3. TLB (Translation Lookaside Buffer)](tlb.md) — 변환 결과 캐시, 계층 구조, TLBI·멀티코어 coherency, 교체 정책
