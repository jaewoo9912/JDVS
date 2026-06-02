# TLB (Translation Lookaside Buffer)

> **한 줄 요약**: page walk(~400ns)를 매번 하면 너무 느리다. TLB는 한 번 변환한 (VA→PA + 권한·속성) 결과를 캐시해 **1 cycle**로 줄이는 가속기다. 단 page table과 **별개 저장소**라, page table을 바꾸면 반드시 TLBI로 낡은 entry를 지워야 한다.

---

## 1. 왜 필요한가 — page walk가 느려서

VA→PA 변환은 L0→L1→L2→L3 표를 읽어야 하고(2단원), 4-level이면 메모리를 4번 읽어 **~400ns** 걸린다. 프로그램은 같은 주소를 반복 접근하므로 매번 walk는 낭비다.

→ **TLB = 변환 결과를 저장하는 작은 초고속 하드웨어** (브라우저 북마크 비유).

| | 시간 | 비유 |
|---|---|---|
| **TLB hit** | ~1 cycle (0.5ns) ⚡ | 북마크 클릭 |
| **TLB miss → walk** | ~400ns 🐢 | 검색해서 찾기 |

!!! info "800× 차이"
    TLB가 MMU 성능의 **90%를 결정**한다.

---

## 2. Hit rate가 성능을 지배한다

$$T_{eff} = (\text{Hit율} \times T_{hit}) + (\text{Miss율} \times T_{miss})$$

`T_hit = 0.5ns`, `T_miss = 400ns` 기준:

| Hit rate | 유효 접근시간 | 배율 |
|---|---|---|
| 99% | 4.5 ns | 기준 |
| 95% | 20.5 ns | **4.6×** |
| 90% | 40.5 ns | **9×** |

!!! warning
    단 4%p(99→95) 떨어졌는데 4.6배 폭락. miss 한 번이 400ns씩 잡아먹기 때문. **hit rate 관리가 생명.**

---

## 3. TLB 계층 구조

"빠르려면 작고, 많이 담으려면 커야 하는" 모순을 계층으로 해결.

```text
μTLB(L1) → L2 TLB → PWC → page walk
빠름·작음   크고느림  중간캐시  최후수단
```

| 단계 | 크기 | 속도 | 방식 |
|---|---|---|---|
| **μTLB (L1)** | 32~64칸 | 1 cycle | fully-associative |
| **L2 TLB** | 256~2048칸 | 2~4 cycle | set-associative (4~8 way) |
| **Page Walk Engine** | (메모리 표) | ~400ns | L2 miss 시 호출, 성공하면 L1·L2 둘 다 fill |

!!! note "Split vs Unified / IOTLB"
    - **L1은 split** (I-TLB + D-TLB) → 명령·데이터 동시 조회 가능
    - **L2는 unified** → 활용도 ↑
    - **IOTLB**: IOMMU/SMMU용 별도 TLB. 키 = StreamID(디바이스) + SubstreamID(PASID)

---

## 4. TLB 한 칸의 구조 — PA만 담는 게 아니다

```text
+------+------+------+------+---+---+---+---+------+------+
| VMID | ASID | VPN  | PPN  | V | R | W | X | Attr | Size |
+------+------+------+------+---+---+---+---+------+------+
|  3   |  5   | 0x1F | 0x8A | 1 | 1 | 1 | 0 | WB   | 4KB  |
```

| 필드 | 의미 |
|---|---|
| **VMID / ASID** | 어느 가상머신 / 어느 프로세스 |
| **VPN → PPN** | 가상 → 물리 페이지 번호 |
| **V** | Valid (사용 가능) |
| **R/W/X** | 권한 (page table에서 복사해온 것) |
| **Attr** | 캐시 정책 (WB = write-back) |
| **Size** | 페이지 granule (4KB/2MB/1GB) |

!!! danger "이게 핵심"
    TLB는 **권한·속성까지 통째로 캐시**한다. 그래서 page table에서 권한만 바꿔도 TLBI를 안 하면 **옛날 권한이 그대로 살아있어** silent 위반이 생긴다.

**Lookup 과정**: VA에서 VPN 추출 → `VMID + ASID + VPN(size-aware mask) + V=1` 모두 일치하는 칸 검색 → hit이면 PPN+권한+속성 반환(~1cycle), miss면 Page Walk Engine 호출.

---

## 5. ⚠️  Stale Entry = 보안 구멍

TLB는 page table의 **사본**이므로, 원본을 바꿔도 사본은 안 바뀐다.

!!! danger "조용한 데이터 오염 시나리오"
    ```text
    1. OS가 메모리를 unmap (munmap)
    2. 같은 VA를 다른 물리 메모리에 remap
    3. TLB엔 옛날 매핑이 그대로 남음  ← TLBI 누락!
    4. 프로세스가 옛날 PA를 읽음 → 경고 없이 데이터 오염 💥
    ```
    남의 메모리를 읽을 수 있어 **보안 취약점**. → page table 변경 시 반드시 TLB 무효화.

---

## 6. TLB 무효화 (TLBI) — 선택적으로 지운다

| 명령 | 범위 |
|---|---|
| `TLBI ALLE1` | EL1 전부 (비쌈 — cold miss 폭발) |
| `TLBI VAE1, Xt` | **특정 VA만** |
| `TLBI ASIDE1, Xt` | **특정 프로세스(ASID)만** |
| `TLBI VMALLE1` | 현재 VM 전부 |

**필수 3종 세트:**

```text
TLBI VAE1, Xt   ← 무효화 (방송만, 완료는 안 기다림)
DSB ISH         ← 모든 코어가 끝낼 때까지 대기  ★틈을 막는 자물쇠
ISB             ← 파이프라인 정리
```

!!! warning
    이 순서를 안 지키면 변경이 제대로 반영되지 않는다. **PWC(2단원)도 함께 무효화**돼야 한다.

---

## 7. 멀티코어 TLB Coherency (★핵심 그림)

코어마다 자기 TLB를 가지므로, 한 코어가 page table을 바꿔도 다른 코어엔 옛날 게 남는다.

### ❌ 순서 위반 — 깨지는 순간 (Race Window)

```text
시간 →

Core 0 ──[PTE 수정]──────────────[TLBI 방송]──────▶
            │                         │
            │   ← 이 틈(window)이 위험 →
            ▼                         ▼
Core 1 ─────────[VA 접근]─────────────────────────▶
                    │
                    └─ 아직 TLBI 안 받음
                       → 옛날 TLB entry 사용
                       → 옛날 PA 읽음 💥 데이터 오염
```

### ✅ 올바른 경우 — DSB ISH로 틈을 막음

```text
시간 →

Core 0 ──[PTE 수정]──[TLBI ...IS]──[DSB ISH]══대기══▶[재개]
                          │             ▲
                          │ 방송         │ 모든 코어 완료 확인
                          ▼             │
Core 1 ──────────────[TLBI 수신]──[무효화 완료]──┘
Core 2 ──────────────[TLBI 수신]──[무효화 완료]──┘

→ DSB ISH가 "모든 코어 무효화 완료"까지 Core 0을 멈춤
→ 그 후엔 어느 코어에도 옛날 entry 없음 → 안전 ✅
```

!!! tip "DSB ISH의 역할"
    - `TLBI ...IS` = "모든 코어야 지워" (**방송만**, 완료는 안 기다림)
    - `DSB ISH` = "**전부 지울 때까지 나 대기**" ← race window를 닫는 자물쇠
    - `ISB` = 그다음 내 파이프라인 정리

### ARM vs x86 코히런시 방식

```text
[ARM — HW 방송]
Core 0: TLBI VAE1IS ──┬──▶ Core 1 (HW 자동 무효화)
                      ├──▶ Core 2
                      └──▶ Core 3
        DSB ISH (완료 대기)
   → OS 개입 없음, 빠름

[x86 — SW Shootdown]
Core 0: PTE 수정
        IPI 발사 ──▶ Core 1 (핸들러 실행→무효화)
                 ──▶ Core 2 (핸들러 실행→무효화)
                 ──▶ Core 3 (핸들러 실행→무효화)
        모든 ACK 대기
   → 코어마다 인터럽트+핸들러, 코어 많을수록 느림 🐢
```

| | ARM | x86 |
|---|---|---|
| 방식 | HW 자동 방송 (`IS` 접미사) | SW IPI shootdown |
| 속도 | 빠름 | 코어 많을수록 느림 |
| OS 개입 | 불필요 | 필요 (핸들러) |

---

## 8. 교체 정책 (Replacement)

| 정책 | 메커니즘 | 트레이드오프 |
|---|---|---|
| **LRU** | 가장 오래 안 쓴 것 축출 | 정확하나 HW 복잡 |
| **Pseudo-LRU (PLRU)** | 트리 기반 근사 | 단순, near-LRU 성능 |
| **Random** | 무작위 | 가장 단순, worst-case 없음 |
| **FIFO** | 먼저 들어온 것부터 | 단순하나 hit rate 낮음 |

!!! note "PLRU와 DV"
    4-way는 트리 방향 비트 **3개**(N-way → N-1비트)로 근사. 진짜 LRU는 log₂(N!)≈5비트 필요.
    PLRU는 **정확한 LRU 순서가 아니므로**, 레퍼런스 모델도 **동일한 PLRU 알고리즘**을 써야 결과가 일치한다.

---

## 9. 흔한 오해

| ❌ Myth | ✅ Reality |
|---|---|
| "TLBI = 전부 삭제" | `VAE1`(VA별)·`ASIDE1`(ASID별)로 골라서 지움. 전체 flush는 비쌈 |
| "TLB 클수록 빠름" | 크면 검색 자체가 느려짐. 그래서 작은 L1 + 큰 L2 계층 |
| "TLBI는 즉시 전 코어 반영" | `IS` + `DSB ISH` 없으면 다른 코어는 stale |
| "ASID 다르면 절대 충돌 없음" | 논리적으론 그렇지만 물리적 칸이 한정돼 서로 축출. **ASID는 구분하지 격리 안 함** |

---

## 10. DV 검증 체크리스트

| 항목 | 시나리오 | 확인 |
|---|---|---|
| TLB Hit | 같은 VA 연속 접근 | 첫 번째 walk, 두 번째 1 cycle |
| TLB Miss | 새 VA | walk 실행 후 entry 캐시 |
| Replacement | TLB 꽉 참, 새 entry | 정책대로 축출 (PLRU 정확성) |
| Invalidation | TLBI 후 같은 VA | 다음 접근이 **반드시 miss + walk** |
| ASID 격리 | 같은 VA, 다른 ASID | 별도 entry, 다른 PPN |
| Multi-size | 4KB + 2MB 혼합 | size-aware VPN 마스킹 |
| **Stale Entry** | PTE 변경, TLBI 생략, 접근 | **BUG: 틀린 PA 사용** |
| Concurrent Walk | 동시 다발 miss | walk engine 병렬/직렬 정확성 |

### 디버그 체크리스트

| 증상 | 1순위 의심 | 확인 위치 |
|---|---|---|
| PTE 변경 후 옛날 PA | TLBI 또는 DSB/ISB 누락 | `TLBI...; DSB ISH; ISB` 시퀀스 |
| 한 코어만 stale | `IS` 접미사 빠짐 | TLBI 명령 broadcast 접미사 |
| 문맥전환 후 100% miss | ASID rollover로 전역 flush | ASID 할당 로그, generation counter |
| 같은 VA, 다른 ASID인데 같은 PA | lookup에 ASID 비교 누락 | TLB dump ASID 필드, PTE.nG |
| 랜덤 접근 throughput 붕괴 | capacity miss + PWC miss | working set vs TLB 크기 |
| `TLBI VA`가 인접 VA 안 지움 | size mask 오류(huge page) | TLB entry size 필드, TLBI mask |
| Stage2 켜니 hit rate 하락 | S1+S2 결합 TLB capacity | IOTLB vs 결합 TLB 정책 |

---

## 11. 핵심 정리

1. **Latency가 지배** — hit ~1cycle vs miss ~수백 cycle. 1% miss율 변동 = 4~9× 유효시간 변화
2. **계층이 비용 분산** — μTLB → L2 → PWC → walk
3. **ASID/VMID로 공유** — 문맥/VM 전환 시 full flush 회피 (단 rollover 시 강제 flush)
4. **Invalidation은 필수** — page table 변경마다 TLBI + `DSB ISH; ISB`, 누락 시 silent corruption
5. **Shootdown은 x86에서 비쌈** — SW IPI vs ARM HW 방송(`IS`)
6. **Coherency = race window** — PTE 수정과 TLBI 완료 사이의 틈을 `DSB ISH`가 닫는다

---

## 📖 용어 사전 (Glossary)

| 용어 | 풀이 |
|---|---|
| **TLB** | Translation Lookaside Buffer. VA→PA 변환 결과(권한·속성 포함)를 캐시하는 HW |
| **μTLB (L1 TLB)** | 32~64칸, fully-associative, 1 cycle. 가장 빠른 1차 캐시 |
| **L2 TLB** | 256~2048칸, set-associative, 2~4 cycle. L1 miss 흡수 |
| **IOTLB** | IOMMU/SMMU용 TLB. 키 = StreamID + SubstreamID(PASID) |
| **PWC (Page Walk Cache)** | 중간 레벨 PTE를 캐시하는 별도 구조 (TLB와 무효화 함께) |
| **Page Walk Engine** | TLB miss 시 메모리의 page table을 순회하는 HW |
| **Hit / Miss** | TLB에 매핑이 있음 / 없음 (있으면 ~1cycle, 없으면 walk) |
| **Hit Rate** | 전체 접근 중 TLB hit 비율. 성능을 좌우 |
| **VPN / PPN** | Virtual / Physical Page Number |
| **ASID** | Address Space ID. 프로세스 구분 태그 (flush 없이 문맥 전환) |
| **VMID** | Virtual Machine ID. VM 구분 태그 |
| **nG (not Global)** | 프로세스 전용(ASID 적용) 매핑 표시 비트 |
| **Global entry** | nG=0. ASID 무관하게 모든 문맥에서 유효 (커널 매핑 등) |
| **Fully-associative** | 어느 칸에든 들어갈 수 있어 전 칸 검색 (작을 때 적합) |
| **Set-associative** | set 단위로 묶어 일부만 검색 (클 때 적합, N-way) |
| **Split / Unified TLB** | 명령·데이터 분리 / 통합 TLB |
| **TLBI** | TLB Invalidate. 낡은 entry 무효화 명령 (ALLE1/VAE1/ASIDE1/VMALLE1) |
| **DSB ISH** | Data Synchronization Barrier (Inner Shareable). 모든 코어 완료 보장 |
| **ISB** | Instruction Synchronization Barrier. 파이프라인 flush·동기화 |
| **IS 접미사** | TLBI의 broadcast 버전 (Inner Shareable 도메인 전 코어) |
| **TLB Shootdown** | 멀티코어에서 다른 코어의 TLB를 무효화시키는 절차 |
| **IPI** | Inter-Processor Interrupt. x86 shootdown에서 다른 코어를 깨우는 인터럽트 |
| **Race Window** | PTE 수정과 TLBI 완료 사이의 틈. 이 동안 stale 변환 사용 위험 |
| **Stale Entry** | page table은 바뀌었는데 무효화 안 된 낡은 TLB entry |
| **Replacement Policy** | TLB가 꽉 찼을 때 어느 칸을 축출할지 결정 (LRU/PLRU/Random/FIFO) |
| **PLRU (Pseudo-LRU)** | 트리 비트로 LRU를 근사하는 저비용 교체 정책 |
| **EAT (T_eff)** | Effective Access Time. hit/miss 가중평균 유효 접근시간 |
| **HW/SW-managed TLB** | miss를 HW walk engine이 처리 / OS 핸들러가 처리 (MIPS 등 legacy) |
| **Prefetch / Speculative Walk** | miss 예방 위해 인접·예측 주소를 미리 walk |
