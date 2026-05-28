# virtual interface + class

같은 `virtual` 키워드지만 `virtual function/task`의 동적 디스패치와는 **무관한 별개 메커니즘 두 가지**다.

---

## 1. virtual class (추상 클래스)

### 한 줄 정의

**인스턴스 생성 금지 + 상속 전용** 클래스. *"뼈대만 제공, 살은 자식이 채워라"* 패턴.

### 문법

```systemverilog
virtual class Shape;
  pure virtual function real area();    // 본문 없음. 자식이 반드시 구현
  virtual function void describe();     // 본문 있는 virtual 도 가능
    $display("area = %0.2f", area());
  endfunction
endclass

class Circle extends Shape;
  real r;
  function new(real r); this.r = r; endfunction
  virtual function real area();         // pure virtual 구현 필수
    return 3.14159 * r * r;
  endfunction
endclass

Shape  s = new();      // ❌ 컴파일 에러 (추상 클래스 인스턴스화 불가)
Circle c = new(2.0);   // ✅
Shape  s2 = c;         // ✅ 베이스 핸들에 자식 객체
s2.describe();         // ✅ "area = 12.57"  (virtual 디스패치)
```

### 규칙

- **V1**: `virtual class`는 `new()` 호출 불가
- **V2**: `pure virtual`은 **본문 없는 선언만**. 자식이 모두 구현해야 인스턴스화 가능
- **V3**: `pure virtual`은 `virtual class` 안에서만 선언 가능
- **V4**: `pure virtual` 중 **하나라도 미구현이면 자식도 자동 추상 클래스**

### 용도

- 공통 **인터페이스/계약**을 정의하고, **구현은 자식에 강제**
- UVM의 `uvm_object`, `uvm_component` 등이 사실상 이 역할

---

## 2. virtual interface (interface 핸들)

### 핵심 사실 — SystemVerilog의 두 세계

| 모듈 / 인터페이스 | 클래스 |
| --- | --- |
| 건물 (방, 벽) | 사람 (건물 안 돌아다님) |
| 시뮬 시작 **전** 도면 확정 | 시뮬 **도중** 동적 생성/소멸 |
| 컴파일 타임에 **위치(계층) 고정** | 메모리 어딘가에 **떠다님** (위치 없음) |

→ 클래스(동적 객체) 안에 interface(고정된 건물 일부) **인스턴스를 통째로 넣을 수 없다.**
*사람 만들 때마다 방을 같이 짓는 게 말이 안 되는 것과 같다.*

### 해법 — 핸들(주소)만 갖기

```systemverilog
class Driver;
  virtual my_if vif;     // ✅ interface 의 "주소"만 갖는다 (핸들)
endclass
```

- `virtual` 키워드 = **"이 변수는 interface 인스턴스가 아니라 그 핸들이다"** 라는 마킹
- 실제 interface 인스턴스는 **모듈에** 있음. 클래스는 **핸들로 거기 신호에 접근**

### 전형 패턴 — UVM 표준

```systemverilog
// 모듈 쪽
interface my_if(input bit clk);
  logic        valid;
  logic [31:0] data;
endinterface

module top;
  bit clk;
  my_if intf(clk);                                              // 실제 인스턴스
  dut u_dut (.clk(clk), .vif(intf));

  initial begin
    uvm_config_db #(virtual my_if)::set(null, "*", "vif", intf); // 핸들 등록
    run_test();
  end
endmodule
```

```systemverilog
// 클래스 쪽
class my_driver extends uvm_driver;
  virtual my_if vif;                                            // 핸들 멤버

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db #(virtual my_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "vif not set")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      vif.valid <= 1;
    end
  endtask
endclass
```

### 규칙

- **I1**: virtual interface는 **항상 핸들**. `new()` 불가. interface 자체와 다름
- **I2**: 누가 할당해주기 전엔 `null`. 사용 전 **반드시 등록/획득**
- **I3**: **`uvm_config_db`가 표준 전달 메커니즘** (모듈 set / 클래스 get)
- **I4**: **clocking block을 통한 접근 권장** (`vif.cb.signal`) — 일반 신호 접근은 race condition 위험

### 흔한 함정

- ❌ virtual interface가 `virtual function`의 `virtual`과 관련 있다고 오해 → **완전 별개**
- ❌ `vif` `null` 체크 없이 사용 → 런타임 크래시
- ❌ `vif.signal` 직접 driving → RTL과 race. **clocking block 필요**
- ❌ 여러 interface 인스턴스를 같은 path로 set → **마지막 것만 살아남음**

---

## `virtual` 키워드 세 가지 의미 — 최종

| 형태 | 의미 | 관련 |
| --- | --- | --- |
| `virtual function` / `task` | 동적 디스패치 (객체 실제 타입 호출) | OOP 다형성 |
| `virtual class`             | 추상 클래스 (인스턴스화 불가) | OOP 상속 |
| `virtual <interface>`       | interface 핸들 | 모듈-클래스 다리 |
