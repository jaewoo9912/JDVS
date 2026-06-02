# Page Table Structure (페이지 테이블 구조)

> **한 줄 요약**: 한 프로세스의 전체 VA 공간을 단일 표로 만들면 512GB가 필요하다. 이를 **다단계(L0~L3) 트리**로 쪼개 **쓰는 가지만 할당**하면 같은 공간을 1~10MB로 커버한다.

---

## 1. 문제 정의 — 왜 다단계인가

| 방식 | 비용 |
|---|---|
| **단일 평면 테이블** | 48-bit VA, 4KB 페이지 → 36-bit 인덱스 → 2³⁶ × 8B = **512 GB / 프로세스** ❌ |
| **다단계 테이블** | 4레벨 × 9-bit 인덱스 + 12-bit offset = 48-bit. 각 표 = 512칸 × 8B = 정확히 **4KB(한 페이지)** |

!!! tip "핵심 이득"
    안 쓰는 가지(branch)는 sub-table을 아예 할당 안 함(sparse allocation).
    → 일반 프로세스는 **256TB VA 공간 전체를 1~10MB page table**로 커버.

---

## 2. "표(table)"의 정체

표 = 메모리에 놓인 **512칸짜리 배열**일 뿐이다.

```text
물리 메모리 0x9000부터 시작하는 표:
주소      칸      내용(8byte = 64bit)
0x9000  [0]      ...
0x9008  [1]      ...          ← 8byte씩 떨어져 있음
0x9010  [2]      0x...A003    ← "다음 표 = 0xA000" + 속성비트
  ...
0x9FF8  [511]    ...
```

- 칸 하나 = **8byte(64bit)** → `칸번호 × 8`이 주소 오프셋
- 칸 512개 × 8byte = **4096byte = 4KB = 한 페이지**
- 각 칸엔 **다음 표 주소** 또는 **최종 물리주소** + 권한·속성

!!! note "왜 64비트(8byte)인가"
    물리 페이지 번호(PPN, 36bit)만 담는 게 아니라 V·AP·AF·NS·Type 등 **권한·속성까지** 욱여넣어야 해서 32bit(4byte)로는 부족하다.

---

## 3. 직관 — 도서관 색인 비유

다단계 page table ≈ 계층형 도서관 분류 체계:

- **L0** (최상위) → 큰 분류 (층)
- **L1** → 세부 분류 (코너)
- **L2** → 책장
- **L3** (leaf) → 정확한 책 위치 (4KB 페이지)

안 쓰는 가지는 아무것도 할당하지 않고, **Huge page(block descriptor)**는 중간에서 일찍 끝내 여러 4KB를 한 큰 매핑으로 반환한다.

---

## 4. 레벨별 커버리지 — 위로 갈수록 넓다

한 칸 내려갈 때마다 담당 크기가 **÷512** 된다 (레벨당 9비트 = 2⁹ = 512).

| 레벨 | 한 칸 담당 | 계산 |
|---|---|---|
| **L0** | **512 GB** | 2³⁹ (= 1GB × 512) |
| L1 | 1 GB | 2³⁰ (= 2MB × 512) |
| L2 | 2 MB | 2²¹ (= 4KB × 512) |
| L3 | 4 KB | 2¹² (= 페이지 1개) |

> **검산**: L0칸 512개 × 512GB = **256TB = 2⁴⁸** = 전체 VA 공간 ✅

---

## 5. 비트 분해 (ARMv8 4KB granule)

```text
 63    48 47   39 38   30 29   21 20   12 11       0
+--------+-------+-------+-------+-------+----------+
| Sign   |  L0   |  L1   |  L2   |  L3   |  Offset  |
| Ext    | Index | Index | Index | Index | (12-bit) |
|(16bit) |(9bit) |(9bit) |(9bit) |(9bit) |          |
+--------+-------+-------+-------+-------+----------+
    ↓        ↓        ↓        ↓        ↓
TTBR0/1   Level0   Level1   Level2   Level3
```

!!! info "왜 레벨이 4개인가"
    레벨 수 = (VA비트 − offset) ÷ 레벨당비트 = **(48 − 12) ÷ 9 = 4**.
    값을 바꾸면 레벨도 바뀐다 → Sv39(39bit)=3레벨, x86 LA57(57bit)=5레벨, ARM 64KB granule=3레벨.
    4에서 멈추는 이유: 256TB면 충분하고, 레벨 1개 = 메모리 접근 1회 추가(~100ns).

---

## 6. 구체 예시 — VA 변환 따라가기

**시나리오**: VA `0xFFFF_0000_0040_0ABC`, ARMv8 EL1, 4KB granule, ASID=1, `TTBR1_EL1 = 0x..0009_0000_0000`

| 필드 | 비트 | 값 | 용도 |
|---|---|---|---|
| Sign-ext | [63:48] | 0xFFFF | bit63=1 → **TTBR1** 사용 |
| L0 index | [47:39] | 0x000 | |
| L1 index | [38:30] | 0x000 | |
| L2 index | [29:21] | 0x002 | |
| L3 index | [20:12] | 0x000 | |
| Offset | [11:0] | 0xABC | (변환 안 됨) |

```text
1. L0 read: 0x..0009_0000_0000 + 0×8
   PTE → [1:0]=0b11(Table) → 다음 표 0x..0009_1000_0000
2. L1 read: + 0×8
   PTE → 0b11(Table) → 다음 표 0x..0009_2000_0000
3. L2 read: + 2×8 = 0x..0009_2000_0010
   PTE = 0x0040_0000_0080_0741 → [1:0]=0b01 (Block!)
   → Walk 종료 (2MB block)
4. PA 합성: OutputAddr[47:21] || VA[20:0] = 0x0000_0000_0040_0ABC
5. TLB fill: ASID=1, VPN, PPN, size=2MB
```

!!! note "핵심 관찰"
    - L2 Block(0b01) → walk가 일찍 끝나 **메모리 접근 4회 → 3회**
    - L1 PTE가 V=0이면 → Translation Fault Level 1 → OS demand paging

---

## 7. Descriptor 종류 & Block(Huge Page)

각 PTE의 하위 2비트(`[1:0]`)가 종류를 결정:

| Descriptor | 값 | 커버리지 | Walk 깊이 |
|---|---|---|---|
| Table (L0~L3) | 0b11 | 다음 레벨로 | 풀 깊이 |
| Block at L1 | 0b01 | 1 GB | **3회** |
| Block at L2 | 0b01 | 2 MB | **3회** |
| Page at L3 | 0b11 | 4 KB | **4회** |
| Invalid | 0b00 | — | Page Fault |

**용도**: GPU framebuffer(1GB) → L1 Block / 큰 MMIO(2MB) → L2 Block / 세밀한 앱 → L3 Page

---

## 8. PWC (Page Walk Cache) — 중간 레벨 캐싱

이웃한 VA는 상위 레벨 PTE를 공유한다.

```text
VA 0x..1000, VA 0x..2000 → L0·L1·L2 인덱스 동일, L3만 다름
```

→ 중간 레벨 PTE를 캐시하면: L0+L1+L2 hit 시 **4회 → 1회(L3만)**. 순차 워크로드에서 **walk 비용 40~60% 절감**.

!!! warning "DV 주의"
    PWC는 TLBI 시 TLB와 **함께 무효화**돼야 한다. stale PWC + 새 page table = 잘못된 PA.

---

## 9. PTE 주요 필드

| 필드 | 비트 | 의미 |
|---|---|---|
| **V (Valid)** | [0] | entry 유효 |
| **Type** | [1] | 0=Block, 1=Table/Page |
| **AttrIdx** | [4:2] | MAIR 인덱스 (캐시 속성) |
| **NS** | [5] | Non-Secure (TrustZone) |
| **AP** | [7:6] | 접근 권한 (R/W × EL0/EL1) |
| **SH** | [9:8] | Shareability |
| **AF** | [10] | Access Flag (접근됨?) |
| **nG** | [11] | not Global (ASID 적용) |
| **OutputAddr** | [47:12] | 물리 페이지 번호(PPN) |
| **Upper Attrs** | [63:52] | XN, PXN, Contiguous 등 |

**Access Permission (AP) 인코딩:**

| AP[7:6] | EL1 (Kernel) | EL0 (User) |
|---|---|---|
| 00 | RW | No Access |
| 01 | RW | RW |
| 10 | RO | No Access |
| 11 | RO | RO |

!!! note
    AP는 **R/W만** 제어. 실행 권한은 별도(`UXN`/`PXN`).

---

## 10. ASID — 문맥 전환 시 TLB flush 회피

TLB entry에 프로세스 ID를 태깅해 flush 없이 전환:

```text
| ASID | VPN | PPN |
|  5   | 0x1 | 0x8 | ← Process A
|  7   | 0x1 | 0xA | ← Process B
VA 0x1000, ASID=5 → PA 0x8000 / ASID=7 → PA 0xA000 (flush 불필요!)
```

> 주의: ASID는 재활용(8-bit=256, 16-bit=65K). 한계 초과 시 OS가 전역 TLB flush 강제.

---

## 11. ISA 비교 (참고)

| 항목 | ARMv8 | RISC-V (Sv48) | x86-64 |
|---|---|---|---|
| VA 비트 | 48 | 48 | 48 (LA57이면 57) |
| 레벨 | 4 (L0~L3) | 4 (역순) | 4 (PML4→PT) |
| Granule | 4/16/64KB | 4KB | 4KB |
| Entries/table | 512 | 512 | 512 |
| Huge page | 2MB(L2),1GB(L1) | 2MB(L1),1GB(L0) | 2MB(PD),1GB(PDP) |
| Base 레지스터 | TTBR0/1_EL1 | satp | CR3 |

> **면접 포인트**: 구조는 거의 동일, 차이는 용어·인코딩뿐. 검증 방법론은 ISA 간 이전 가능.

---

## 12. 흔한 오해 & DV 디버그 체크리스트

| ❌ Myth | ✅ Reality |
|---|---|
| "Walk = 메모리 read 1회" | 4-level walk = 최대 4회. PWC hit면 1~3, block이면 1레벨 단축 |
| "Block descriptor = huge page" | Block은 **PTE 인코딩**(0b01), huge page는 **OS 정책**(MAP_HUGETLB) |
| "PWC = TLB의 일부" | PWC는 **별도 구조**(중간 PTE 캐시), TLB는 최종 VA→PA |
| "ASID 있으면 flush 영원히 불필요" | ASID 재활용 한계 초과 시 전역 flush |
| "AP=11(RO/RO)이 가장 안전" | AP는 R/W만. 실행은 UXN/PXN 별도. W^X는 **둘 다** 확인 |

| 증상 | 1순위 의심 | 확인 위치 |
|---|---|---|
| Translation Fault 항상 Level 0 | TTBR base가 unmapped | TTBR0/1_EL1이 DRAM에 있나 |
| 2MB walk가 L3에서 끝남 | L2 PTE가 Table(0b11) | L2 PTE[1:0] + OutputAddr[20:0]=0? |
| Block PA가 1MB 어긋남 | PA mask가 [47:20] (정답 [47:21]) | PA 합성 공식 |
| 같은 VA→프로세스별 다른 PA인데 hit | TLB에 ASID 없음 / nG=0 | TLB dump → ASID + PTE.nG |
| AF=0 접근에 fault 2회 | FEAT_HAFDBS 미지원, SW가 AF set 누락 | ID_AA64MMFR1_EL1.HAFDBS + OS AF 코드 |
| Walk 횟수 ≥5 | Stage2 활성 | VTCR_EL2.SL0 + Stage2 enable |

---

## 13. 핵심 정리

1. **다단계는 sparsity를 해결** — 단일=TB 낭비, 다단계=쓰는 가지만 할당
2. **레벨 수 = (VA−offset)÷9** — 표준값에서 4가 나옴
3. **표 = 512칸 × 8byte = 4KB** — 표 자체가 한 페이지에 딱 맞음
4. **위 레벨일수록 넓다** — L0(512GB) → ÷512씩 → L3(4KB)
5. **Block descriptor** — L1/L2 조기 종료 → huge page, walk↓
6. **PWC** — 중간 PTE 캐시, 별도 무효화 정책

---

## 📖 용어 사전 (Glossary)

| 용어 | 풀이 |
|---|---|
| **Page Table** | VA→PA 매핑을 담은 다단계 트리 구조의 표 |
| **PTE** | Page Table Entry. 출력 주소 + 권한·속성 비트를 담은 한 칸(8byte) |
| **Multi-level Page Table** | 단일 평면 표 대신 L0~L3 트리로 나눠 쓰는 가지만 할당 |
| **L0~L3 (Level)** | page table 단계. L0=최상위, L3=leaf(최종 페이지) |
| **Sparse Allocation** | 실제 쓰는 가지만 sub-table을 할당하는 방식 |
| **Granule** | page table 기본 페이지 크기 (4/16/64KB) |
| **Page Walk** | TLB miss 시 page table을 단계별로 순회해 PA를 찾는 과정 |
| **Table Descriptor** | PTE[1:0]=0b11. 다음 레벨 테이블을 가리킴 |
| **Block Descriptor** | PTE[1:0]=0b01. 중간 레벨에서 끝내는 큰 매핑(2MB/1GB) |
| **Page Descriptor** | L3의 PTE. 최종 4KB 페이지 매핑 |
| **Huge Page** | 큰 페이지(2MB/1GB)를 쓰는 **OS 정책** (구현은 block descriptor) |
| **PWC (Page Walk Cache)** | 중간 레벨 PTE(다음 테이블 주소)를 캐시하는 별도 구조 |
| **TLB** | 최종 VA→PA 매핑을 캐시하는 구조 (page table과 별개) |
| **VPN / PPN** | Virtual / Physical Page Number |
| **Output Address** | PTE 안의 물리 페이지 번호(PPN), bits[47:12] |
| **V (Valid) bit** | PTE entry가 유효한지 표시 |
| **AF (Access Flag)** | 페이지가 한 번이라도 접근됐는지 표시 (0이면 fault) |
| **AP[7:6]** | Access Permission. R/W × EL0/EL1 권한 조합 |
| **UXN / PXN** | User/Privileged Execute Never. 실행 금지 비트 (AP와 별개) |
| **NS bit** | Non-Secure 비트 (TrustZone), PTE[5] |
| **SH (Shareability)** | Inner/Outer/Non — 캐시 일관성 도메인 범위 |
| **nG (not Global)** | 1이면 ASID가 적용되는 프로세스 전용 매핑 |
| **AttrIdx / MAIR** | 캐시 속성 slot 인덱스 / 속성 정의 레지스터 |
| **Contiguous bit** | PTE[52]. 연속 16개 4KB 페이지를 TLB 1 entry로 결합 |
| **ASID** | Address Space ID. 프로세스 구분 태그. flush 없이 문맥 전환 |
| **VMID** | Virtual Machine ID. VM 구분 태그 (가상화 2단계 변환) |
| **Stage 1 / Stage 2** | VA→IPA(OS) / IPA→PA(Hypervisor) 2단계 변환 |
| **COW (Copy-on-Write)** | 공유 페이지에 write 시 그 순간 복사본 생성 |
| **TTBR0/1** | Translation Table Base Register. page table 시작 주소 |
| **satp / CR3** | RISC-V / x86-64의 page table base 레지스터 |
| **TLBI** | TLB Invalidate. 낡은 TLB(및 PWC) entry 무효화 명령 |
| **FEAT_HAFDBS** | HW가 AF/Dirty bit를 auto-set하는 기능 |
| **Internal Fragmentation** | 큰 페이지 할당 시 안 쓰는 내부 공간이 낭비되는 현상 |
| **W^X** | Write XOR eXecute. 쓰기·실행 동시 허용 금지 보안 원칙 |
| **Sv39 / Sv48** | RISC-V의 39/48-bit VA 페이지 테이블 구성 (3/4 레벨) |
| **LA57** | x86-64의 57-bit VA 5-level paging |
