# Common Task & CCTV

> **한 줄 요약**: IP 50~200개 × 공통 검사 7개 = 수천 칸의 표. 사람이 손으로 채우면 **3~5% 빼먹는다.**
> CCTV는 이 **출석부를 자동화**해 "혹시 빠뜨린 거 없나?"를 "왜 이게 자동 실행 안 됐지?"로 바꾼다.

---

## 1. 비유로 시작 — 직원 건강검진

회사에 직원 **200명**, 모두가 받아야 할 검진 항목이 **7개**.
보건 담당자 한 명이 엑셀로 관리한다 → 200 × 7 = **1,400칸**.

```text
        시력  청력  혈압  혈액  흉부  치아  소변
김철수   ✅    ✅    ✅    ✅    ✅    ✅    ✅
이영희   ✅    ⬜    ✅    ✅    ✅    ✅    ✅   ← 청력 빈칸!
박민수   ✅    ✅    ✅    ⬜    ✅    ✅    ✅   ← 혈액 빈칸!
```

!!! danger "수동 추적의 한계 (DVCon 2025)"
    - 셀의 **3~5%가 누락**된다.
    - 누락의 **96.30%가 사람 실수(human oversight)** — 어려워서가 아니라 그냥 깜빡해서.

> **직원 = IP, 검진 항목 = 검증 항목, 엑셀 = 검증 추적표.**
> 해결책: *"엑셀을 사람이 채우지 말고, 컴퓨터가 자동으로 채우고 빈칸을 빨갛게 알리게 하자."* → 이게 **CCTV**.

---

## 2. 용어 정리

| 용어 | 풀이 |
|---|---|
| **Common Task** | 모든 해당 IP가 공통으로 받아야 하는 검증 항목 (7개) |
| **CCTV** | **C**ommon Task **C**overage **V**erification — 공통 검사 완료 여부를 자동 추적 |

---

## 3. Common Task — 7가지 공통 검사

| # | 항목 | 한 마디로 | 핵심 시나리오 |
|---|---|---|---|
| 1 | **sysMMU** | 주소 변환 잘 되나 | VA→PA 변환, page fault, **bypass↔enable 전환**, TLB invalidation |
| 2 | **Security** | 아무나 못 들어가게 막나 | Secure/Non-Secure 경계, 레지스터 권한, firewall |
| 3 | **DVFS** | 속도 바꿔도 안 깨지나 | 전압/주파수 변경 중 in-flight 트랜잭션 보호 |
| 4 | **Clock Gating** | 껐다 켜도 잘 깨나 | idle 감지 → 클럭 차단 → wake-up 복구 |
| 5 | **Power Domain** | 전원 껐다 켜도 기억하나 | power on/off, 상태 retention |
| 6 | **Reset** | 리셋하면 처음으로 돌아오나 | warm reset, 레지스터 기본값, 초기화 순서 |
| 7 | **IRQ** | 급한 일 생기면 알리나 | 인터럽트 생성 → 라우팅 → 핸들러 실행 |

---

## 4. CCTV 매트릭스 — IP × Task × Result

```text
            sysMMU  보안   DVFS  클럭  전원  리셋  IRQ
IP_UFS        ✅     ✅    ✅   ✅   ✅   ✅   ✅
IP_GPU        ✅     ❓    ✅   ✅   ✅   ✅   ✅   ← ❓ 빈칸 → 자동 경보
IP_CRYPTO    N/A     ✅    ✅   ✅   ✅   ✅   ✅   ← 암호화는 sysMMU 불필요
IP_UART      N/A     ✅   N/A   ✅   ✅   ✅   ✅
```

각 칸의 4가지 상태:

| 상태 | 의미 |
|---|---|
| ✅ **PASS** | 검사 완료, 통과 |
| ❌ **FAIL** | 검사 완료, 실패 → **진짜 버그** |
| **N/A** | 검사 불필요 (스펙 근거 필요) |
| ❓ **NOT_TESTED** | **아직 안 함 → 자동 경보 (가장 위험)** |

!!! success "완료(Closure) 정의"
    모든 칸이 **PASS 또는 N/A**여야 sign-off.
    `NOT_TESTED`가 하나라도 있으면 끝난 게 아니다.

!!! note "합리적인 N/A 예시"
    - **Crypto** — 내부 메모리만 사용 → sysMMU N/A
    - **UART** — 고정 클럭 → DVFS N/A

---

## 5. SystemVerilog 구현 (covergroup)

```systemverilog
covergroup cg_cctv;
  cp_ip:     coverpoint ip;      // {UFS, DMA, GPU, CRYPTO, ...}
  cp_task:   coverpoint task_id; // {SYSMMU, SECURITY, DVFS, CLK_GATE, POWER, RESET, IRQ}
  cp_result: coverpoint result;  // {PASS, FAIL, N_A, NOT_TESTED}

  cx_ip_task_result: cross cp_ip, cp_task, cp_result {
    // ① 스펙상 N/A인 칸을 제외 (반드시 근거 명시)
    ignore_bins crypto_no_mmu =
        binsof(cp_ip)   intersect {IP_CRYPTO} &&
        binsof(cp_task) intersect {TASK_SYSMMU};

    // ② 안 한 칸(NOT_TESTED)은 자동으로 illegal → 즉시 경보
    illegal_bins gap =
        binsof(cp_result) intersect {RESULT_NOT_TESTED};
  }
endgroup
```

!!! tip "핵심 두 줄"
    - **`ignore_bins`** = "이 칸은 N/A니까 빼줘" (단, **반드시 스펙 근거**)
    - **`illegal_bins`** = "안 한 칸이 있으면 자동으로 에러" ← **CCTV의 심장**

!!! warning "ignore_bins의 함정"
    근거 없이 `ignore_bins`를 남발하면 → "할 필요 없다"고 잘못 빼버려 **조용히 누락**.
    이것이 바로 누락의 96% 메커니즘. → **N/A는 항상 스펙으로 정당화**.

---

## 6. 테스트 시나리오 예시

=== "sysMMU (4 시나리오)"
    1. Normal translation — VA→PA 매핑 정확성
    3. **Bypass↔Enable 전환** — in-flight 트랜잭션 안전성
    4. TLB invalidation — 페이지 테이블 변경 후 갱신

=== "Security (4 테스트)"
    1. Non-Secure → Secure 레지스터 read → **SLVERR**
    2. Secure → Secure 레지스터 read → **OKAY**
    3. Non-Secure → Non-Secure 레지스터 read → **OKAY**
    4. Security lock 지속성 — 한 번 설정되면 해제 불가

---

## 7. 실제 실리콘 버그 사례

!!! example "DMA × sysMMU 전환 누락"
    ```text
    1. DMA IP 단독 검증은 전부 통과 ✅
    2. 그러나 "sysMMU bypass→enable 전환" 검증 누락 ⬜
    3. Linux 부팅 중 DMA 트랜잭션 진행 중 sysMMU enable
    4. 트랜잭션은 VA로 발행됐는데 페이지 테이블 미완성 → Translation Fault
    5. 산발적 kernel panic, 디버깅에 수 주 소요 💥
    ```

    **CCTV 예방:**
    ```text
    record_result(IP_DMA, TASK_SYSMMU_TRANSITION, NOT_TESTED)
    → ❓ 칸 자동 감지 → 경보 → 시나리오 생성 → pre-silicon 발견 ✅
    ```

---

## 8. Gap 원인 분류 (DVCon 2025)

| 원인 | 비율 | 해결책 |
|---|---|---|
| **사람 실수 (Human Oversight)** | **96.30%** | 자동화 (CCTV 매트릭스 + AI) |
| 새 IP/기능 추가 시 누락 | ~40% 예방 가능 | 스펙 기반 자동 업데이트 |
| Legacy 가정 | 높음 | 매트릭스 버전 관리 |

!!! quote "왜 이게 희소식인가"
    누락의 96%는 **기술적 난이도가 아니라 체크리스트 관리 실패**.
    어려운 문제면 천재가 필요하지만, 깜빡한 거면 **자동 알림만으로 거의 다 막힌다.**

---

## 9. Closure 조건 & 회귀 정책

| 조건 | 조치 |
|---|---|
| 모든 칸 ∈ {PASS, N/A} | **Sign-off 승인** |
| 칸 = NOT_TESTED | gap 리포트 → 시퀀스 생성 → rerun |
| 칸 = FAIL | 실제 버그로 escalate, 매트릭스 업데이트 보류 |
| ignore_bins > 30% | N/A 정당성을 스펙과 대조 감사(audit) |

---

## 10. 자주 하는 오해

| 오해 | 진실 |
|---|---|
| "IP-XACT만 있으면 CCTV 자동화 끝" | IP-XACT는 **구조만**. "sysMMU 필요?" 같은 의미 판단은 **스펙 파싱** 필요 |
| "CCTV 100% = 칩 출시 OK" | 매트릭스는 칸만 채움. **칸 사이 순서 의존성**(sysMMU-enable→DVFS)은 못 잡음 |
| "ignore_bins 많이 쓰면 빨라짐" | 근거 없는 ignore_bins = **조용한 누락** (96% 메커니즘) |
| "작은 SoC는 자동화 불필요" | DVCon: Project B(소형) 4.99% vs Project A 2.75% — **작을수록 누락률 높음** |

---

## 11. 핵심 정리

- 문제: IP × Common Task 매트릭스를 **수동 추적하면 3~5% 누락**, 그중 **96%가 사람 실수**
- 해법: **IP × Task × Result** cross-coverage로 자동 추적
- **`illegal_bins`** = NOT_TESTED 자동 경보 / **`ignore_bins`** = N/A 제외(스펙 근거 필수)
- Closure = 모든 칸 **PASS 또는 N/A**
- 작은 팀일수록 누락률이 높다 → **자동화가 더 필요**
