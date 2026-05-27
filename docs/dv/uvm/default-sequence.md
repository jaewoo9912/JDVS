# default_sequence

## 핵심

특정 sequencer에 대해 **지정한 phase가 시작될 때 자동으로 실행되는 sequence**다.
config_db로 등록해두면 sequencer가 해당 phase에서 알아서 `start` 해준다 → 별도로 `seq.start()`를 호출할 필요가 없다.

## 설정 방법

config_db로 **sequencer의 특정 phase**에 등록한다. 보통 test의 `build_phase`에서 설정한다.

```systemverilog
// 1) 타입으로 등록 — sequencer가 내부에서 직접 create
uvm_config_db #(uvm_object_wrapper)::set(
    this, "env.agt.sqr.main_phase", "default_sequence",
    my_seq::type_id::get());

// 2) 인스턴스로 등록
uvm_config_db #(uvm_sequence_base)::set(
    this, "env.agt.sqr.main_phase", "default_sequence", seq);
```

!!! note "설정 타이밍"
    config_db는 **경로 문자열**로 동작해 lookup 시점에 해석되므로, sequencer 인스턴스가 만들어지기 전(`build_phase`)에 set해도 된다.
    핵심은 **대상 phase(`main_phase` 등)가 시작되기 전**에만 등록돼 있으면 된다는 것.

## 중지 방법

"아직 시작 안 한 걸 막기"와 "이미 돌고 있는 걸 멈추기"는 메커니즘이 다르다.

### 1. 시작 전 막기 — config_db `null`

phase **시작 전**(`build_phase`)에 같은 자리에 `null`을 set하면 sequencer가 아예 시작하지 않는다.
실무에선 주로 **base test가 깔아둔 default_sequence를 확장 test에서 끌 때** 쓴다.

```systemverilog
class my_test extends base_test;   // base_test 가 default_sequence 설정해둠
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);      // base 설정 적용
    // 같은 경로/필드, 값만 null → base 시퀀스 비활성화
    uvm_config_db #(uvm_object_wrapper)::set(
        this, "env.agt.sqr.main_phase", "default_sequence", null);
  endfunction
endclass
```

!!! warning "타이밍"
    sequencer는 phase가 **시작되는 순간** default_sequence를 읽고 바로 `start`한다.
    그래서 `set(null)`은 **phase 진입 전**에만 효과가 있다 — 이미 돌고 있으면 소용없다.

### 2. 이미 돌고 있는 걸 멈추기 — `stop_sequences()`

phase에 진입해 시퀀스가 **실행 중**이면 config_db로는 못 멈춘다. sequencer의 `stop_sequences()`로 돌던 시퀀스를 전부 중지한다.

가장 흔한 경우는 **reset 처리** — DUT reset 시 돌던 자극을 죽이고 reset 후 다시 시작.

```systemverilog
uvm_sequencer_base _sqr;
_sqr = sqr;                  // 대상 sequencer (파생→base 대입은 upcast라 cast 불필요)

forever begin
  @(negedge vif.rst_n);      // reset 감지
  _sqr.stop_sequences();     // 돌던 시퀀스 전부 중지 → reset 후 재시작
end
```

!!! note
    특정 시퀀스 핸들을 들고 있다면 `seq.kill()`로 그 하나만 죽일 수도 있다 (default_sequence는 보통 핸들을 안 들고 있어 잘 안 씀).

| 상황 | 방법 |
| --- | --- |
| 아직 시작 안 함 (phase 전) | config_db `set(..., null)` |
| 이미 실행 중 (phase 중) | `sqr.stop_sequences()` |
