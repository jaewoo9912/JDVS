# [심화 Unit 1] TLB 마이크로아키텍처 & 멀티프로세스 구분

## 왜 필요한가

단순 "VPN→PFN 사전" 모델엔 실무 폭탄 3개: ① 프로세스 전환마다 flush하면 walk 폭풍 ② 페이지 크기 여러 개면 offset 폭이 달라 인덱싱이 깨짐 ③ 하나로 빠르고 크게는 물리적으로 불가.

## 핵심 1 — 멀티레벨 TLB

| | L1 TLB | L2 TLB |
|---|---|---|
| 크기/속도 | 작음 / ~1 사이클 | 큼 / 몇 사이클 |
| 구성 | I-TLB·D-TLB 분리, fully-assoc | 통합(unified), set-assoc |

흐름: L1 miss → L2 확인 → L2도 miss → 그제서야 PTW walk.

### I-TLB / D-TLB

- 명령어(코드)도 데이터도 **둘 다 가상주소** → 둘 다 번역 필요.
- I-TLB=명령어 fetch용, D-TLB=데이터 load/store용. **분리 이유 = 둘이 동시에 일어나서 병렬 처리**(한 포트 경합 회피). L1 캐시를 I/D로 쪼개는 것과 같은 이유.
- IOMMU(장치용)엔 명령어 fetch가 없어 이 분리가 없음 — 전부 데이터(DMA) 번역.

### Page-Walk Cache (PWC) — "폴더 경로 캐시"

- walk = 깊은 폴더(L1/L2/L3/L4)를 타고 내려가 파일(PFN) 찾기.
- 인접 페이지는 상위 폴더(L1/L2/L3)를 공유 → PWC가 "방금 간 폴더 위치"를 기억 → 다음 번역은 마지막 레벨만 읽음 (4단계 → 1~2단계).
- TLB는 "파일 내용(최종 PFN) 캐시", PWC는 "폴더 경로(중간 디렉터리) 캐시". TLB miss 시 walk를 짧게 해주는 2차 방어선.

## 핵심 2 — ASID / VMID (태그로 구분)

- 문제: 프로세스 A의 VPN 0x2 ≠ 프로세스 B의 VPN 0x2 (다른 PA). 태그 없으면 전환마다 flush 필요(느림).
- **ASID (Address Space ID)** = TLB 엔트리에 붙는 "프로세스 이름표". lookup 시 VPN + 현재 ASID 둘 다 일치해야 hit. → 전환 시 flush 없이 현재 ASID만 교체, 엔트리 공존.
- **VMID (Virtual Machine ID)** = 그 위 "VM(회사) 이름표". 엔트리 = [VPN|PFN|권한|ASID|VMID], 두 태그 다 맞아야 hit.
- 한계: 태그 비트 유한(8~16b) → 고갈 시 재활용+해당 엔트리 flush.

## 핵심 3 — 다중 페이지 크기 (4KB/2MB/1GB)

- 문제: 크기마다 offset 폭 다름(12/21/30비트) → set-assoc의 고정 index 비트가 어떤 크기엔 VPN(적합), 다른 크기엔 offset(부적합). 게다가 번역 전엔 크기를 모름(순환 모순).
- 해법: 크기별 분리 TLB / fully-associative(index 없어 크기 무관) / 다중 크기 병렬 probe.

## 캐시 조직: set-assoc vs fully-assoc (주차장 비유)

| | 주차 규칙 | 찾기 | 특징 |
|---|---|---|---|
| Direct-mapped | 번호판=지정 칸 1개 | 1칸 | 빠름, 충돌 잦음 |
| Set-associative | 번호판=지정 구역, 구역 내 자유(K-way) | K칸 | 절충. index 비트 사용 → 페이지 크기 민감 |
| Fully-associative | 어디든 자유 | 전체 N칸 | 유연(충돌 없음), 비쌈 → 작을 때만. index 없어 크기 혼합에 강함 |

→ 작은 L1 TLB는 fully-assoc(혼합 크기 OK), 큰 L2는 set-assoc.

## Huge Page (2MB / 1GB)

- 페이지를 4KB → 2MB/1GB로 키운 것.
- 이득: ① TLB reach 폭증 (엔트리 1개가 거대 영역 커버; 64엔트리 → 4KB:256KB vs 2MB:128MB vs 1GB:64GB) ② walk 단계 단축(1GB는 상위 레벨에서 leaf).
- 대가: 내부 단편화(안 쓰는 큰 공간 낭비) / 권한·swap이 거친 단위 / 큰 연속 물리메모리 필요.
- 큰 버퍼=huge page, 자잘한 데이터=4KB. (우리 RDMA MMU가 1GB/2MB/4KB 지원하는 이유)

## TLB miss 한 번의 비용 사다리

```text
L1 TLB HIT (~1c) > L1 miss·L2 HIT (~수c) > L2 miss+PWC (메모리 1~2읽기)
                                          > L2 miss+cold walk (메모리 4읽기)
                                          > page fault (OS 개입, 초느림)
```

miss 흐름: L1 D-TLB miss → L2 miss → (PWC 단축) PTW walk → 권한 검사 → fill(L2/L1/PWC) → 재시도 HIT.

## 핵심 takeaway

- 실제 TLB = 멀티레벨 + 태그(ASID/VMID) + 다중 페이지 크기 대응.
- set-assoc은 index 비트로 페이지 크기에 민감, fully-assoc은 크기 무관(작을 때만).
- ASID/VMID/Generation ID = 같은 "태그+비교" 메커니즘, 다른 목적(공간 vs 시간).

---

## 📎 부록 — 이 단원에서 나온 질문들

### Q. I-TLB / D-TLB가 뭐고, 데이터도 TLB를 거치나?

- 명령어도 데이터도 둘 다 가상주소라 **둘 다 번역 필요**. I-TLB=명령어 fetch용, D-TLB=데이터 load/store용.
- 분리 이유: 파이프라인에서 fetch와 load/store가 **동시에** 일어나 → 전용 포트로 병렬 처리(경합 회피). 부가로 접근 패턴 차이(명령어=순차, 데이터=산발), 물리적 밀착. L1 캐시 I/D 분리와 같은 이유.
- IOMMU엔 명령어 fetch가 없어 I-TLB 없음 (장치는 데이터 DMA만).

### Q. Page-walk cache(PWC)를 더 쉽게

- walk = 폴더 4단계(L1/L2/L3/L4)를 타고 내려가 파일(PFN) 찾기. 인접 페이지는 상위 폴더 공유.
- PWC = "방금 들어간 폴더 위치"를 기억 → 다음 번역은 마지막 단계만 읽음(4→1~2단계). 탐색기에서 같은 폴더의 다른 파일 열 때 home부터 다시 안 가는 것과 같음.
- TLB(파일 내용 캐시) vs PWC(폴더 경로 캐시). PWC는 TLB miss 시 walk를 단축하는 2차 방어선.

### Q. TLB 거치고 miss 나는 예시 (load [0xDEADB123], 4KB, ASID=7)

1. D-TLB(L1) lookup VPN=0xDEADB,ASID=7 → MISS
2. L2 TLB → MISS
3. PTW walk (PWC 있으면 마지막 레벨만, cold면 4번 읽기)
4. PTE: PFN=0x55000, R=1 → load(읽기) 권한 OK
5. fill: L2/L1 D-TLB ← 엔트리, PWC ← 상위 디렉터리
6. 재시도 → L1 HIT → PA=(0x55000<<12)|0x123=0x55000123 → 데이터 캐시 접근
   이후 같은 페이지(0xDEADB456)는 즉시 HIT (엔트리 1개가 4KB 전체 커버).

### Q. set-associative vs fully-associative 차이 (주차장)

- Direct-mapped: 번호판=지정 칸 1개. 찾기 1번. 충돌 잦음.
- Fully-associative: 어디든 주차, 찾을 때 전체 비교(N번). 유연·충돌없음, 비쌈→작을 때만. index 없어 페이지 크기 혼합 OK.
- Set-associative: 번호판으로 구역 결정, 구역 내 K칸 자유. 찾기 K번. direct·fully의 절충. index 비트 사용 → 페이지 크기에 민감.
- 그래서 작은 L1 TLB는 fully-assoc, 큰 L2는 set-assoc.

### Q. Huge page 개념 (쉽게)

- 페이지를 4KB→2MB/1GB로 키운 것. "큰 박스".
- 이득: TLB reach 폭증(엔트리 1개가 거대 영역 커버) + walk 단축.
- 대가: 내부 단편화(낭비), 거친 권한/swap 단위, 큰 연속 물리메모리 필요.
- 큰 버퍼엔 huge page, 자잘한 데이터엔 4KB.

### Q. ASID, VMID, Generation ID — 목적이 어떻게 다른가?

- **같은 메커니즘**: 셋 다 "엔트리에 태그 붙이고 lookup 때 비교".
- **다른 축**: ASID/VMID = 공간(누구 것이냐) / Generation = 시간(아직 최신이냐).
    - ASID: "어느 프로세스?" → 전환 시 flush 없이 공존 + 프로세스 격리.
    - VMID: "어느 VM?" → VM 간 격리.
    - Generation: "어느 세대?" → 매핑 변경 시 옛 엔트리 대량 무효화(O(1)).
- 위험 시나리오가 다름: ASID 없으면 "다른 프로세스가 내 번역 hit"(공존하는 남), Generation 무효화 안 하면 "같은 프로세스가 자기 옛 번역 hit → 이미 재배정된 메모리 접근"(시간 지난 자기 것).
- 비유: ASID=부서 도장, VMID=회사 도장, Generation=발급연도 도장. [재무] 문서는 HR이 안 읽음(격리), [2024년] 문서는 재무 자신 것이어도 2025 선언 시 무효(무효화).
