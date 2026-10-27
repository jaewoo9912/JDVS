# UVM

UVM(Universal Verification Methodology)은 SystemVerilog 기반의 표준 검증 방법론이다.

- **[UVM을 왜 써야 하는가](intro-why-uvm.md)** — CRV/CDV(SystemVerilog)와 구분되는 오직 UVM만의 재사용·자동화 인프라

---

## 카테고리

- **[Study](study/index.md)** — UVM 개념 및 구조 학습 정리
- **[코드 분석](code-analysis/index.md)** — 실제 UVM 코드 분석 정리
- **[실무 Tips](tips/index.md)** — 실무 문법·동작·디버깅 노하우
    - [Driver / Monitor에서의 Blocking(`=`) vs Non-blocking(`<=`)](driver-monitor-blocking-nonblocking.md)
    - [uvm_object](object.md)
    - [uvm_queue](queue.md)
    - [uvm_callback](callback.md)
    - [uvm_RAL](ral.md)
    - [uvm_pool](pool.md)
    - [default_sequence](default-sequence.md)
    - [lock + grab](lock-grab.md)
    - [begin_tr / end_tr (Transaction Recording)](begin-end-tr/index.md)
