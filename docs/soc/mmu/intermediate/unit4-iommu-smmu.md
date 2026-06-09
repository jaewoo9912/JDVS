# [심화 Unit 4] IOMMU & SMMU — 장치에도 MMU를

> 핵심 질문: NIC·GPU 같은 장치에 왜 주소 변환이 필요하고, CPU MMU와 무엇이 다른가?

## 왜 필요한가

장치(NIC/GPU/NVMe)도 DMA로 메모리를 직접 만진다. 변환·검사가 없으면 버그/악성 장치가 커널·타 프로세스 메모리를 덮어쓸 수 있다. → 장치 DMA를 변환·격리하는 "장치용 MMU"가 필요하다.

## 1. IOMMU란

> **IOMMU(I/O MMU) = 장치의 DMA 주소(IOVA)를 실제 물리주소(PA)로 변환하고, 매핑에 없는 접근을 차단하는 "장치용 MMU".** ARM에선 **SMMU**(System MMU).

- **IOVA (I/O Virtual Address)** = 장치가 보는 가상주소 (CPU의 VA에 대응).
- CPU MMU가 CPU 접근을 변환하듯, IOMMU는 **장치 DMA**를 변환·보호.

## 2. 변환기는 "접근을 시작한 주체"로 갈린다

| 접근 주체 | 사용 주소 | 거치는 변환기 |
|---|---|---|
| **CPU** (명령 실행, load/store, MMIO) | VA | **CPU MMU** (항상) |
| **장치** (NIC/GPU/NVMe의 DMA) | IOVA 또는 PA | **IOMMU** (있을 때만) |

- **CPU MMU**: CPU가 메모리를 만지는 매 순간 동작 (IOMMU 유무와 무관, 항상 on).
- **IOMMU**: 장치가 DMA할 때만 동작.
- 기준: **"접근을 *시작한* 게 장치면 IOMMU, CPU면 CPU MMU."** (CPU가 장치 레지스터를 MMIO로 건드리는 건 CPU가 시작 → CPU MMU)

## 3. 위치가 다르다

```text
[CPU MMU]  CPU core ─VA─► MMU/TLB ─PA─► 메모리      (코어 안, 코어마다 1개)
[IOMMU]    장치 ─IOVA─► [메모리 길목] IOMMU/IOTLB ─PA─► 메모리  (코어 밖, 시스템에 1개)
```

IOMMU는 모든 장치 DMA가 모이는 길목(PCIe root complex 근처)에 있어, 먼저 **"이 DMA가 어느 장치에서 왔나"**를 알아야 한다 → CPU MMU에 없는 단계.

## 4. ★ CPU MMU vs IOMMU 차이

| 항목 | CPU MMU | IOMMU |
|---|---|---|
| 변환 대상 | 프로세스의 VA | 장치의 IOVA |
| 누구를 구분? | ASID(프로세스) | **StreamID/BDF(장치)** → PASID(장치 내 프로세스) |
| 위치 | 코어 안 | root complex 길목, 코어 밖 |
| 변환 캐시 | TLB | **IOTLB** (+ 장치 쪽 캐시 **ATC**) |
| miss 시 멈추는 것 | CPU 파이프라인 (수 사이클도 치명적) | DMA 트랜잭션 (비동기, 상대적 관대) |
| 1차 목적 | 속도·가상 메모리 | **격리/보호** (속도는 2순위) |
| fault 처리 | CPU exception → OS 즉시 처리·재실행 | 옛날엔 차단(abort), 요즘은 **PRI**로 OS에 요청 |

변환 *알고리즘*(트리 walk)은 거의 같음. 본질 차이는 **입력이 (장치ID, 주소) 쌍**이라는 것.

## 5. 장치 식별 — IOMMU만의 앞단계

```text
DMA 도착 (StreamID 첨부)
   ├─ StreamID로 Stream Table 조회 → STE(Stream Table Entry) 획득
   │     STE = "이 장치의 stage1 테이블=?, stage2 테이블=?, PASID 쓰나?"
   ├─ (PASID 있으면) PASID로 장치 안 특정 프로세스의 stage1 선택
   └─ IOVA를 그 테이블들로 변환 → PA  (권한 없으면 ABORT)
```

- PCIe: **BDF(Bus/Device/Function)** / ARM: **StreamID**로 장치 식별.
- StreamID는 단순 비교 태그라기보다 **"어느 page table을 쓸지 고르는 키"**.

## 6. 식별자 대응표 (CPU MMU vs IOMMU)

| 역할 | CPU MMU | IOMMU |
|---|---|---|
| **장치 식별** | (없음 — 코어가 곧 자신) | **StreamID / BDF** |
| **프로세스 식별** | **ASID** | **PASID** / SubstreamID |
| **VM 식별** | **VMID** | **VMID** |
| **주소** | VA | IOVA |

→ IOTLB 태그 ≈ `(StreamID, VMID, PASID, IOVA) → PA`. CPU의 `(VMID, ASID, VA)`보다 **StreamID 한 겹 더**.
**왜 추가?** CPU MMU는 전용(주인 한 명, 자명). IOMMU는 공용 길목(여러 장치)이라 "누가 보냈나"부터 확인해야 함.
PASID는 선택적 — 한 장치를 여러 프로세스가 공유(SVA)할 때만. PASID ↔ CPU의 ASID 대응.

## 7. 2단계 변환 (가상화 + 장치 passthrough)

```text
장치 IOVA ─(Stage 1: 게스트 소유)─► IPA ─(Stage 2: 하이퍼바이저 소유)─► PA
```

- **Stage 1 (IOVA→IPA)**: 게스트 OS가 장치에 준 매핑. (신뢰 불가)
- **Stage 2 (IPA→PA)**: 하이퍼바이저가 그 VM에 허용한 PA로만 가둠. **최종 방어선.**
- 게스트가 stage1을 어떻게 조작해도 stage2가 다른 VM 메모리 접근을 차단 → "게스트 불신" 모델.
- 모드: 비가상화=stage1만(IOVA→PA), VM passthrough=stage1+stage2.
- stage2 테이블은 **CPU MMU와 IOMMU가 공유 가능** (이 VM에 허용된 물리영역은 동일).

## 8. 성능 — IOTLB + ATS/ATC + PRI

- **IOTLB**: IOMMU 안의 TLB. IOVA→PA(최종 결과) 캐싱.
- **ATS (Address Translation Services)**: 장치가 자기 안에 변환 캐시(**ATC**)를 두게 하는 PCIe 기능. IOMMU 왕복 절감.
- **PRI (Page Request Interface)**: 장치발 "이 페이지 올려줘" 요청 = CPU page fault의 장치 버전. demand paging 가능.
- 함정: 매핑이 바뀌면 IOTLB뿐 아니라 **장치 안 ATC, CPU TLB**까지 무효화해야 함 → Unit 5 주제.

## 핵심 takeaway

- IOMMU = 장치용 MMU. IOVA→PA 변환 + 매핑 없는 접근 차단.
- CPU MMU와 알고리즘 동일, 차이는 **입력이 (장치ID, 주소)**, 위치는 코어 밖 길목, 1차 목적은 **격리**.
- 장치 식별(StreamID/BDF) → Stream Table에서 그 장치의 변환 설정 선택.
- 2단계: Stage1=게스트, Stage2=하이퍼바이저(최종 방어선). VM에 장치 직접 줘도 격리 유지.
- **Golden rule:** IOMMU = CPU MMU + "이 트랜잭션 누가 보냈어?(StreamID)" + "모르는 놈은 차단(격리 우선)".

---

## 📎 부록 — 이 단원에서 나온 질문들

### Q1. 일반 시스템에서 CPU MMU / IOMMU는 각각 언제 접근돼? IOMMU가 없으면 장치는 PA로 직접 접근하는 건가?

변환기는 "접근을 *시작한* 주체"로 갈린다. **CPU 접근 → CPU MMU(항상), 장치 DMA → IOMMU(있을 때만).**

- IOMMU **있음**: 드라이버가 IOMMU에 매핑 등록 → 장치는 IOVA로 DMA → IOMMU가 PA로 변환(매핑 없으면 ABORT). 장치가 정해진 PA만 접근 = 격리.
- IOMMU **없음**: 드라이버가 버퍼의 진짜 PA를 장치에 직접 줌 → **장치가 PA로 직통**(변환·검사 없음). 직관대로 맞음. 버그/악성 장치가 커널·타 프로세스 메모리를 덮어쓸 수 있어 위험.
- 주의: CPU가 장치 레지스터를 MMIO로 건드리는 건 **CPU가 시작**한 접근이라 CPU MMU를 거침.

### Q2. stage1/stage2를 더 설명해줘

Stage = 서로 다른 주인이 소유한 독립 변환 단계.

- **Stage 1 (IOVA/VA→IPA)**: 게스트 OS 소유. 자기 메모리 안에서의 배치 관리.
- **Stage 2 (IPA→PA)**: 하이퍼바이저 소유. 각 VM을 다른 PA에 가두고 격리.
- 모드: ① 비가상화=stage1만 ② VM passthrough=stage1+stage2 ③ stage2만.
- stage2가 최종 방어선(게스트가 stage1 조작해도 막음). CPU 2단계와 구조 대칭, stage2 테이블 공유 가능. 대가는 중첩 walk로 변환 비용 폭발.

### Q3. IPA가 게스트가 바라보는 주소야? (instruction physical address인가?) 2단계가 왜 필요해?

IPA = **Intermediate Physical Address(중간 물리주소)**, instruction 아님. **게스트가 "이게 물리다"라고 믿는 가짜 주소**가 맞다. 2단계가 필요한 이유: 게스트 OS는 이미 자기 변환(stage1, VA→IPA)을 하고 있고 그걸 못 뺏는다 → 그 밑에 하이퍼바이저가 stage2(IPA→PA)를 몰래 끼워, **게스트엔 "진짜 컴퓨터" 환상을 주면서 진짜 메모리는 하이퍼바이저가 통제**하기 위해.

### Q4. CPU MMU에서 VA→PA 한 번만 한 건, 게스트 없이 OS만 있을 때 가정한 거야?

맞다. **1단계(VA→PA) = 가상화 없음**(OS가 하드웨어 위에서 직접, 자기 프로세스 변환). **2단계(VA→IPA→PA) = 게스트 VM 안.** (용어 주의: "host OS"는 Type 2 하이퍼바이저 밑 OS 전용어. 가상화 없는 경우는 그냥 "OS".)

### Q5. virtual address를 쓰는 것 자체가 가상화 아니야?

아니다 — **"virtual"이 완전히 다른 두 가지를 가리키는데 이름이 같아서** 생기는 흔한 오해다. ("virtual" = 그냥 "진짜가 아닌, 추상화된"이라는 형용사 → 서로 무관한 두 명사에 다 붙음: "virtual *address*" vs "virtual *machine*".)

**① 가상 메모리 (Virtual Memory) — "주소"의 추상화**

- **무엇:** 프로세스마다 독립된 가짜 주소 공간(VA)을 주고, MMU/페이징으로 VA→PA 변환.
- **목적:**
    - **프로세스 격리** — 프로세스끼리 서로의 메모리를 못 봄(각자 다른 주소공간).
    - **물리보다 큰 주소공간** — 실제 RAM보다 큰 메모리를 swap으로 흉내.
    - **위치 독립성(relocation)** — 프로그램을 RAM 어디에 적재하든 항상 같은 VA로 보임 → 링킹/로딩 단순화.
    - **메모리 보호** — 페이지별 읽기/쓰기/실행 권한 강제.
- **누가/언제:** **모든 평범한 OS가 항상** 사용 (PC·폰 포함). VM이 0개여도 씀. 1960년대부터 존재.

**② 가상화 (Virtualization) — "컴퓨터(머신)"의 추상화**

- **무엇:** 하이퍼바이저가 하드웨어 하나를 여러 개의 가짜 컴퓨터(VM)로 쪼개, 각 VM에서 OS(게스트)를 통째로 돌림.
- **목적:**
    - **서버 통합(consolidation)** — 물리 서버 1대에 여러 OS를 올려 자원 활용↑.
    - **테넌트 격리** — 한 VM의 장애·침해가 다른 VM에 안 번지게(클라우드 멀티테넌시).
    - **스냅샷/라이브 마이그레이션** — VM을 통째 저장·복구·다른 서버로 이동.
    - **이기종 OS 동시 실행** — 한 머신에서 리눅스·윈도우 동시에.
- **누가/언제:** **하이퍼바이저가 있을 때만.** 특수 상황(클라우드·서버·테스트 환경).

**핵심 — 둘은 독립적이고, VA를 쓴다고 가상화가 아니다:**

| | 가상 메모리 | 가상화 |
|---|---|---|
| 추상화 대상 | 주소 (VA) | 컴퓨터 전체 (VM) |
| 필요한 것 | MMU | 하이퍼바이저 |
| 사용 시점 | 항상 (모든 OS) | VM 띄울 때만 |

→ **지금 쓰는 PC가 증거: VA(가상 메모리)는 쓰지만 VM(가상화)은 없음.**

**우리 1단계/2단계에 매핑:**

```text
가상화 없음 (OS 하나만 메모리 접근, VM 0개):  VA ─► PA           (1단계, VA 사용 O / 가상화 X)
가상화 있음 (게스트 VM 안):                    VA ─► IPA ─► PA     (2단계, VA 사용 O / 가상화 O)
```

- **VA→PA (1단계)** = **하나의 OS가 (게스트/하이퍼바이저 층 없이) 직접 메모리에 접근하는 경우.** OS가 곧 물리 메모리의 유일한 주인이라 중간(IPA)이 필요 없음.
- **VA→IPA→PA (2단계)** = 게스트 VM 안. 위에 하이퍼바이저가 한 겹 더 있어 IPA가 끼어듦.

1단계라고 가상 메모리를 안 쓰는 게 아니다 — VA는 늘 있다. **가상화(VM)가 얹힐 때만** IPA가 끼어 stage가 하나 더 늘 뿐.

### Q6. 가상화에선 왜 2단계가 필요해?

1단계로 충분했던 건 물리 메모리 주인이 OS 하나였기 때문. 가상화하면 **여러 게스트가 다 "내가 주인"이라 믿음** → 충돌·격리 문제. 게스트의 stage1(VA→IPA)은 못 뺏으니 **그 밑에 하이퍼바이저의 stage2(IPA→PA)를 추가**. 근본 이유: **변환을 통제할 독립적 주인이 둘(게스트·하이퍼바이저)이라 각자 한 단계씩.** (한 단계로 하이퍼바이저가 직접 VA→PA 하면 shadow page table 추적 지옥 + 게스트는 어차피 자기 변환 필요.)

### Q7. 가상화에선 VA→IPA→PA / IOVA→…→PA 둘 다 MMU가 변환해? TLB가 2단계를 알아?

- **둘 다 HW가 함**: CPU MMU가 VA→IPA→PA, IOMMU가 IOVA→IPA→PA를 각각 자동 walk.
- **"IOIPA/IOPA"는 없다**: 중간(IPA)·끝(PA)은 CPU와 **공유하는 같은 것**, 입구 이름만 VA/IOVA로 다름. 진짜 물리 메모리는 하나.
- **TLB는 2단계를 모름** — **(VMID,ASID,VA)→PA 최종 결과만** 캐싱. hit이면 IPA·stage들 건너뛰고 곧장 PA. 2단계 walk는 **miss일 때 PTW가** 수행. → 비싼 2단계를 첫 한 번만 치르고 TLB가 지름길로 숨김.

### Q8. IOMMU는 ASID, VMID + StreamID까지 비교하는 거야?

맞다 — IOMMU는 식별자가 더 많다. **StreamID(장치) = CPU엔 없는 추가**, PASID(장치 내 프로세스) ↔ ASID 대응, VMID는 동일. IOTLB 태그 ≈ (StreamID, VMID, PASID, IOVA). StreamID가 추가되는 이유: IOMMU는 여러 장치를 공유하는 길목에 있어 "누가 보낸 DMA냐"부터 식별해야 하므로.

### Q9. 그 VMID도 가상화 환경에서만 쓰는 거였구나?

맞다. **VMID·IPA·stage2는 가상화일 때만 등장하는 3종 세트.** ASID/StreamID는 가상화 유무와 무관하게 항상(프로세스·장치 구분). VMID는 VM을 구분하니 가상화에서만. 즉 가상화 = 기존 구조 위에 VMID·IPA·stage2를 한 겹 더 얹는 것.
