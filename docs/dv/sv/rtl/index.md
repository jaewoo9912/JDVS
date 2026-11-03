# RTL 기초

> 검증 코드를 읽고 쓰기 전에 알아야 할 **하드웨어 쪽 기본기** — 조합/순차 논리와 `=` vs `<=`, `initial` / `always` 같은 절차 블록, 컨트롤러의 두뇌인 FSM, 그리고 리셋 누락 등에서 번지는 `X` 전파.

---

## 1. 페이지

| 페이지 | 한 줄 요약 |
| --- | --- |
| [조합 / 순차 논리 (`=` vs `<=`)](comb-seq-logic.md) | `assign` / `always_comb` / `always_ff`와 blocking vs non-blocking 대입 |
| [절차 블록 (`initial` / `always` / `always_comb`)](procedural-blocks.md) | `initial` vs `always`, TB 클럭 생성, `assign` vs `always_comb` 규칙 |
| [FSM (유한 상태 머신)](fsm.md) | `state` / `next_state`를 순차·조합 블록으로 나눠 만드는 컨트롤러 |
| [X propagation (`xprop`)](x-propagation.md) | `X`가 번지는 현상, X-optimism, `xprop` 옵션 |
| [X vs Z](x-vs-z.md) | `X` vs `Z`, `==` vs `===`, TB 체크에서 `X` 놓치지 않기 (`!==` / `$isunknown`) |

!!! tip "읽는 순서"
    조합/순차 논리 → 절차 블록 → FSM → X propagation → X vs Z 순서로 읽으면 앞 페이지 개념이 다음 페이지에서 그대로 쓰인다.
