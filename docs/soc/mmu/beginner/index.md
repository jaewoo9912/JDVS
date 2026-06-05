# 초보 (Beginner)

MMU의 기초 — 왜 필요한지부터 페이지 테이블·TLB·보호/무효화까지 단원별로 정리한다.

## 단원

- [Unit 1 — 왜 MMU가 필요한가? (Why MMU?)](unit1-why-mmu.md) — 가상메모리의 동기, 호텔 프런트 비유, 메모리 계층
- [Unit 2 — 페이지와 페이지 테이블](unit2-page-table.md) — VPN/offset 분리, 변환 공식, huge page 트레이드오프
- [Unit 3 — 다단계 페이지 테이블 & PTW](unit3-multilevel-ptw.md) — sparse 절약, page table walk, 메모리↔속도 트레이드오프
- [Unit 4 — TLB (변환 캐시)](unit4-tlb.md) — 지역성, hit/miss 흐름, hit rate가 성능을 좌우하는 이유
- [Unit 5 — 보호와 무효화](unit5-protection-invalidation.md) — 권한 비트, fault, TLB 무효화 (단일 vs Generation ID)
