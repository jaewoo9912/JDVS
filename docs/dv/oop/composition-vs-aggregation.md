# composition vs aggregation

> 둘 다 **has-a** 관계(클래스가 다른 객체를 멤버로 가짐)이고, 차이는 **멤버 객체의 생명주기(lifecycle)와 소유권(ownership)을 누가 갖느냐**다.

---

## 1. 개념

| | 정의 | 비유 |
|---|---|---|
| **composition** | 소유 클래스가 멤버 객체를 직접 생성하고 소유한다. 생명주기가 소유 클래스와 같다. | 사람과 심장 |
| **aggregation** | 외부에서 생성된 객체를 handle로 참조한다. 생명주기가 소유 클래스와 독립적이다. | 회사와 직원 (회사가 없어져도 직원은 남는다) |

### composition (강한 has-a)

- **생성 책임:** 소유 클래스가 멤버 객체를 내부에서 직접 생성(`new` / `create`)한다.
- **소유권:** 멤버 객체는 소유 클래스에 독점적으로 속하며, 외부와 공유하지 않는다.
- **생명주기:** 소유 클래스와 함께 생성되고 함께 소멸한다. 소유 클래스 밖에서 단독으로 존재할 이유가 없다.
- **변경 영향 범위:** 멤버 객체를 수정해도 영향이 소유 클래스 내부로 한정된다.
- **UVM 예:** agent가 `build_phase`에서 driver, monitor, sequencer를 직접 `create`한다. 해당 driver는 그 agent 전용이며, agent 없이 단독으로 쓰이지 않는다.

### aggregation (약한 has-a)

- **생성 책임:** 소유 클래스는 객체를 생성하지 않는다. 외부(test, env 등)에서 생성한 객체를 handle로 전달받아 참조만 한다.
- **소유권:** 객체의 생성·관리 주체가 따로 있고, 소유 클래스는 사용자일 뿐이다.
- **생명주기:** 소유 클래스보다 먼저 생성될 수 있고, 소유 클래스가 소멸해도 계속 유지된다.
- **공유:** 같은 객체 하나를 여러 클래스가 동시에 참조할 수 있다.
- **변경 영향 범위:** 한 곳에서 객체 값을 바꾸면 그 객체를 참조하는 모든 곳에 즉시 반영된다.
- **UVM 예:** test가 생성한 cfg 객체를 여러 seq와 component가 handle로 받아 쓴다. vif도 top에서 한 번 생성해 `uvm_config_db`로 배포한다.

```
composition                      aggregation

 axi_agent                        test ── create ──▶ cfg
 ┌───────────────┐                                    ▲  ▲
 │ drv (create)  │                         seq1 ──────┘  │
 │ mon (create)  │                         seq2 ─────────┘
 └───────────────┘                        (handle 참조만)
 agent 소멸 시 drv도 소멸                  seq 소멸 후에도 cfg 유지
```

!!! tip "구분 기준 두 가지"
    1. **생성 책임:** 클래스 내부에서 생성하면 composition, 외부에서 전달받으면 aggregation.
    2. **생명주기:** 소유 클래스와 함께 소멸하면 composition, 독립적으로 유지되면 aggregation.

---

## 2. composition 예

```systemverilog
class axi_agent extends uvm_agent;
  axi_driver drv;
  function void build_phase(uvm_phase phase);
    drv = axi_driver::type_id::create("drv", this);  // 내부에서 생성
  endfunction
endclass
```

---

## 3. aggregation 예

```systemverilog
class axi_wr_seq extends axi_base_seq;
  axi_cfg cfg;   // 외부에서 전달받음
endclass

// test에서
cfg = axi_cfg::type_id::create("cfg");
seq1.cfg = cfg;
seq2.cfg = cfg;   // 같은 cfg를 여러 seq가 공유
```

---

## 4. 비교

| | composition | aggregation |
|---|---|---|
| 생성 책임 | 소유 클래스 (내부에서 create) | 외부에서 생성 후 전달 |
| 생명주기 | 소유 클래스와 동일 | 독립적 |
| 공유 | 안 함 | 여러 클래스가 공유 |
| UVM 예 | env→agent, agent→driver | seq→cfg, 여러 component가 같은 vif나 config 객체 공유 |

---

## 5. SV에서는 사실상 handle 넘김

- SV에는 둘을 구분하는 문법이 없고, 클래스 타입 멤버 변수는 모두 handle이다.
- 차이는 문법이 아니라 **설계 의도**다. 내부에서 `new`나 `create`로 생성해 단독으로 쓰면 composition, 외부에서 생성된 객체를 handle로 받아 쓰면 aggregation이다.

```systemverilog
drv = axi_driver::type_id::create("drv", this);  // composition
seq.cfg = cfg;                                   // aggregation: handle만 전달
```

!!! warning "handle을 넘기면 원본을 같이 참조한다"
    test가 `cfg.narrow`를 바꾸면 그 cfg를 참조하는 seq 모두에 즉시 반영된다. 장점이자 주의할 점이다.

!!! tip "참고"
    [깊은 상속 문제](deep-inheritance.md)의 composition 예제에서 `cfg`와 `inj`는 test가 생성해 전달하므로 엄밀히는 aggregation이다. 보통은 둘을 묶어 'composition(상속 대신 객체를 조합해 쓰기)'이라고 부른다.
