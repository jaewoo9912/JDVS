# Flash 보조 기능과 칩의 일생

> 요약: flash 칩의 핵심 동작([아날로그 in-memory 연산(CIM) 읽기](flash-cell.md#12-flash-in-memory-cim))이 **제대로, 오래, 아껴 가며** 동작하도록 돕는 보조 기능(Redundancy, NVR, Recall/Config Register, 디지털 읽기, Standby/DPD)을 정리한다. 핵심은 **trim 값은 공장에서 칩마다 한 번 찾아 NVR(플래시)에 저장하고, 전원을 켤 때마다 Recall → Set Config로 레지스터에 적용**한다는 것이다.
>
> ※ 출처: 2026-11-24 "Flash 보조 기능과 칩의 일생" 학습 노트.

---

## 1. 보조 기능 한눈에 보기

| 기능 | 한 줄 설명 |
|---|---|
| Redundancy | 불량 row/column을 예비 row/column으로 대체 |
| NVR | 칩별 보정값(trim)을 저장하는 별도 플래시 영역 |
| Recall / Config Register | 전원을 켜면 보정값을 읽어 회로에 적용 |
| 디지털(0/1) 읽기 모드 | 일반 플래시처럼 0/1로 읽기 |
| Standby / DPD | 사용하지 않을 때 전력 절약 |

---

## 2. Redundancy

- 셀이 수백만 개라 제조하면 몇 개는 반드시 불량이 남는다. 그 때문에 칩 전체를 버리면 수율 손실이 크다.
- 처음부터 **예비 row/column**을 더 만들어 두고, 테스트에서 불량을 찾으면 예비 줄로 대체한다.

| 종류 | 선택 | 대체 대상 |
|---|---|---|
| Row Redundancy | 예비 row 선택 신호 | 불량 가로줄 (row) |
| Column Redundancy | 예비 column 선택 신호 | 불량 세로줄 (column) |

- 예비 column의 읽기 결과는 **예비 column 전용 출력**으로 따로 나온다.

---

## 3. NVR과 trim

### 3.1 NVR (Non-Volatile Register 영역)

- 메인 어레이와 **별도의 플래시 영역**이다.
- 칩마다 다른 **보정값(trim)**을 저장한다.
- 플래시라서 전원을 꺼도 남아 있다.
- 전용 선택 신호로 NVR 영역을 골라 Program / Erase / Read 한다.

### 3.2 보정값(trim)이란

- 같은 설계로 만들어도 **공정 편차** 때문에 칩마다 특성이 조금씩 다르다 (같은 전압을 줘도 전류가 조금 더/덜 흐름, 기준 전압이 조금 어긋남 등).
- 그 차이를 칩마다 맞춰 주는 설정값이 **trim**이다.

| trim 대상 예 | 내용 |
|---|---|
| 셀 단자 전압 | Program/Erase 때 CG, EG, SL에 거는 전압 조정 ([Flash 셀 동작 원리 — 단자 약자](flash-cell.md#8) 참고) |
| 읽기 회로 | 읽기 기준·바이어스 조정 |

- trim은 칩마다 **공장에서 한 번** 찾아서 NVR에 저장한다. 사용 중에 다시 찾지 않는다.

!!! warning "NVR trim ≠ ADC calibration"
    사용 중에 수행하는 ADC calibration(offset 보정 등)은 NVR trim과 별개다.

---

## 4. Recall / Config Register

- 회로가 실제로 쓰는 설정값은 **Config Register(레지스터)**에 있다.
- 레지스터는 전원이 꺼지면 사라진다 → 켤 때마다 다시 채워야 한다.

| 동작 | 내용 |
|---|---|
| Recall | NVR(플래시)의 보정값을 읽어 오는 동작 |
| Set Config | 읽은 값을 Config Register에 써 넣는 동작 |
| 초기화 | 필요 없으면 0으로 덮어쓰거나 power-on reset으로 리셋 |

---

## 5. 디지털(0/1) 읽기 모드

- CIM 연산 읽기(아날로그 연산)와 달리, **일반 플래시처럼 셀을 0/1로 읽는 모드**다.
- 셀 전류를 기준과 비교해 많으면 1, 적으면 0 같은 식으로 판정한다.

| | CIM 연산 읽기 | 디지털(0/1) 읽기 |
|---|---|---|
| 출력 | 아날로그 전류 (입력 × 가중치) | 0 / 1 |
| 판정 | ADC로 디지털 변환 | 기준 전류와 비교 |

---

## 6. Standby / DPD

| 모드 | 진입 | 의미 |
|---|---|---|
| Standby | chip enable 비활성 | 동작만 멈추고 대기. 바로 다시 쓸 수 있음 |
| DPD (Deep Power Down) | DPD 진입 신호 활성 | 대부분의 회로 전원을 끊어 전력을 더 아낌. 깨어나는 데 시간이 더 걸림 |

---

## 7. 칩의 일생 — trim은 언제 정해지고 언제 쓰이나

```text
[1] 설계 / 제조
      │
[2] 웨이퍼 테스트 (공장, 칩마다 한 번)
      │  - 테스트 장비가 칩 특성을 측정 → 이 칩에 맞는 trim 값을 찾음
      │  - 불량 줄을 찾아 Redundancy로 대체할 정보 기록
      │  - 결과를 NVR에 Program (플래시라 영구 저장)
      │
[3] 전원 켤 때마다
      │  power-on reset 해제 → Recall (NVR 읽기) → Set Config (레지스터에 쓰기)
      │  → 회로가 이 칩에 맞게 보정된 상태가 됨
      │
[4] 사용
      │  Program / Erase / CIM 연산 읽기 ...
      │  쉴 때는 Standby 또는 DPD
      │
[5] 전원 끔
         - 레지스터 (trim 적용값 포함): 사라짐 → 다음에 켜면 [3] 다시
         - 플래시 (메인 어레이 weight, NVR trim): 남아 있음
```

### 7.1 무엇이 남고 무엇이 사라지나

| 상황 | 플래시 셀 (weight, NVR) | 레지스터 (Config 등) |
|---|---|---|
| Standby | 남음 | 남음 |
| DPD | 남음 | 구현에 따라 다름 |
| power-on reset | 남음 | 사라짐 |
| 전원 끔 | 남음 | 사라짐 |

---

## 8. 핵심 정리

| 항목 | 시점 |
|---|---|
| trim **값을 찾는 것** | 공장에서 칩마다 한 번 (웨이퍼 테스트) |
| trim **값을 적용하는 것** | 전원을 켤 때마다 (Recall → Set Config) |

!!! tip "왜 둘로 나누나"
    플래시(NVR)는 지워지지 않지만 회로가 바로 쓸 수 없고, 레지스터는 회로가 바로 쓰지만 전원이 꺼지면 사라지기 때문이다.
