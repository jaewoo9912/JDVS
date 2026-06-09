# 중수 (Intermediate)

실제 TLB 마이크로아키텍처와 멀티프로세스/멀티VM 구분 등 한 단계 깊은 주제를 단원별로 정리한다.

## 단원

- [심화 Unit 1 — TLB 마이크로아키텍처 & 멀티프로세스 구분](unit1-tlb-microarch.md) — 멀티레벨 TLB, I/D-TLB, PWC, ASID/VMID, 다중 페이지 크기, set/fully-assoc, huge page
- [심화 Unit 3 — PTW & Walk Cache (miss를 견디는 법)](unit3-ptw-walkcache.md) — 다단계 walk 비용, walk cache, MSHR/latency hiding, huge page trade-off, 가상화·2단계 변환(stage1/stage2·IPA)
- [심화 Unit 4 — IOMMU & SMMU (장치에도 MMU를)](unit4-iommu-smmu.md) — IOVA→PA, 장치 식별(StreamID/BDF), PASID/VMID, IOTLB/ATS/ATC/PRI, 2단계 변환과 장치 passthrough, 가상 메모리 vs 가상화
