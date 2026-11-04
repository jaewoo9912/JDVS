# RTL lint — 시뮬레이션 전 정적 검사

> **lint**는 시뮬레이션 전에 툴로 RTL을 **실행하지 않고 정적으로 검사**해서 위험한 코딩을 찾는 작업이다. RTL용 **맞춤법 검사기**라고 보면 된다.

---

## 1. lint란?

- 대표 툴: **SpyGlass**, **Superlint**, **`verilator --lint-only`**
- 코드를 돌려보지 않고 **코드 자체만 보고** 위험한 패턴을 리포트한다.

```
RTL 작성 ──▶ lint (정적 검사) ──▶ 시뮬레이션 (동적 검증)
              └ 맞춤법 검사        └ 실제로 돌려보기
```

---

## 2. 주로 잡는 것

| 항목 | 예 |
| --- | --- |
| 의도치 않은 latch | `else` / `default` 누락 |
| multiple driver | 한 신호를 여러 곳에서 구동 |
| bit width 불일치 | 대입 시 상위 비트 잘림 |
| undriven / unused 신호 | 구동 안 되는 신호, 안 쓰는 신호 |
| `always_ff`에서 blocking 사용 | `always_ff` 안의 `=` |
| 불완전한 sensitivity list | `always @(a)`에서 `b` 누락 |
| combinational loop | 조합 논리가 자기 자신으로 되돌아옴 |

!!! tip "CDC는 별도"
    CDC(Clock Domain Crossing)는 보통 lint가 아닌 **별도 CDC 툴**로 본다.

---

## 3. "lint 작업했다"의 의미

1. lint **리포트**를 뽑는다.
2. 진짜 버그는 **RTL을 수정**한다.
3. 의도된 것은 **waiver**로 사유를 남긴다.
4. 결과적으로 **lint clean** 상태를 만든다.

---

## 4. 검증 입장에서 왜 중요한가?

- lint가 clean이어야 latch나 X 같은 **엉뚱한 원인으로 디버깅 시간을 낭비하는 일**이 줄어든다.
- 그래서 보통 **RTL 릴리즈 조건**으로 lint clean을 건다.
